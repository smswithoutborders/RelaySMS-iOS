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
    @State var phoneNumber: String = ""
    
    @State private var country: Country?
    @State private var showCountryPicker = false
    @State private var selectedCountryCodeText: String? = "CM".getFlag() + " " + Country.init(isoCode: "CM").localizedName
    @State private var showCode = false

    var body: some View {
         VStack {
             if showCode {
                 HStack {
                     TextField("Enter code", text: $phoneNumber)
                         .keyboardType(.numberPad)
                         .autocapitalization(.none)
                         .disableAutocorrection(true)
                 }
                 .padding()
                 .textFieldStyle(.roundedBorder)

                 Button("Submit") {
                     dismiss()
                 }
                 .buttonStyle(.borderedProminent)
                 .padding()
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
                 
                 HStack {
                     Text("+" + (country?.phoneCode ?? Country.init(isoCode: "CM").phoneCode))
                     TextField("Phone Number", text: $phoneNumber)
                         .keyboardType(.numberPad)
                         .autocapitalization(.none)
                         .disableAutocorrection(true)
                 }
                 .padding()
                 .textFieldStyle(.roundedBorder)

                 Button("Get code") {
                     showCode = true
                 }
                 .buttonStyle(.borderedProminent)
                 .padding()
             }
        }
    }
}

#Preview {
    PhoneNumberSheetView()
}
