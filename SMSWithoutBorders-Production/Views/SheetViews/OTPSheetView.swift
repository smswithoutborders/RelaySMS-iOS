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
        print("Signing in with phone number: \(phoneNumber)")
        print("Country code: \(countryCode)")
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

struct OTPView: View {
    @Binding var otpCode: String
    @Binding var loading: Bool
    
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
    }
}



struct OTPSheetView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var context

    #if DEBUG
        @State private var otpCode: String = "123456"
    #else
        @State private var otpCode: String = ""
    #endif
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    @State private var canRetry: Bool = false
    @State public var type: OTPAuthType.TYPE = OTPAuthType.TYPE.AUTHENTICATE
    @State public var retryTimer: Int = 0
    @State private var timeTillRetry: Int = 0
    
    @State var errorMessage: String = ""
    @State var isLoading: Bool = false

    @Binding var countryCode: String
    @Binding var phoneNumber: String
    @Binding var password: String
    @Binding var completed: Bool
    @Binding var isLoggedIn: Bool
    @Binding var failed: Bool
    

    var body: some View {
        VStack {
            OTPView(otpCode: $otpCode, loading: $isLoading)
                .textFieldStyle(.roundedBorder)
            
            if(isLoading) {
                ProgressView()
            }
            else {
                VStack {
                    Button {
                        isLoading = true
                        Task {
                            do {
                                try await signupAuthenticateRecover(phoneNumber: phoneNumber,
                                                          countryCode: countryCode,
                                                          password: password,
                                                               type: type,
                                                               otpCode: otpCode,
                                                               context: context)
                                completed = true
                                isLoggedIn = true
                                dismiss()
                            } catch Vault.Exceptions.requestNotOK(let status){
                                failed = true
                                errorMessage = status.message!
                            } catch {
                                failed = true
                                errorMessage = error.localizedDescription
                            }
                            isLoading = false
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
    
    
}

//struct OTPSheetView_Preview: PreviewProvider {
//    static var previews: some View {
//        @State var otpCode: String = ""
//        @State var password: String = ""
//        @State var phoneNumber: String = ""
//        @State var countryCode: String? = ""
//        @State var loading: Bool = false
//        @State var completed: Bool = false
//        @State var failed: Bool = false
//        OTPSheetView(type: OTPAuthType.TYPE.CREATE,
//                     retryTimer: Int(Date().timeIntervalSince1970) + 10,
//                     phoneNumber: phoneNumber,
//                     countryCode: countryCode,
//                     password: $password,
//                     completed: $completed,
//                     isLoggedIn: $completed, failed: $failed)
//    }
//}

//#Preview {
//}

struct OTPSheetView_Preview: PreviewProvider {
    static var previews: some View {
        @State var password: String = ""
        @State var completed: Bool = false
        @State var isLoggedIn: Bool = false
        @State var failed: Bool = false
        
        @State var countryCode: String = "+237"
        @State var phoneNumber: String = "+12345678"

        OTPSheetView(
            countryCode: $countryCode,
            phoneNumber: $phoneNumber,
            password: $password,
            completed: $completed,
            isLoggedIn: $isLoggedIn,
            failed: $failed)
        
//        OTPView(otpCode: $otpCode, loading: $isLoading)
    }
}
