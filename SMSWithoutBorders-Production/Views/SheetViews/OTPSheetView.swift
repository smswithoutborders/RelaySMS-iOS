//
//  OTPSheetViewswift.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 01/07/2024.
//

import SwiftUI
import CryptoKit
import Fernet

func authenticate2() {
    
}


func signup2(phoneNumber: String, 
             countryCode: String,
             password: String,
             otpCode: String) throws {
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
    
    let response = try vault.createEntity2(
        phoneNumber: phoneNumber,
        countryCode: countryCode,
        password: password,
        clientPublishPubKey: clientPublishPubKey,
        clientDeviceIdPubKey: clientDeviceIDPubKey,
        ownershipResponse: otpCode)
    
    try processOTP(peerDeviceIDPubKey: try response.serverDeviceIDPubKey.base64Decoded(),
               peerPublishPubKey: response.serverPublishPubKey.base64Decoded(),
               llt: response.longLivedToken,
               clientDeviceIDPrivateKey: clientDeviceIDPrivateKey!,
               clientPublishPrivateKey: clientPublishPrivateKey!)
}

private func processOTP(peerDeviceIDPubKey: [UInt8],
                        peerPublishPubKey: [UInt8],
                        llt: String,
                        clientDeviceIDPrivateKey: Curve25519.KeyAgreement.PrivateKey,
                        clientPublishPrivateKey: Curve25519.KeyAgreement.PrivateKey) throws {
    
    let longLivedTokenKeystoreAlias = "com.afkanerd.relaysms.long_lived_token"
    let publishingSharedKeyKeystoreAlias = "com.afkanerd.relaysms.publishing_shared_key"

    let peerPublicKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: peerDeviceIDPubKey)
    
    let sharedKey = try SecurityCurve25519.calculateSharedSecret(
        privateKey: clientDeviceIDPrivateKey,
        publicKey: peerPublicKey).withUnsafeBytes {
            return Data(Array($0))
        }
        
    let fernetToken = try Fernet(key: Data(sharedKey))
    let decodedOutput = try fernetToken.decode(Data(base64Encoded: llt)!)
    
    let llt = String(data: decodedOutput.data, encoding: .utf8)
    let peerPublishPublicKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: peerPublishPubKey)
    
    let publishingSharedKey = try SecurityCurve25519.calculateSharedSecret(
        privateKey: clientPublishPrivateKey, publicKey: peerPublishPublicKey).withUnsafeBytes {
            return Data(Array($0))
        }
    
    try CSecurity.storeInKeyChain(data: llt!.data(using: .utf8)!, keystoreAlias: longLivedTokenKeystoreAlias)
    try CSecurity.storeInKeyChain(data: publishingSharedKey, keystoreAlias: publishingSharedKeyKeystoreAlias)
}


struct OTPSheetView: View {
    enum TYPE {
        case AUTHENTICATE
        case CREATE
    }
    @State private var otpCode: String = ""
    @State private var loading: Bool = false
    @State private var work: Task<Void, Never>?
    
    @State public var type: TYPE

    @Binding var phoneNumber: String
    @Binding var countryCode: String?
    @Binding var password: String

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
                Button(action: {
                    work = Task {
                        do {
                            try signup2(
                                phoneNumber: phoneNumber,
                                countryCode: countryCode!,
                                password: password,
                                otpCode: otpCode )
                        } catch {
                            print("Error with second phase signup: \(error)")
                        }
                    }
                    loading = true
                }, label: {
                    Text("Submit")
                        .foregroundColor(.white)
                        .frame(width: 200, height: 40)
                        .background(.blue)
                        .cornerRadius(15)
                        .padding()
                })
                
                Button("Resend code") {
                    
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
    OTPSheetView(type: OTPSheetView.TYPE.CREATE, phoneNumber: $phoneNumber,
                 countryCode: $countryCode,
                 password: $password)
}
