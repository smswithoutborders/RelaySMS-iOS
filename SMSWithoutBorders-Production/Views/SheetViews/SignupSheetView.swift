//
//  SignupSheetView.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 01/07/2024.
//

import SwiftUI
import CountryPicker
import CryptoKit

struct CheckBoxView: View {
    @Binding var checked: Bool

    var body: some View {
        Image(systemName: checked ? "checkmark.square.fill" : "square")
            .foregroundColor(checked ? Color(UIColor.systemBlue) : Color.secondary)
            .onTapGesture {
                self.checked.toggle()
            }
    }
}

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

struct SignupSheetView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var country: Country? = Country(isoCode: "CM")
    #if DEBUG
        @State private var phoneNumber = "1123457528"
        @State private var password: String = "dMd2Kmo9#"
        @State private var rePassword: String = "dMd2Kmo9#"
        @State private var selectedCountryCodeText: String? = "CM"
    #else
        @State private var phoneNumber: String {
            return "+" + (country?.phoneCode ?? Country(isoCode: "CM").phoneCode) + phoneNumber
        }
        @State private var password: String = ""
        @State private var rePassword: String = ""
        @State private var selectedCountryCodeText: String? = "Select country"
    #endif

    
    @State private var countryCode: String = Country(isoCode: "CM").isoCode
    @State private var showCountryPicker = false
    @State private var isLoading = false
    @State private var otpRequired = false
    @State private var failed: Bool = false
    @State private var acceptTermsConditions: Bool = false
    @State private var passwordsNotMatch: Bool = false
    @State var completedSuccessfully: Bool = false
    @State var otpRetryTimer: Int = 0
    @State var errorMessage: String = ""
    @State var callbackText: String = "Account created successfully!"

    @Binding var loginRequested: Bool
    @Binding var accountCreated: Bool

    var body: some View {
        VStack {
            NavigationLink(
                destination:
                    OTPSheetView(
                        countryCode: $countryCode,
                        phoneNumber: $phoneNumber,
                        password: $password,
                        failed: $failed,
                        completedSuccessfully: $completedSuccessfully
                    ),
                isActive: $otpRequired
            ) {
                EmptyView()
            }
            
            if(completedSuccessfully) {
                SuccessAnimations( callbackText: $callbackText ) {
                    accountCreated = true
                    dismiss()
                }
            } else {
                VStack {
                    VStack {
                        Image("Logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 75, height: 75)
                            .padding()

                        Text("Create account")
                            .font(.title)
                            .bold()
                            .padding()
                        
                        Group {
                            Text("If you don't have an account")
                            Text("Please create one to save your platforms")
                        }
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                    }
                    .padding(.bottom, 30)
                    
                    VStack {
                        HStack {
                             Button {
                                 showCountryPicker = true
                             } label: {
                                 let flag = countryCode
                                 Text(flag.getFlag() + "+" + country!.phoneCode)
                                    .foregroundColor(Color.secondary)
                             }.sheet(isPresented: $showCountryPicker) {
                                 CountryPicker(country: $country, selectedCountryCodeText: $selectedCountryCodeText)
                             }
                             Spacer()
                             TextField("Phone Number", text: $phoneNumber)
                                 .keyboardType(.numberPad)
                                 .textContentType(.emailAddress)
                                 .autocapitalization(.none)
                        }
                        .padding(.leading)
                        Rectangle().frame(height: 1).foregroundColor(.secondary)
                            .padding(.bottom, 20)
                        
                        SecureField("Password", text: $password)
                        Rectangle().frame(height: 1).foregroundColor(.secondary)
                            .padding(.bottom, 20)
                        
                        SecureField("Re-enter password", text: $rePassword)
                        Group {
                            Rectangle().frame(height: 1).foregroundColor(.secondary)
                            if passwordsNotMatch {
                                Text("Passwords don't match")
                                    .foregroundStyle(.red)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(.bottom, 20)

                        HStack {
                            CheckBoxView(checked: $acceptTermsConditions)
                            Text("I accept the")
                            Link("terms and conditions", destination: URL(string:"https://smswithoutborders.com/privacy-policy")!)
                        }
                        .frame(maxWidth: .infinity, alignment: .init(horizontal: .leading, vertical: .center))

                    }
                    .padding()
                    Spacer()
                    
                    VStack {
                        if(self.isLoading) {
                            ProgressView()
                        } else {
                            Button {
                                if password != rePassword {
                                    passwordsNotMatch = true
                                    return
                                }
                                self.isLoading = true
                                Task {
                                    do {
                                        self.otpRetryTimer = try await signupAuthenticateRecover(
                                            phoneNumber: getPhoneNumber(),
                                            countryCode: countryCode,
                                            password: password,
                                            type: OTPAuthType.TYPE.CREATE
                                        )

                                        self.otpRequired = true
                                        self.phoneNumber = getPhoneNumber()
                                    } catch Vault.Exceptions.requestNotOK(let status){
                                        print("Something went wrong authenticating: \(status)")
                                        isLoading = false
                                        failed = true
                                        errorMessage = status.message!
                                        phoneNumber = ""
                                    } catch {
                                        isLoading = false
                                        failed = true
                                        errorMessage = error.localizedDescription
                                        phoneNumber = ""
                                    }
                                }
                            } label: {
                                Text("Create account")
                                    .bold()
                                    .frame(maxWidth: .infinity, maxHeight: 35)
                            }
                            .disabled(!acceptTermsConditions)
                            .buttonStyle(.borderedProminent)
                            .alert(isPresented: $failed) {
                                Alert(title: Text("Error"), message: Text(errorMessage))
                            }
                            .padding(.bottom, 20)
                            
                            Button {
                                phoneNumber = getPhoneNumber()
                                self.otpRequired = true
                            } label: {
                                Text("Already got code")
                                    .padding(.top, 10)
                                    .font(.subheadline)
                            }
                            .disabled(phoneNumber.isEmpty)
                        }
                    }
                    .padding()
                    
                    HStack {
                        Text("Already have an account?")
                        Button {
                            loginRequested = true
                        } label: {
                            Text("Log in")
                                .bold()
                        }
                    }
                    .font(.subheadline)
                    .padding()
                }
                
            }

        }
    }
    
    private func getPhoneNumber() -> String {
        return "+" + (country?.phoneCode ?? Country(isoCode: "CM").phoneCode) + phoneNumber
    }
}

struct SignupSheetView_Preview: PreviewProvider {
    static var previews: some View {
        @State var completed: Bool = false
        @State var failed: Bool = false
        @State var loginRequested: Bool = false
        SignupSheetView(
            loginRequested: $loginRequested,
            accountCreated: $completed
        )
    }
}
