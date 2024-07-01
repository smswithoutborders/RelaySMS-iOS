//
//  SignupSheetView.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 01/07/2024.
//

import SwiftUI
import CountryPicker

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



struct SignupSheetView: View {
    @State private var phoneNumber: String = ""
    @State private var password: String = ""
    @State private var rePassword: String = ""
    
    @State private var country: Country?
    @State private var showCountryPicker = false
    
    @State private var selectedCountryCodeText: String? = "Select country"

    var body: some View {
        Form {
            HStack {
                Button {
                    showCountryPicker = true
                } label: {
                    Text(selectedCountryCodeText!)
                }.sheet(isPresented: $showCountryPicker) { 
                    CountryPicker(country: $country,
                                  selectedCountryCodeText: $selectedCountryCodeText)
//                    selectedCountryCodeText = country?.localizedName()
                }
                
                Spacer()
                TextField("Enter phone number", text: $phoneNumber)
            }
            SecureField("Password", text: $password)
            SecureField("Re-Enter password", text: $rePassword)

            Button("Login") {
                
            }
        }
        
    }
}

#Preview {
    SignupSheetView()
}
