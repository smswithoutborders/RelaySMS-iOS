//
//  MessageComposer.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 01/08/2024.
//

import Foundation
import SwobDoubleRatchet
import CryptoKit
import CoreData

class MessageComposer {
    
    var SK: [UInt8]
    var keystoreAlias: String
    var AD: [UInt8]
    var state = States()
    var deviceID: [UInt8]?
    var context: NSManagedObjectContext
    var useDeviceID: Bool

    init(SK: [UInt8], 
         AD: [UInt8],
         peerDhPubKey: Curve25519.KeyAgreement.PublicKey,
         keystoreAlias: String,
         deviceID: [UInt8]? = nil,
         context: NSManagedObjectContext,
         useDeviceID: Bool = true) throws {
        self.SK = SK
        self.keystoreAlias = keystoreAlias
        self.AD = AD
        self.deviceID = deviceID
        self.context = context
        self.useDeviceID = useDeviceID

        let fetchStates = try fetchStates()
        if fetchStates == nil {
            self.state = States()
            try Ratchet.aliceInit(
                state: self.state,
                SK: self.SK,
                bobDhPubKey: peerDhPubKey,
                keystoreAlias: self.keystoreAlias)
        } else {
//            print("Fetched state: \(fetchStates!.data?.base64EncodedString())")
//            print(try deserialize(data: fetchStates!.data!))
            self.state = try States.deserialize(data: fetchStates!.data!)!
        }
    }
    
    private func fetchStates() throws -> StatesEntity? {
        let fetchRequest: NSFetchRequest<StatesEntity> = StatesEntity.fetchRequest()
        do {
            let result = try self.context.fetch(fetchRequest)
            if result.count > 0 {
                let stateEntity = result[0] as NSManagedObject as? StatesEntity
                return stateEntity
            }
        } catch {
            print("Error fetching StatesEntity: \(error)")
        }
        return nil
    }
    
    private func saveState() throws {
        do {
            try Vault.resetStates(context: self.context)
            
            let statesEntity = StatesEntity(context: context)
            statesEntity.data = self.state.serialized()
            try context.save()
            
            print("Stored state: \(statesEntity.data?.base64EncodedString())")
            
        } catch {
            throw error
        }
    }
    
    public func emailComposer(platform_letter: UInt8, from: String, to: String, cc: String, bcc: String,
                              subject: String,
                              body: String) throws -> String {
        let content = "\(from):\(to):\(cc):\(bcc):\(subject):\(body)".data(using: .utf8)!.withUnsafeBytes { data in
            return Array(data)
        }
        do {
            let (header, cipherText) = try Ratchet.encrypt(state: self.state, data: content, AD: self.AD)
            try saveState()
            return formatTransmission(header: header, cipherText: cipherText, platform_letter: platform_letter)
        } catch {
            print("Error saving state message cannot be sent: \(error)")
            throw error
        }
    }
    
    public func textComposer(platform_letter: UInt8,
                             sender: String, text: String) throws -> String {
        let content = "\(sender):\(text)".data(using: .utf8)!.withUnsafeBytes { data in
            return Array(data)
        }
        do {
            let (header, cipherText) = try Ratchet.encrypt(state: self.state, data: content, AD: self.AD)
            try saveState()
            return formatTransmission(header: header, cipherText: cipherText, platform_letter: platform_letter)
        } catch {
            print("Error saving state message cannot be sent: \(error)")
            throw error
        }
    }
    
    public func messageComposer(platform_letter: UInt8,
                                sender: String, receiver: String, message: String) throws -> String {
        let content = "\(sender):\(receiver):\(message)".data(using: .utf8)!.withUnsafeBytes { data in
            return Array(data)
        }
        do {
            let (header, cipherText) = try Ratchet.encrypt(state: self.state, data: content, AD: self.AD)
            try saveState()
            return formatTransmission(header: header, cipherText: cipherText, platform_letter: platform_letter)
        } catch {
            print("Error saving state message cannot be sent: \(error)")
            throw error
        }
    }
    
    private func formatTransmission(header: HEADERS,
                                    cipherText: [UInt8],
                                    platform_letter: UInt8) -> String {
        
        let sHeader = header.serialize()
        
        // Convert PN to Data
        var bytesHeaderLen = Data(count: 4)
        bytesHeaderLen.withUnsafeMutableBytes {
            $0.storeBytes(of: UInt32(sHeader.count).littleEndian, as: UInt32.self)
        }
        
        var encryptedContentPayload = Data()
        encryptedContentPayload.append(bytesHeaderLen)
        encryptedContentPayload.append(sHeader)
        encryptedContentPayload.append(Data(cipherText))
        
        var payloadLen = Data(count: 4)
        payloadLen.withUnsafeMutableBytes {
            $0.storeBytes(of: UInt32(encryptedContentPayload.count).littleEndian, as: UInt32.self)
        }
        
        var data = Data()
        data.append(payloadLen)
        data.append(platform_letter)
        data.append(encryptedContentPayload)
        if useDeviceID && deviceID != nil {
            print("Appending deviceID")
            data.append(Data(deviceID!))
        }

        return data.base64EncodedString()
    }
}
