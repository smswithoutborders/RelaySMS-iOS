//
//  SignupSheetView.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 01/07/2024.
//

import SwiftUI
import CountryPicker
import CryptoKit

struct CountryPicker: UIViewControllerRepresentable {
    typealias UIViewControllerType = CountryPickerViewController

    let countryPicker = CountryPickerViewController()

    @Binding var country: Country?
    @Binding var selectedCountryCodeText: String?
    
    @State var showFlag = false

    func makeUIViewController(context: Context) -> CountryPickerViewController {
        countryPicker.selectedCountry = "CM"
        countryPicker.delegate = context.coordinator
        return countryPicker
    }

    func updateUIViewController(_ uiViewController: CountryPickerViewController, context: Context) {
        //
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    class Coordinator: NSObject, CountryPickerDelegate {
        var parent: CountryPicker
        init(_ parent: CountryPicker) {
            self.parent = parent
        }
        func countryPicker(didSelect country: Country) {
            parent.country = country
            parent.selectedCountryCodeText = country.isoCode.getFlag() + " " +
            (parent.showFlag ? country.localizedName : country.isoCode)
        }
    }
}

nonisolated func createAccount(phonenumber: String,
                        countryCode: String,
                        password: String,
                        type: OTPAuthType.TYPE) async throws -> Int {
    let vault = Vault()
    return try await signupOrAuthenticate(phoneNumber: phonenumber,
                         countryCode: countryCode,
                         password: password,
                         type: type)
}



struct SignupSheetView: View {
    #if DEBUG
        @State private var phoneNumber: String = "+2371234567"
        @State private var password: String = "LL<O3ZG~=z-epkv"
        @State private var rePassword: String = "LL<O3ZG~=z-epkv"
        @State private var selectedCountryCodeText: String? = "CM"
    #else
        @State private var phoneNumber: String = ""
        @State private var password: String = ""
        @State private var rePassword: String = ""
        @State private var selectedCountryCodeText: String? = "Select country"
    #endif

    @State private var country: Country?
    @State private var showCountryPicker = false
    
    @State private var isLoading = false
    
    @State private var OTPRequired = false
    
    @Binding var completed: Bool
    @Binding var failed: Bool
    
    @State var otpRetryTimer: Int = 0
    @State var errorMessage: String = ""

    var body: some View {
        if(OTPRequired) {
            OTPSheetView(type: OTPAuthType.TYPE.CREATE,
                         retryTimer: otpRetryTimer,
                         phoneNumber: $phoneNumber,
                         countryCode: $selectedCountryCodeText,
                         password: $password,
                         completed: $completed,
                         failed: $failed)
        }
        else {
            VStack {
                Form {
                    HStack {
                        Button {
                            showCountryPicker = true
                        } label: {
                            Text(selectedCountryCodeText!)
                        }.sheet(isPresented: $showCountryPicker) {
                            CountryPicker(country: $country,
                                          selectedCountryCodeText: $selectedCountryCodeText)
                        }
                        
                        Spacer()
                        TextField("Enter phone number", text: $phoneNumber)
                    }
                    SecureField("Password", text: $password)
                    SecureField("Re-Enter password", text: $rePassword)
                    
                    if(self.isLoading) {
                        ProgressView()
                    } else {
                        Button("Create account") {
                            self.isLoading = true
                            Task {
                                do {
                                    self.otpRetryTimer = try await createAccount(
                                        phonenumber: phoneNumber,
                                        countryCode: selectedCountryCodeText!,
                                        password: password,
                                        type: OTPAuthType.TYPE.CREATE)
                                    OTPRequired = true
                                } catch Vault.Exceptions.requestNotOK(let status){
                                    print("Something went wrong authenticating: \(status)")
                                    isLoading = false
                                    failed = true
                                    var (field, message) = Vault.parseErrorMessage(message: status.message)!
                                    errorMessage = message
                                }
                            }
                        }.alert(isPresented: $failed) {
                            Alert(title: Text("Error"), message: Text(errorMessage))
                        }
                        Button("Already got code") {
                            OTPRequired = true
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    @State var completed: Bool = false
    @State var failed: Bool = false
    SignupSheetView(completed: $completed, failed: $failed)
}
