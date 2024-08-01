//
//  OTPSheetViewswift.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 01/07/2024.
//

import SwiftUI
import CryptoKit
import Fernet
import CoreData
import SwobDoubleRatchet

public class OTPAuthType {
    public enum TYPE {
        case AUTHENTICATE
        case CREATE
    }
}


private nonisolated func processOTP(peerDeviceIDPubKey: [UInt8],
                        peerPublishPubKey: [UInt8],
                        llt: String,
                        clientDeviceIDPrivateKey: Curve25519.KeyAgreement.PrivateKey,
                        clientPublishPrivateKey: Curve25519.KeyAgreement.PrivateKey) throws -> String {

    let peerPublicKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: peerDeviceIDPubKey)
    
    let sharedKey = try SecurityCurve25519.calculateSharedSecret(
        privateKey: clientDeviceIDPrivateKey,
        publicKey: Curve25519.KeyAgreement.PublicKey(rawRepresentation: peerPublishPubKey)).withUnsafeBytes { data in
            return Array(data)
        }
        
    let fernetToken = try Fernet(key: Data(sharedKey))
    let decodedOutput = try fernetToken.decode(Data(base64Encoded: llt)!)
    
    let llt = String(data: decodedOutput.data, encoding: .utf8)
    let peerPublishPublicKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: peerPublishPubKey)
    
    let publishingSharedKey = try SecurityCurve25519.calculateSharedSecret(
        privateKey: clientPublishPrivateKey, publicKey: peerPublishPublicKey).withUnsafeBytes {
            return Data(Array($0))
        }
    
    CSecurity.deletePasswordFromKeychain(keystoreAlias: Vault.VAULT_LONG_LIVED_TOKEN)
    CSecurity.deletePasswordFromKeychain(keystoreAlias: Publisher.PUBLISHER_SHARED_KEY)

    try CSecurity.storeInKeyChain(data: llt!.data(using: .utf8)!, 
                                  keystoreAlias: Vault.VAULT_LONG_LIVED_TOKEN)
    try CSecurity.storeInKeyChain(data: publishingSharedKey,
                                  keystoreAlias: Publisher.PUBLISHER_SHARED_KEY)
    
    return llt!
}


nonisolated func signupOrAuthenticate(phoneNumber: String,
                               countryCode: String?,
                               password: String,
                                      type: OTPAuthType.TYPE,
                                      otpCode: String? = nil,
                                      context: NSManagedObjectContext? = nil) async throws -> Int {
    let vault = Vault()
    var keystoreAliasPublishPubKey = "relaysms-publish-keystoreAlias"
    var keystoreAliasDeviceIDPubKey = "relaysms-deviceid-keystoreAlias"
    
    CSecurity.deleteKeyFromKeychain(keystoreAlias: keystoreAliasPublishPubKey)
    CSecurity.deleteKeyFromKeychain(keystoreAlias: keystoreAliasDeviceIDPubKey)

    var clientDeviceIDPrivateKey: Curve25519.KeyAgreement.PrivateKey?
    var clientPublishPrivateKey: Curve25519.KeyAgreement.PrivateKey?

    var clientPublishPubKey: String
    var clientDeviceIDPubKey: String
    do {
        clientDeviceIDPrivateKey = try SecurityCurve25519.generateKeyPair(keystoreAlias: keystoreAliasDeviceIDPubKey).privateKey
        clientDeviceIDPubKey = clientDeviceIDPrivateKey!.publicKey.rawRepresentation.base64EncodedString()
        
        clientPublishPrivateKey = try SecurityCurve25519.generateKeyPair(keystoreAlias: keystoreAliasPublishPubKey).privateKey
        clientPublishPubKey = clientPublishPrivateKey!.publicKey.rawRepresentation.base64EncodedString()
    } catch {
        throw error
    }
    
    if(type == OTPAuthType.TYPE.CREATE) {
        let response = try vault.createEntity(
            phoneNumber: phoneNumber,
            countryCode: countryCode!,
            password: password,
            clientPublishPubKey: clientPublishPubKey,
            clientDeviceIdPubKey: clientDeviceIDPubKey,
            ownershipResponse: otpCode)
        
        if(otpCode != nil) {
            try processOTP(peerDeviceIDPubKey: try response.serverDeviceIDPubKey.base64Decoded(),
                       peerPublishPubKey: response.serverPublishPubKey.base64Decoded(),
                       llt: response.longLivedToken,
                       clientDeviceIDPrivateKey: clientDeviceIDPrivateKey!,
                       clientPublishPrivateKey: clientPublishPrivateKey!)
            
        }
        return Int(response.nextAttemptTimestamp)

    } else {
        let response = try vault.authenticateEntity(
            phoneNumber: phoneNumber,
            password: password,
            clientPublishPubKey: clientPublishPubKey,
            clientDeviceIDPubKey: clientDeviceIDPubKey,
            ownershipResponse: otpCode)
        
        
        if(otpCode != nil) {
            let llt = try processOTP(peerDeviceIDPubKey: try response.serverDeviceIDPubKey.base64Decoded(),
                       peerPublishPubKey: response.serverPublishPubKey.base64Decoded(),
                       llt: response.longLivedToken,
                       clientDeviceIDPrivateKey: clientDeviceIDPrivateKey!,
                       clientPublishPrivateKey: clientPublishPrivateKey!)
            
            let publisher = Publisher()
            try vault.refreshStoredTokens(llt: llt, context: context!)
            print("successfully refreshed stored tokens...")
        }
        return Int(response.nextAttemptTimestamp)
    }
}



struct OTPSheetView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var datastore

    #if DEBUG
        @State private var otpCode: String = "123456"
    #else
        @State private var otpCode: String = ""
    #endif
    
    @State private var loading: Bool = false
    
    @State public var type: OTPAuthType.TYPE
    
    @State public var retryTimer: Int
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    @Binding var phoneNumber: String
    @Binding var countryCode: String?
    @Binding var password: String
    
    @Binding var completed: Bool
    @Binding var failed: Bool
    

    var body: some View {
        VStack {
            TextField("OTP Code", text: $otpCode)
                .disableAutocorrection(true)
                .border(.secondary)
                .disabled(loading)
            
        }
        .padding()
        .textFieldStyle(.roundedBorder)
        
        if(loading) {
            ProgressView()
        }
        else {
            VStack {
                Button {
                    loading = true
                    Task {
                        do {
                            try await signupOrAuthenticate(phoneNumber: phoneNumber,
                                                      countryCode: countryCode,
                                                      password: password,
                                                           type: type,
                                                           otpCode: otpCode,
                                                           context: datastore)
                        } catch {
                            print("Error with second phase signup: \(error)")
                            failed = true
                        }
                        completed = true
                        dismiss()
                    }
                } label: {
                    Text("Submit")
                        .foregroundColor(.white)
                        .frame(width: 200, height: 40)
                        .background(.blue)
                        .cornerRadius(15)
                        .padding()
                }
                
                HStack {
                    Button("Resend code") {
                        dismiss()
                    }
                    Text("(\(retryTimer))").onReceive(timer) { _ in
                        if retryTimer > 0 {
                            retryTimer -= 1
                        }
                    }
                }
            }
        }
    }
    
    
}



#Preview {
    @State var otpCode: String = ""
    @State var password: String = ""
    @State var phoneNumber: String = ""
    @State var countryCode: String? = ""
    @State var loading: Bool = false
    @State var completed: Bool = false
    @State var failed: Bool = false
    OTPSheetView(type: OTPAuthType.TYPE.CREATE,
                 retryTimer: 100000, 
                 phoneNumber: $phoneNumber,
                 countryCode: $countryCode,
                 password: $password,
                 completed: $completed,
                 failed: $failed)
}
