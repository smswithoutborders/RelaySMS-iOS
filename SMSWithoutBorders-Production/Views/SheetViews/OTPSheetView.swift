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
        case RECOVER
    }
}


private nonisolated func processOTP(peerDeviceIdPubKey: [UInt8],
                        publishPubKey: [UInt8],
                        llt: String,
                        clientDeviceIDPrivateKey: Curve25519.KeyAgreement.PrivateKey,
                                    clientPublishPrivateKey: Curve25519.KeyAgreement.PrivateKey,
                                    phoneNumber: String) throws -> String {

    let peerDeviceIdPublicKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: peerDeviceIdPubKey)
    let peerPublishPublicKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: publishPubKey)

    let deviceIdSharedKey = try SecurityCurve25519.calculateSharedSecret(
        privateKey: clientDeviceIDPrivateKey, publicKey: peerDeviceIdPublicKey).withUnsafeBytes {
            return Array($0)
        }
        
    let fernetToken = try Fernet(key: Data(deviceIdSharedKey))
    let decodedOutput = try fernetToken.decode(Data(base64Encoded: llt)!)
    
    let llt = String(data: decodedOutput.data, encoding: .utf8)
    print("llt: \(llt)")

    let publishingSharedKey = try SecurityCurve25519.calculateSharedSecret(
        privateKey: clientPublishPrivateKey, publicKey: peerPublishPublicKey).withUnsafeBytes {
            return Array($0)
        }
    
    CSecurity.deletePasswordFromKeychain(keystoreAlias: Vault.VAULT_LONG_LIVED_TOKEN)
    CSecurity.deletePasswordFromKeychain(keystoreAlias: Publisher.PUBLISHER_SHARED_KEY)

    let deviceID = try Vault.getDeviceID(derivedKey: deviceIdSharedKey,
                                         phoneNumber: phoneNumber,
                                         publicKey: clientDeviceIDPrivateKey.publicKey.rawRepresentation.bytes)
    
    print("Peer publish pubkey raw: \(publishPubKey.toBase64())")
    UserDefaults.standard.set(deviceID, forKey: Vault.VAULT_DEVICE_ID)
    UserDefaults.standard.set(publishPubKey, forKey: Publisher.PUBLISHER_SERVER_PUBLIC_KEY)
    
    let AD: [UInt8] = UserDefaults.standard.object(forKey: Publisher.PUBLISHER_SERVER_PUBLIC_KEY) as! [UInt8]
    print("Peer publish pubkey retrieved: \(AD.toBase64())")

    try CSecurity.storeInKeyChain(data: llt!.data(using: .utf8)!,
                                  keystoreAlias: Vault.VAULT_LONG_LIVED_TOKEN)
    try CSecurity.storeInKeyChain(data: Data(publishingSharedKey),
                                  keystoreAlias: Publisher.PUBLISHER_SHARED_KEY)
    
    return llt!
}

func generateNewKeypairs() throws -> (
    publisherPublicKey: Curve25519.KeyAgreement.PrivateKey,
    deviceIDPublicKey: Curve25519.KeyAgreement.PrivateKey) {
    
        CSecurity.deleteKeyFromKeychain(keystoreAlias: Publisher.PUBLISHER_PUBLIC_KEY_KEYSTOREALIAS)
        CSecurity.deleteKeyFromKeychain(keystoreAlias: Vault.DEVICE_PUBLIC_KEY_KEYSTOREALIAS)

        var clientDeviceIDPrivateKey: Curve25519.KeyAgreement.PrivateKey?
        var clientPublishPrivateKey: Curve25519.KeyAgreement.PrivateKey?
        
        do {
            clientDeviceIDPrivateKey = try SecurityCurve25519.generateKeyPair(keystoreAlias: Vault.DEVICE_PUBLIC_KEY_KEYSTOREALIAS).privateKey
            
            clientPublishPrivateKey = try SecurityCurve25519.generateKeyPair(keystoreAlias: Publisher.PUBLISHER_PUBLIC_KEY_KEYSTOREALIAS).privateKey
        } catch {
            throw error
        }
        return (clientPublishPrivateKey!, clientDeviceIDPrivateKey!)
}


nonisolated func signupAuthenticateRecover(
    phoneNumber: String,
    countryCode: String?,
    password: String,
    type: OTPAuthType.TYPE,
    otpCode: String? = nil,
    context: NSManagedObjectContext? = nil) async throws -> Int {
        print("country code: \(countryCode), phoneNumber: \(phoneNumber)")
    
    let (publishPrivateKey, deviceIdPrivateKey) = try generateNewKeypairs()
    let clientPublishPubKey = publishPrivateKey.publicKey.rawRepresentation.base64EncodedString()
    
    let clientDeviceIDPubKey = deviceIdPrivateKey.publicKey.rawRepresentation.base64EncodedString()
    
    let vault = Vault()

    if(type == OTPAuthType.TYPE.CREATE) {
        let response = try vault.createEntity(
            phoneNumber: phoneNumber,
            countryCode: countryCode!,
            password: password,
            clientPublishPubKey: clientPublishPubKey,
            clientDeviceIdPubKey: clientDeviceIDPubKey,
            ownershipResponse: otpCode)
        
        if(otpCode != nil) {
            try processOTP(peerDeviceIdPubKey: try response.serverDeviceIDPubKey.base64Decoded(),
                           publishPubKey: response.serverPublishPubKey.base64Decoded(),
                       llt: response.longLivedToken,
                           clientDeviceIDPrivateKey: deviceIdPrivateKey,
                           clientPublishPrivateKey: publishPrivateKey,
                           phoneNumber: phoneNumber)
            
        }
        return Int(response.nextAttemptTimestamp)

    } else if type == OTPAuthType.TYPE.AUTHENTICATE {
        let response = try vault.authenticateEntity(
            phoneNumber: phoneNumber,
            password: password,
            clientPublishPubKey: clientPublishPubKey,
            clientDeviceIDPubKey: clientDeviceIDPubKey,
            ownershipResponse: otpCode)
        
        
        if(otpCode != nil) {
            let llt = try processOTP(peerDeviceIdPubKey: try response.serverDeviceIDPubKey.base64Decoded(),
                                     publishPubKey: response.serverPublishPubKey.base64Decoded(),
                       llt: response.longLivedToken,
                       clientDeviceIDPrivateKey: deviceIdPrivateKey,
                                     clientPublishPrivateKey: publishPrivateKey,
                                     phoneNumber: phoneNumber)
            
            let publisher = Publisher()
            try vault.refreshStoredTokens(llt: llt, context: context!)
            print("successfully refreshed stored tokens...")
        }
        return Int(response.nextAttemptTimestamp)
        
    } else {
        print("Recovering password")
        let response = try vault.recoverPassword(
            phoneNumber: phoneNumber,
            newPassword: password,
            clientPublishPubKey: clientPublishPubKey,
            clientDeviceIdPubKey: clientDeviceIDPubKey,
            ownershipResponse: otpCode)
        
        if(otpCode != nil) {
            let llt = try processOTP(peerDeviceIdPubKey: try response.serverDeviceIDPubKey.base64Decoded(),
                                     publishPubKey: response.serverPublishPubKey.base64Decoded(),
                       llt: response.longLivedToken,
                       clientDeviceIDPrivateKey: deviceIdPrivateKey,
                                     clientPublishPrivateKey: publishPrivateKey,
                                     phoneNumber: phoneNumber)
            
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
    @State private var canRetry: Bool = false

    @State public var type: OTPAuthType.TYPE
    
    @State public var retryTimer: Int
    @State private var timeTillRetry: Int = 0
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    @State var phoneNumber: String
    @Binding var countryCode: String?
    @Binding var password: String
    
    @Binding var completed: Bool
    @Binding var failed: Bool
    
    @State var errorMessage: String = ""


    var body: some View {
        VStack {
            Text("Verify your Phone number")
                .bold()
                .padding()
                .font(.title2)
            
            Text("Enter code sent by SMS")
                .padding()
                .font(.subheadline)
            
            TextField("OTP Code", text: $otpCode)
                .textFieldStyle(.plain)
                .frame(height: 20)
                .clipShape(Capsule())
                .padding()
                .overlay(RoundedRectangle(cornerRadius:10.0)
                    .strokeBorder(Color.blue, style: StrokeStyle(lineWidth: 1.0)))
                .padding()
                .disabled(loading)
        
        }
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
                            try await signupAuthenticateRecover(phoneNumber: phoneNumber,
                                                      countryCode: countryCode,
                                                      password: password,
                                                           type: type,
                                                           otpCode: otpCode,
                                                           context: datastore)
                            completed = true
                            dismiss()
                        } catch Vault.Exceptions.requestNotOK(let status){
                            print("Something went wrong authenticating: \(status)")
                            failed = true
                            errorMessage = status.message!
                        } catch {
                            failed = true
                            errorMessage = error.localizedDescription
                        }
                        loading = false
                    }
                } label: {
                    Text("Verify")
                        .bold()
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, maxHeight: 50)
                        .background(.blue)
                        .cornerRadius(15)
                        .padding()
                }
                .alert(isPresented: $failed) {
                    Alert(title: Text("Error"), message: Text(errorMessage))
                }

                HStack {
                    Button("Resend code") {
                        dismiss()
                    }
                    .disabled(timeTillRetry > -1)
                    if timeTillRetry > -1 {
                        Text("in \(timeTillRetry) seconds").onReceive(timer) { _ in
                            guard !canRetry else { return }
                            timeTillRetry = retryTimer - Int(Date().timeIntervalSince1970)
                            canRetry = timeTillRetry < 0
                        }
                    }
                }
            }
        }
    }
    
    
}

struct OTPSheetView_Preview: PreviewProvider {
    static var previews: some View {
        @State var otpCode: String = ""
        @State var password: String = ""
        @State var phoneNumber: String = ""
        @State var countryCode: String? = ""
        @State var loading: Bool = false
        @State var completed: Bool = false
        @State var failed: Bool = false
        OTPSheetView(type: OTPAuthType.TYPE.CREATE,
                     retryTimer: Int(Date().timeIntervalSince1970) + 10,
                     phoneNumber: phoneNumber,
                     countryCode: $countryCode,
                     password: $password,
                     completed: $completed,
                     failed: $failed)
    }
}
