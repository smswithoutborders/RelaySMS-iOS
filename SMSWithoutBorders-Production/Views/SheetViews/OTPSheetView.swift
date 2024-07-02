//
//  OTPSheetViewswift.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 01/07/2024.
//

import SwiftUI
import CryptoKit
import Fernet

func storeLongLivedToken(llt: String) {
    let lltKeystoreAlias = "longlivedtoken_keystoreAlias"
    let retrievedLlt = CSecurity.findInKeyChain(keystoreAlias: lltKeystoreAlias)
    if(retrievedLlt != nil && retrievedLlt != llt) {
        CSecurity.storeInKeyChain(data: llt, keystoreAlias: lltKeystoreAlias)
    }
}


func signup2(phoneNumber: String, 
             countryCode: String,
             password: String,
             otpCode: String) throws {
    let vault = Vault()
    var keystoreAliasPublishPubKey = "vault-publish-keystoreAlias"
    var keystoreAliasDeviceIDPubKey = "valut-device-id-keystoreAlias"
    
    CSecurity.deleteFromKeyChain(keystoreAlias: keystoreAliasPublishPubKey)
    CSecurity.deleteFromKeyChain(keystoreAlias: keystoreAliasDeviceIDPubKey)

    var clientDeviceIDPrivateKey: Curve25519.KeyAgreement.PrivateKey?
    
    var clientPublishPubKey: String
    var clientDeviceIDPubKey: String
    do {
        clientDeviceIDPrivateKey = try SecurityCurve25519.generateKeyPair(keystoreAlias: keystoreAliasDeviceIDPubKey).privateKey
        clientDeviceIDPubKey = clientDeviceIDPrivateKey!.publicKey.rawRepresentation.base64EncodedString()
        clientPublishPubKey = try SecurityCurve25519.generateKeyPair(keystoreAlias: keystoreAliasPublishPubKey).privateKey .publicKey.rawRepresentation.base64EncodedString()
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
    
    let peerPublicKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: response.serverDeviceIDPubKey.base64Decoded())
    
    let sharedKey = try SecurityCurve25519.calculateSharedSecret(
        privateKey: clientDeviceIDPrivateKey!,
        publicKey: peerPublicKey).withUnsafeBytes {
            return Data(Array($0))
        }
        
    let fernetToken = try Fernet(key: Data(sharedKey))
    let decodedOutput = try fernetToken.decode(Data(base64Encoded: response.longLivedToken)!)
    
    let llt = String(data: decodedOutput.data, encoding: .utf8)
    storeLongLivedToken(llt: llt!)
    
    // TODO: store public key
}


struct OTPSheetView: View {
    @State private var otpCode: String = ""
    @State private var loading: Bool = false
    @State private var work: Task<Void, Never>?
    
    @Binding var phoneNumber: String
    @Binding var countryCode: String
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
                                countryCode: countryCode,
                                password: password,
                                otpCode: otpCode )
                        } catch {
                            
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
    @State var countryCode: String = ""
    @State var loading: Bool = false
    OTPSheetView(phoneNumber: $phoneNumber,
                 countryCode: $countryCode,
                 password: $password)
}
