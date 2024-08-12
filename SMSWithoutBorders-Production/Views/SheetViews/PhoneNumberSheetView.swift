//
//  PhoneNumberSheetView.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 03/08/2024.
//

import SwiftUI
import CountryPicker

struct PhoneNumberSheetView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var viewContext
    
    @State private var phoneNumber: String = ""
    @State private var code: String = ""

    @State private var country: Country?
    @State private var showCountryPicker = false
    @State private var selectedCountryCodeText: String? = "CM".getFlag() + " " + Country.init(isoCode: "CM").localizedName
    @State private var showCode = false
    @State private var requestingCode = false
    @State private var submittingCode = false

    @State var platformName: String

    var body: some View {
         VStack {
             if showCode {
                 HStack {
                     TextField("Enter code", text: $code)
                         .keyboardType(.numberPad)
                         .autocapitalization(.none)
                         .disableAutocorrection(true)
                 }
                 .padding()
                 .textFieldStyle(.roundedBorder)

                 if submittingCode {
                     ProgressView()
                 }
                 else {
                     Button("Submit") {
                         submittingCode = true
                         phoneNumberAuthExchange()
                     }
                     .buttonStyle(.borderedProminent)
                     .padding()
                     .disabled(submittingCode)
                 }
             }
             else {
                 HStack {
                     Button {
                         showCountryPicker = true
                     } label: {
                         Text(selectedCountryCodeText!)
                             .padding()
                             .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(.blue, lineWidth: 1)
                             )
                     }.sheet(isPresented: $showCountryPicker) {
                         CountryPicker(country: $country,
                                       selectedCountryCodeText: $selectedCountryCodeText,
                                       showFlag: true)
                     }
                 }
                 .padding()
                 
                 Group {
                     HStack {
                         Text("+" + (country?.phoneCode ?? Country.init(isoCode: "CM").phoneCode))
                            .foregroundColor(Color.secondary)
                         Spacer()
                         TextField("Phone Number", text: $phoneNumber)
                             .padding()
                             .keyboardType(.numberPad)
                             .textContentType(.emailAddress)
                             .autocapitalization(.none)
                    }
                    Rectangle().frame(height: 1).foregroundColor(.secondary)
                 }
                 .padding(.leading)

                 if requestingCode {
                     ProgressView()
                 }
                 else {
                     Button("Get code") {
                         requestingCode = true
                         phoneNumberAuthRequest()
                     }
                     .padding(.bottom, 10)
                     .buttonStyle(.borderedProminent)
                     .disabled(phoneNumber.count < 3)
                     .controlSize(.large)
                 }
             }
        }
         .task {
             print("requesting phonenumber for: \(platformName)")
         }
    }
    
    func phoneNumberAuthExchange() {
        DispatchQueue.background(background: {
            do {
                let publisher = Publisher()
                let llt = try Vault.getLongLivedToken()
                 
                let response = try publisher.phoneNumberBaseAuthenticationExchange(
                    authorizationCode: code, llt: llt, phoneNumber: phoneNumber, platform: platformName)

                if response.success {
                    print("Successfully stored: \(platformName)")
                    try Vault().refreshStoredTokens(llt: llt, context: viewContext)
                    dismiss()
                }
                else {
                     print("Failed to store platform: \(platformName)")
                }
            } catch {
                print("Failed to submit code: \(error)")
            }
        }, completion: {
            submittingCode = false
        })
        
    }
    
    func phoneNumberAuthRequest() {
        DispatchQueue.background(background: {
            do {
                let phoneNum = "+" + (country?.phoneCode ?? Country(isoCode: "CM").phoneCode) + phoneNumber
                print("Requesting phone auth for: \(phoneNum)")
                
                let publisher = Publisher()
                let response = try publisher.phoneNumberBaseAuthenticationRequest(
                   phoneNumber: phoneNum, platform: platformName)
                
                phoneNumber = phoneNum
                
                if response.success {
                    showCode = true
                }
            }
            catch {
                print("Some error occured: \(error)")
            }
        }, completion: {
            requestingCode = false
        })
    }
}

#Preview {
    @State var platformName = "telegram"
    PhoneNumberSheetView(platformName: platformName)
}
