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
            parent.selectedCountryCodeText = country.isoCode
        }
    }
}

nonisolated func signup(phonenumber: String) async throws -> Vault_V1_CreateEntityResponse {
    let vault = Vault()
    return try vault.createEntity(phoneNumber: phonenumber)
}



struct SignupSheetView: View {
    #if DEBUG
        @State private var phoneNumber: String = "+2371234567"
        @State private var password: String = "dummy_password"
        @State private var rePassword: String = "dummy_password"
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

    var body: some View {
        if(OTPRequired) {
            OTPSheetView(type: OTPSheetView.TYPE.CREATE,
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
                                    OTPRequired = try await signup(phonenumber: phoneNumber)
                                        .requiresOwnershipProof
                                } catch {
                                    print("Something went wrong \(error)")
                                    isLoading = false
                                }
                            }
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
