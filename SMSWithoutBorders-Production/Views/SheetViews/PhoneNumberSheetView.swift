//
//  PhoneNumberSheetView.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 03/08/2024.
//

import SwiftUI
import CountryPicker

struct PhoneNumberCodeEntryView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var context
    
    var platformName: String
    @Binding var phoneNumber: String
    @Binding var completed: Bool

    @State var loading = false
    @State var failed = false
    
    @State var code: String = ""
    @State var errorMessage: String = ""

    var body: some View {
        VStack {
            TextField("Enter code", text: $code)
                .padding()
                .keyboardType(.numberPad)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .controlSize(.large)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(lineWidth: 1)
                        .foregroundColor(.gray)
                )

            if loading {
                ProgressView()
                    .padding()
            }
            else {
                Button("Submit") {
                    phoneNumberAuthExchange()
                }
                .buttonStyle(.borderedProminent)
                .padding()
                .controlSize(.large)
                .disabled(code.count < 3)
            }
        }
        .padding()
        .alert(isPresented: $failed) {
            Alert(
                title: Text("Error! You did nothing wrong..."),
                message: Text(errorMessage),
                dismissButton: .default(Text("Not my fault!"))
            )
        }
    }
    
    func phoneNumberAuthExchange() {
        DispatchQueue.background(background: {
            loading = true
            do {
                let publisher = Publisher()
                let llt = try Vault.getLongLivedToken()
                print("Sending code for phone number: \(phoneNumber)")
                 
                let response = try publisher.phoneNumberBaseAuthenticationExchange(
                    authorizationCode: code,
                    llt: llt,
                    phoneNumber: phoneNumber,
                    platform: platformName
                )

                if response.success {
                    print("Successfully stored: \(platformName)")
                    try Vault().refreshStoredTokens(
                        llt: llt,
                        context: context
                    )
                    completed = true
                    dismiss()
                }
                else {
                     print("Failed to store platform: \(platformName)")
                }
            } catch {
                print("Failed to submit code: \(error)")
                failed = true
                errorMessage = error.localizedDescription
            }
        }, completion: {
//            submittingCode = false
            loading = false
        })
    }
}

struct PhoneNumberEntryView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedCountryCodeText: String? = "CM".getFlag() + " " + Country.init(isoCode: "CM").localizedName
    
    @State private var errorMessage: String = ""
    
    @State var platformName: String
    @State private var showCountryPicker = false
    @State private var submittingCode = false
    @State private var isLoading = false
    @State private var failed = false
    @State private var country: Country?
    
    @Binding var codeRequested: Bool
    @Binding var phoneNumber: String

    var body: some View {
        VStack {
            Group {
                HStack {
                    Button {
                        showCountryPicker.toggle()
                    } label: {
                        Text("+" + (country?.phoneCode ?? Country.init(isoCode: "CM").phoneCode))
                           .foregroundColor(Color.secondary)
                    }
                    .sheet(isPresented: $showCountryPicker) {
                        CountryPicker(
                            country: $country,
                            selectedCountryCodeText: $selectedCountryCodeText
                        )
                    }
                    Spacer()
                    TextField("\(platformName) phone number", text: $phoneNumber)
                        .padding()
                        .keyboardType(.numberPad)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .disabled(isLoading)
               }
               Rectangle().frame(height: 1).foregroundColor(.secondary)
            }
            .padding(.leading)
            .alert(isPresented: $failed) {
                Alert(
                    title: Text("Error! You did nothing wrong..."),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("Not my fault!"))
                )
            }

            if isLoading {
                ProgressView()
                    .padding()
            }
            else {
                Button("Get code") {
                    phoneNumberAuthRequest()
                }
                .padding()
                .buttonStyle(.borderedProminent)
                .disabled(phoneNumber.count < 3)
                .controlSize(.large)
            }
        }
        .padding(.bottom, 32)
    }
    
    func phoneNumberAuthRequest() {
        DispatchQueue.background(background: {
            isLoading = true
            do {
                let publisher = Publisher()
                let response = try publisher.phoneNumberBaseAuthenticationRequest(
                    phoneNumber: getPhoneNumber(),
                    platform: platformName
                )
                
                phoneNumber = getPhoneNumber()
                
                if response.success {
                    codeRequested = true
                }
            }
            catch {
                print("Some error occured: \(error)")
                failed = true
                errorMessage = error.localizedDescription
            }
        }, completion: {
            isLoading = false
        })
    }
    
    private func getPhoneNumber() -> String {
        return "+" + (country?.phoneCode ?? Country(isoCode: "CM").phoneCode) + phoneNumber
    }
}

struct PhoneNumberSheetView: View {
    @Binding var completed: Bool
    
    @State private var phoneNumber: String = ""
    @State private var codeRequested = false
    @State private var requestingCode = false

    var platformName: String

    var body: some View {
         VStack {
             if codeRequested {
                 PhoneNumberCodeEntryView(
                    platformName: platformName,
                    phoneNumber: $phoneNumber,
                    completed: $completed
                 )
             }
             else {
                 PhoneNumberEntryView(
                    platformName: platformName,
                    codeRequested: $codeRequested,
                    phoneNumber: $phoneNumber
                 )
             }
        }
    }
    
}

#Preview {
    @State var platformName = "telegram"
    @State var completed = false
    PhoneNumberSheetView(
        completed: $completed,
        platformName: platformName
    )
}

#Preview {
    @State var platformName = "telegram"
    @State var phoneNumber = ""
    @State var completed: Bool = false
    PhoneNumberCodeEntryView(
       platformName: platformName,
       phoneNumber: $phoneNumber,
       completed: $completed
    )
}

#Preview {
    @State var platformName = "telegram"
    @State var phoneNumber = "112345"
    @State var codeRequested = false
    PhoneNumberEntryView(
        platformName: platformName,
        codeRequested: $codeRequested,
        phoneNumber: $phoneNumber
    )
}
