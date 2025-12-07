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

struct MessageComposer {
    
    var SK: [UInt8]?
    var keystoreAlias: String
    var AD: [UInt8]
    var state = States()
    var deviceID: [UInt8]?
    var context: NSManagedObjectContext
    var useDeviceID: Bool
    var languageCode: [UInt8]

    init(SK: [UInt8]?, 
         AD: [UInt8],
         peerDhPubKey: Curve25519.KeyAgreement.PublicKey?,
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
        self.languageCode = Array(LanguagePreferencesManager.getStoredLanguageCode().utf8)

        
        let regionalLanguageCode = LanguagePreferencesManager.getStoredLanguageCode()
        if let isoLanguageCode =  regionalLanguageCode.split(separator: "-").first , isoLanguageCode.count == 2 {
            
            print("isoLanguageCode: \(isoLanguageCode)")
            self.languageCode = Array(String(isoLanguageCode).utf8)
    
        } else {
            print("Error: Cannot extract valid 2-letter language code from \(regionalLanguageCode). Using 'en' as default.")
            self.languageCode = Array("en".utf8)
        
        }
        

        let fetchStates = try fetchStates()
//        print("AD in message composer: \(AD.toBase64())")
        if fetchStates == nil {
            print("[+] Initializing states...")
            self.state = States()
            try Ratchet.aliceInit(
                state: self.state,
                SK: self.SK!,
                bobDhPubKey: peerDhPubKey!,
                keystoreAlias: self.keystoreAlias)
        } else {
            print("Fetched state: \(fetchStates!.data?.base64EncodedString())")
//            print(try deserialize(data: fetchStates!.data!))
            self.state = try States.deserialize(data: fetchStates!.data!)!
        }
    }
    
    public static func hasStates(context: NSManagedObjectContext) -> Bool {
        let fetchRequest: NSFetchRequest<StatesEntity> = StatesEntity.fetchRequest()
        do {
            let result = try context.fetch(fetchRequest)
            return result.count > 0
        } catch {
            return false
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
            throw error
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
            print("Error in saving states....")
            throw error
        }
    }
    
    public func emailComposer(platform_letter: UInt8, from: String, to: String, cc: String, bcc: String,
                              subject: String,
                              body: String, accessToken: String? = nil, refreshToken: String? = nil) throws -> String {
        
        var content: [UInt8]
        var contentString = "\(from):\(to):\(cc):\(bcc):\(subject):\(body)"
    
        // Append the access token and refresh token if they not nil or empty
        if let accToken = accessToken, !accToken.isEmpty,
           let refToken = refreshToken, !refToken.isEmpty {
            print("[Message Composer]: Tokens are available, will use them for composing")
            contentString += ":\(accToken):\(refToken)"
        } else {
            print("[Message Composer]: No tokens are available, will compsoe without")
        }

        // Potentially more verbose, might be easier to just call Array(contentString.ut8)
//        content = contentString.data(using: .utf8)!.withUnsafeBytes { data in
//            return Array(data)
//        }
        content = Array(contentString.utf8)
        
        do {
            let (header, cipherText) = try Ratchet.encrypt(state: self.state, data: content, AD: self.AD)
            try saveState()
            return formatTransmission(header: header, cipherText: cipherText, platform_letter: platform_letter)
        } catch {
            print("Error saving state message cannot be sent: \(error)")
            throw error
        }
    }
    
    public func emailComposerV1(platform_letter: UInt8, from: String, to: String, cc: String, bcc: String,
                              subject: String,
                              body: String, accessToken: String? = nil, refreshToken: String? = nil) throws -> String {
        
        let fromData = Data(from.utf8)
        let toData = Data(to.utf8)
        let ccData = Data(cc.utf8)
        let bccData = Data(bcc.utf8)
        let subjectData = Data(subject.utf8) // Subject length is UInt8!
        let bodyData = Data(body.utf8)
        
        let fromLength: UInt8 = UInt8(min(fromData.count, Int(UInt8.max)))
        let toLength: UInt16 = UInt16(min(toData.count, Int(UInt16.max)))
        let ccLength: UInt16 = UInt16(min(ccData.count, Int(UInt16.max)))
        let bccLength: UInt16 = UInt16(min(bccData.count, Int(UInt16.max)))
        let subjectLength: UInt8 = UInt8(min(subjectData.count, Int(UInt8.max))) // Subject length is 1 bytes
        let bodyLength: UInt16 = UInt16(min(bodyData.count, Int(UInt16.max)))
        
  
        // Handle optional tokens
        var accessTokenData: Data? = nil
        var accessTokenLength: UInt8 = 0
        if let accToken = accessToken, !accToken.isEmpty {
            accessTokenData = Data(accToken.utf8)
            accessTokenLength = UInt8(min(accessTokenData!.count, Int(UInt8.max)))
        }
        var refreshTokenData: Data? = nil
        var refreshTokenLength: UInt8 = 0
        if let refToken = refreshToken, !refToken.isEmpty {
            refreshTokenData = Data(refToken.utf8)
            refreshTokenLength = UInt8(min(refreshTokenData!.count, Int(UInt8.max)))
        }
        
        // 2. Build the Binary Data
        var contentData = Data()
        
        // Append Lengths
        contentData.append(fromLength)
        contentData.append(contentsOf: withUnsafeBytes(of: toLength.littleEndian) {Data($0)})
        contentData.append(contentsOf: withUnsafeBytes(of: ccLength.littleEndian) {Data($0)})
        contentData.append(contentsOf: withUnsafeBytes(of: bccLength.littleEndian) {Data($0)})
        contentData.append(subjectLength)
        contentData.append(contentsOf: withUnsafeBytes(of: bodyLength.littleEndian) {Data($0)})
        contentData.append(accessTokenLength)
        contentData.append(refreshTokenLength)
        
        // Append values only if their length > 0 and in the same order
        if fromLength > 0 {contentData.append(fromData)}
        if toLength > 0 {contentData.append(toData)}
        if ccLength > 0 {contentData.append(ccData)}
        if bccLength > 0 {contentData.append(bccData)}
        if subjectLength > 0 {contentData.append(subjectData)}
        if bodyLength > 0 {contentData.append(bodyData)}
        if accessTokenLength > 0 {contentData.append(accessTokenData!)}
        if refreshTokenLength > 0 {contentData.append(refreshTokenData!)}
        
        print("[Message Composer]: Successfully formatted binary data for encryption. Size: \(contentData.count) bytes")
        
        // Encryption part
        do {
            let (header, cipherText) = try Ratchet.encrypt(state: self.state, data: Array(contentData), AD: self.AD)
            try saveState()
            return formatTransmissionV1(header: header, cipherText: cipherText, platform_letter: platform_letter)
        } catch {
            print("Error saving state message cannot be sent: \(error)")
            throw error
        }
    }
    
    public func textComposer(platform_letter: UInt8,
                             sender: String,
                             text: String,
                             accessToken: String? = nil,
                             refreshToken: String? = nil) throws -> String {
        
        var content: [UInt8]
        var contentString = "\(sender):\(text)"
    
        // Append the access token and refresh token if they not nil or empty
        if let accToken = accessToken, !accToken.isEmpty,
           let refToken = refreshToken, !refToken.isEmpty {
            print("[Message Composer]: Tokens are available, will use them for composing")
            contentString += ":\(accToken):\(refToken)"
        } else {
            print("[Message Composer]: No tokens are available, will compsoe without")
        }

        // Potentially more verbose, might be easier to just call Array(contentString.ut8)
//        content = contentString.data(using: .utf8)!.withUnsafeBytes { data in
//            return Array(data)
//        }
        content = Array(contentString.utf8)

        do {
            let (header, cipherText) = try Ratchet.encrypt(state: self.state, data: content, AD: self.AD)
            try saveState()
            return formatTransmission(header: header, cipherText: cipherText, platform_letter: platform_letter)
        } catch {
            print("Error saving state message cannot be sent: \(error)")
            throw error
        }
    }
    
    public func textComposerV1(platform_letter: UInt8,
                             sender: String,
                             text: String,
                             accessToken: String? = nil,
                             refreshToken: String? = nil) throws -> String {
        
        let fromData = Data(sender.utf8)
        let bodyData = Data(text.utf8)
        
        let fromLength: UInt8 = UInt8(min(fromData.count, Int(UInt8.max)))
        let toLength: UInt16 = UInt16(0)
        let ccLength: UInt16 = UInt16(0)
        let bccLength: UInt16 = UInt16(0)
        let subjectLength: UInt8 = UInt8(0) // Subject length is 1 byte
        let bodyLength: UInt16 = UInt16(min(bodyData.count, Int(UInt16.max)))
        
  
        // Handle optional tokens
        var accessTokenData: Data? = nil
        var accessTokenLength: UInt8 = 0
        if let accToken = accessToken, !accToken.isEmpty {
            accessTokenData = Data(accToken.utf8)
            accessTokenLength = UInt8(min(accessTokenData!.count, Int(UInt8.max)))
        }
        var refreshTokenData: Data? = nil
        var refreshTokenLength: UInt8 = 0
        if let refToken = refreshToken, !refToken.isEmpty {
            refreshTokenData = Data(refToken.utf8)
            refreshTokenLength = UInt8(min(refreshTokenData!.count, Int(UInt8.max)))
        }
        
        // 2. Build the Binary Data
        var contentData = Data()
        
        // Append Lengths
        contentData.append(fromLength)
        contentData.append(contentsOf: withUnsafeBytes(of: toLength.littleEndian) {Data($0)})
        contentData.append(contentsOf: withUnsafeBytes(of: ccLength.littleEndian) {Data($0)})
        contentData.append(contentsOf: withUnsafeBytes(of: bccLength.littleEndian) {Data($0)})
        contentData.append(subjectLength)
        contentData.append(contentsOf: withUnsafeBytes(of: bodyLength.littleEndian) {Data($0)})
        contentData.append(accessTokenLength)
        contentData.append(refreshTokenLength)
        
        // Append values only if their length > 0 and in the same order
        if fromLength > 0 {contentData.append(fromData)}
        if bodyLength > 0 {contentData.append(bodyData)}
        if accessTokenLength > 0 {contentData.append(accessTokenData!)}
        if refreshTokenLength > 0 {contentData.append(refreshTokenData!)}
        
        print("[Message Composer]: Successfully formatted binary data for encryption. Size: \(contentData.count) bytes")
        
        do {
            let (header, cipherText) = try Ratchet.encrypt(state: self.state, data: Array(contentData), AD: self.AD)
            try saveState()
            return formatTransmissionV1(header: header, cipherText: cipherText, platform_letter: platform_letter)
        } catch {
            print("Error saving state message cannot be sent: \(error)")
            throw error
        }
    }
    
    public func messageComposer(
        platform_letter: UInt8,
        sender: String,
        receiver: String,
        message: String
    ) throws -> String {
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
    
    public func messageComposerV1(
        platform_letter: UInt8,
        sender: String,
        receiver: String,
        message: String
    ) throws -> String {
        
        let fromData = Data(sender.utf8)
        let toData = Data(receiver.utf8)
        let bodyData = Data(message.utf8)
        
        let fromLength: UInt8 = UInt8(min(fromData.count, Int(UInt8.max)))
        let toLength: UInt16 = UInt16(min(toData.count, Int(UInt16.max)))
        let ccLength: UInt16 = UInt16(0)
        let bccLength: UInt16 = UInt16(0)
        let subjectLength: UInt8 = UInt8(0) // Subject length is 1 byte
        let bodyLength: UInt16 = UInt16(min(bodyData.count, Int(UInt16.max)))
        let accessTokenLength: UInt8 = UInt8(0)
        let refreshTokenLength: UInt8 = UInt8(0)
        
        // 2. Build the Binary Data
        var contentData = Data()
        
        // Append Lengths
        contentData.append(fromLength)
        contentData.append(contentsOf: withUnsafeBytes(of: toLength.littleEndian) {Data($0)})
        contentData.append(contentsOf: withUnsafeBytes(of: ccLength.littleEndian) {Data($0)})
        contentData.append(contentsOf: withUnsafeBytes(of: bccLength.littleEndian) {Data($0)})
        contentData.append(subjectLength)
        contentData.append(contentsOf: withUnsafeBytes(of: bodyLength.littleEndian) {Data($0)})
        contentData.append(accessTokenLength)
        contentData.append(refreshTokenLength)
        
        // Append values only if their length > 0 and in the same order
        if fromLength > 0 {contentData.append(fromData)}
        if toLength > 0 {contentData.append(toData)}
        if bodyLength > 0 {contentData.append(bodyData)}

        
        print("[Message Composer]: Successfully formatted binary data for encryption. Size: \(contentData.count) bytes")

        do {
            let (header, cipherText) = try Ratchet.encrypt(state: self.state, data: Array(contentData), AD: self.AD)
            try saveState()
            return formatTransmissionV1(header: header, cipherText: cipherText, platform_letter: platform_letter)
        } catch {
            print("Error saving state message cannot be sent: \(error)")
            throw error
        }
    }
    
    public func bridgeEmailComposer(
        to: String,
        cc: String,
        bcc: String,
        subject: String,
        body: String,
        saveState: Bool = true
    ) throws -> Data {
        let content = "\(to):\(cc):\(bcc):\(subject):\(body)".data(using: .utf8)!.withUnsafeBytes { data in
            return Array(data)
        }
        let (header, cipherText) = try Ratchet.encrypt(state: self.state, data: content, AD: self.AD)
        if(saveState) {
            try self.saveState()
        }
        return formatBridgeTransmission(header: header, cipherText: cipherText)
    }
    
    // Helper methods to format payload
    private func formatBridgeTransmission(header: HEADERS, cipherText: [UInt8]) -> Data {
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
        
        return encryptedContentPayload
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
            data.append(Data(deviceID!))
        }
        print("Sending: \(data.base64EncodedString())")

        return data.base64EncodedString()
    }
    
    private func formatTransmissionV1(header: HEADERS,
                                    cipherText: [UInt8],
                                    platform_letter: UInt8) -> String {
        
        let headerData: Data = header.serialize()
        let headerLength = UInt32(min(headerData.count, Int(UInt32.max))).littleEndian // UInt32 because the header length should be 4 bytes
        
        let versionMarkerData: UInt8 = 0x01 // 1 byte long
        
        // Prapare the payload content
        var fullCipherTextContent = Data()
        fullCipherTextContent.append(contentsOf: withUnsafeBytes(of: headerLength.littleEndian) {Data($0)})
        fullCipherTextContent.append(headerData)
        fullCipherTextContent.append(Data(cipherText))
        guard fullCipherTextContent.count <= Int(UInt16.max) else {
            fatalError("Content payload size exceeds UInt16 maximum")
        }
        
        // Length of content payload
        var fullCipherTextContentLength = UInt16(min(fullCipherTextContent.count, Int(UInt16.max)))
        
        // Device Id length
        let actualDeviceId = useDeviceID ? deviceID : nil
        let deviceIDlength = UInt8(actualDeviceId?.count ?? 0) // Calculate actual length of the device id, 0 if nil/ not used
        
        // Language Code (2 bytes)
        guard languageCode.count == 2 else {
            fatalError("Language code must be exactly 2 bytes long")
        }

        // Data to send
        /// Visual Representation of data
        /// ```plaintext
        /// +----------------+-------------------+------------------+--------------------+-----------------+-----------------+---------------+
        /// | Version Marker | Ciphertext Length | Device ID Length | Platform shortcode | Ciphertext      | Device ID       | Language Code |
        /// | (1 byte)       | (2 bytes)         | (1 byte)         | (1 byte)           | (Variable size) | (Variable size) | (2 bytes)     |
        /// +----------------+-------------------+------------------+--------------------+-----------------+-----------------+---------------+
        /// ```
        
        var finalData = Data()
        //Version
        finalData.append(versionMarkerData)
        //Payload length
        finalData.append(contentsOf: withUnsafeBytes(of: fullCipherTextContentLength.littleEndian) {Data($0)})
        //Device ID length
        finalData.append(contentsOf: withUnsafeBytes(of: deviceIDlength.littleEndian){Data($0)})
        //Platform shortcode
        finalData.append(contentsOf: withUnsafeBytes(of: platform_letter.littleEndian){Data($0)})
        //Encrypted message content/Ciphertext/payload
        finalData.append(fullCipherTextContent)
        //Device ID if used
        if let id = actualDeviceId {
            finalData.append(Data(id))
        }
        //LanguageCode
        finalData.append(Data(languageCode))
        print("[Payload Formatter V1] formatted content to send: \(finalData.base64EncodedString())")
        return finalData.base64EncodedString()
    }
    
    public func decryptBridgeMessage(payload: [UInt8]) throws -> [UInt8]? {
        let lenHeader = Data(payload[0..<4]).withUnsafeBytes { $0.load(as: Int32.self) }.littleEndian
        guard let header = HEADERS.deserialize(serializedData: Data(payload[4..<(4+Int(lenHeader))])) else {
            print("Issue constructing header...")
            return nil
        }
        let cipherText = Array(payload[(4+Int(lenHeader))..<payload.count])
        
        let text = try Ratchet.decrypt(
            state: self.state,
            header: header,
            cipherText: cipherText,
            AD: self.AD,
            keystoreAlias: self.keystoreAlias
        )
        try self.saveState()
//        return String(decoding: text, as: Unicode.UTF8.self)
        return text
    }
}
