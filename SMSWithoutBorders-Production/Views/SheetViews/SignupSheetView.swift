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

nonisolated func createAccount(phonenumber: String,
                        countryCode: String,
                        password: String,
                        type: OTPAuthType.TYPE) async throws -> Int {
    let vault = Vault()
    return try await signupAuthenticateRecover(phoneNumber: phonenumber,
                         countryCode: countryCode,
                         password: password,
                         type: type)
}



struct SignupSheetView: View {
    #if DEBUG
        @State private var phoneNumber: String = "1234567"
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
    
    @State private var acceptTermsConditions: Bool = false
    @State private var passwordsNotMatch: Bool = false

    @State var otpRetryTimer: Int = 0
    @State var errorMessage: String = ""

    var body: some View {
        if(OTPRequired) {
            OTPSheetView(type: OTPAuthType.TYPE.CREATE,
                         retryTimer: otpRetryTimer,
                         phoneNumber: getPhoneNumber(),
                         countryCode: $selectedCountryCodeText,
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
                             let flag = country?.isoCode ?? Country.init(isoCode: "CM").isoCode
                             Text(flag.getFlag() + "+" + (country?.phoneCode ?? Country.init(isoCode: "CM").phoneCode))
                                .foregroundColor(Color.secondary)
                         }.sheet(isPresented: $showCountryPicker) {
                             CountryPicker(country: $country,
                                           selectedCountryCodeText: $selectedCountryCodeText)
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
                                    self.otpRetryTimer = try await createAccount(
                                        phonenumber: getPhoneNumber(),
                                        countryCode: country?.isoCode ?? "CM",
                                        password: password,
                                        type: OTPAuthType.TYPE.CREATE)
                                    OTPRequired = true
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
                        Button("Already got SMS code") {
                            OTPRequired = true
                        }
                    }
                }
                .padding()
                
                HStack {
                    Text("Already have an account?")
                        .foregroundStyle(.secondary)
                    Button {
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
    
    private func getPhoneNumber() -> String {
        return "+" + (country?.phoneCode ?? Country(isoCode: "CM").phoneCode) + phoneNumber
    }
}

struct SignupSheetView_Preview: PreviewProvider {
    static var previews: some View {
        @State var completed: Bool = false
        @State var failed: Bool = false
        SignupSheetView(completed: $completed, failed: $failed)
    }
}
