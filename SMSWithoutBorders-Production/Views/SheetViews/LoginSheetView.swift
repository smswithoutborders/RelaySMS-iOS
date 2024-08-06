//
//  LoginSheetView.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 14/06/2024.
//

import SwiftUI
struct SecuredTextInputField: View {
    let placeHolder: String
    @Binding var textValue: String
    
    var body: some View {
        ZStack(alignment: .leading) {
            Text(placeHolder)
                .foregroundColor(Color(.placeholderText))
                .offset(y: textValue.isEmpty ? 0 : -25)
                .scaleEffect(textValue.isEmpty ? 1: 0.8, anchor: .leading)
            SecureField("", text: $textValue)
        }
        .padding(.top, textValue.isEmpty ? 0 : 15)
        .frame(height: 52)
        .padding(.horizontal, 16)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(lineWidth: 1).foregroundColor(.gray))
        .animation(.default)
    }
}
struct TextInputField: View {
    let placeHolder: String
    @Binding var textValue: String
    
    var body: some View {
        ZStack(alignment: .leading) {
            Text(placeHolder)
                .foregroundColor(Color(.placeholderText))
                .offset(y: textValue.isEmpty ? 0 : -25)
                .scaleEffect(textValue.isEmpty ? 1: 0.8, anchor: .leading)
            TextField("", text: $textValue)
        }
        .padding(.top, textValue.isEmpty ? 0 : 15)
        .frame(height: 52)
        .padding(.horizontal, 16)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(lineWidth: 1).foregroundColor(.gray))
        .animation(.default)
    }
}

struct LoginSheetView: View {
    
    #if DEBUG
        @State private var phoneNumber: String = "+237123456"
        @State private var password: String = "LL<O3ZG~=z-epkv"
    #else
        @State private var phoneNumber: String = ""
        @State private var password: String = ""
    #endif
    
    @State private var OTPRequired = false
    @State private var countryCode: String? = nil
    
    @State private var isLoading = false

    @State var work: Task<Void, Never>?
    
    @Binding var completed: Bool
    @Binding var failed: Bool
    
    @State var otpRetryTimer: Int = 0
    @State var errorMessage: String = ""

    var body: some View {
        if(OTPRequired) {
            OTPSheetView(type: OTPAuthType.TYPE.AUTHENTICATE,
                         retryTimer: otpRetryTimer, phoneNumber: $phoneNumber,
                         countryCode: $countryCode,
                         password: $password,
                         completed: $completed,
                         failed: $failed)
        }
        else {
            VStack {
                VStack {
                    Image("Logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 75, height: 75)
//                        .padding(.bottom, 10)
//                        .padding(.top, 10)
                        .padding()

                    Text("Login")
                        .font(.title)
                        .bold()
                        .padding()
                    
                    Group {
                        Text("Welcome back")
                        Text("Sign in to continue with existing account")
                    }
                    .foregroundStyle(.gray)
                    .font(.subheadline)
                }
                .padding(.bottom, 30)

                VStack {
                    TextInputField(placeHolder: "Phone Number", textValue: $phoneNumber)
                        .padding(.bottom, 15)
                    Button {
                    } label: {
                        Text("Forgot password?")
                            .bold()
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    SecuredTextInputField(placeHolder: "Password", textValue: $password)
                }
                .padding()
                Spacer()

                VStack{
                    if(isLoading) {
                        ProgressView()
                    }
                    else {
                        Button {
                            isLoading = true
                            Task {
                                do {
                                    self.otpRetryTimer = try await signupOrAuthenticate(
                                        phoneNumber: phoneNumber,
                                        countryCode: "",
                                        password: password,
                                        type: OTPAuthType.TYPE.AUTHENTICATE)
                                    self.OTPRequired = true
                                } catch Vault.Exceptions.requestNotOK(let status){
                                    print("Something went wrong authenticating: \(status)")
                                    isLoading = false
                                    failed = true
                                    var (field, message) = Vault.parseErrorMessage(message: status.message) ?? (nil, status.message)
                                    errorMessage = message!
                                }
                            }
                        } label: {
                            Text("Login")
                                .bold()
                                .frame(maxWidth: .infinity, maxHeight: 35)
//                                .frame(width: 200 , height: 50, alignment: .center)
                        }
                        .buttonStyle(.borderedProminent)
                        .alert(isPresented: $failed) {
                            Alert(title: Text("Error"), message: Text(errorMessage))
                        }
                        
                        HStack {
                            Text("Don't have an account?")
                                .foregroundStyle(.gray)
                            Button {
                                
                            } label: {
                                Text("Create account")
                                    .bold()
                            }
                        }
                        .font(.subheadline)
                        .padding()
                    }
                }
                .padding()
            }
        }
    }
}

#Preview {
    
    @State var completed: Bool = false
    @State var failed: Bool = false
    LoginSheetView(completed: $completed, failed: $failed)
}
