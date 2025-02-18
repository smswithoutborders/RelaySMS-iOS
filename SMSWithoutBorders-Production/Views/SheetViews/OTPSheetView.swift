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
    context: NSManagedObjectContext? = nil
) async throws -> Int {
    print("country code: \(countryCode), phoneNumber: \(phoneNumber)")
    
    let vault = Vault()

    if(type == OTPAuthType.TYPE.CREATE) {
        let response = try vault.createEntity(
            phoneNumber: phoneNumber,
            countryCode: countryCode!,
            password: password,
            ownershipResponse: otpCode
        )
        
        return Int(response.nextAttemptTimestamp)

    } else if type == OTPAuthType.TYPE.AUTHENTICATE {
        let response = try vault.authenticateEntity(
            phoneNumber: phoneNumber,
            password: password,
            ownershipResponse: otpCode
        )
        
        return Int(response.nextAttemptTimestamp)
        
    } else {
        print("Recovering password")
        let response = try vault.recoverPassword(
            phoneNumber: phoneNumber,
            newPassword: password,
            ownershipResponse: otpCode
        )
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
    @Binding var failed: Bool
    @Binding var completedSuccessfully: Bool

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
                                try await signupAuthenticateRecover(
                                    phoneNumber: phoneNumber,
                                    countryCode: countryCode,
                                    password: password,
                                    type: type,
                                    otpCode: otpCode,
                                    context: context
                                )
                                completedSuccessfully = true
                                dismiss()
                            } catch Vault.Exceptions.requestNotOK(let status){
                                failed = true
                                errorMessage = status.message!
                                isLoading = false
                            } catch {
                                failed = true
                                errorMessage = error.localizedDescription
                                isLoading = false
                            }
                        }
                    } label: {
                        Text("Verify")
                            .bold()
                            .frame(maxWidth: .infinity, maxHeight: 35)
                    }
                    .alert(isPresented: $failed) {
                        Alert(title: Text("Error"), message: Text(errorMessage))
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.bottom, 32)

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
                .padding()
            }
        }
    }
}

struct OTPSheetView_Preview: PreviewProvider {
    static var previews: some View {
        @State var completed: Bool = false
        @State var completedSuccessfully: Bool = false
        @State var isLoggedIn: Bool = false
        @State var failed: Bool = false
        
        @State var countryCode: String = "CM"
        @State var phoneNumber = "1123457528"
        @State var phoneCode = "+237"
        @State var password: String = "dMd2Kmo9#"

        OTPSheetView(
            countryCode: $countryCode,
            phoneNumber: $phoneNumber,
            password: $password,
            failed: $failed,
            completedSuccessfully: $completedSuccessfully
        )
        
//        OTPView(otpCode: $otpCode, loading: $isLoading)
    }
}
