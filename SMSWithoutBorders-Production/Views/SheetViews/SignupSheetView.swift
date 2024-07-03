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

func signup(phonenumber: String) throws -> Vault_V1_CreateEntityResponse {
    let vault = Vault()
    return try vault.createEntity(phoneNumber: phonenumber)
}



struct SignupSheetView: View {
    @State private var phoneNumber: String = ""
    @State private var password: String = ""
    @State private var rePassword: String = ""
    
    @State private var country: Country?
    @State private var showCountryPicker = false
    
    @State private var selectedCountryCodeText: String? = "Select country"
    
    @State private var isLoading = false
    
    @State private var OTPRequired = false
    
    @State var work: Task<Void, Never>?

    var body: some View {
        if(OTPRequired) {
            OTPSheetView(type: OTPSheetView.TYPE.CREATE,
                         phoneNumber: $phoneNumber,
                         countryCode: $selectedCountryCodeText,
                         password: $password)
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
                            work = Task {
                                do {
                                    OTPRequired = try signup(phonenumber: phoneNumber)
                                        .requiresOwnershipProof
                                } catch {
                                    print("Something went wrong \(error)")
                                }
                            }
                            self.isLoading = true
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

#Preview {
    SignupSheetView()
}
