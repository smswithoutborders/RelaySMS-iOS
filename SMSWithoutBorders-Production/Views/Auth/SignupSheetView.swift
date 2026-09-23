//
//  SignupSheetView.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 01/07/2024.
//

import CountryPicker
import CryptoKit
import SwiftUI

struct CheckBoxView: View {
    @Binding var checked: Bool

    var body: some View {
        Image(systemName: checked ? "checkmark.square.fill" : "square")
            .foregroundColor(
                checked ? Color(UIColor.systemBlue) : Color.secondary
            )
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

    func updateUIViewController(
        _ uiViewController: CountryPickerViewController, context: Context
    ) {
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
            parent.selectedCountryCodeText =
                country.isoCode.getFlag() + " "
                + (parent.showFlag ? country.localizedName : country.isoCode)
        }
    }
}

struct SignupSheetView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var context

    @State var country: Country? = Country(isoCode: "CM")
    #if DEBUG
        @State var phoneNumber = "1123457528"
        @State var password: String = "dMd2Kmo9#"
        @State var rePassword: String = "dMd2Kmo9#"
        @State var selectedCountryCodeText: String? = "CM"
    #else
        @State var phoneNumber: String = ""
        @State var password: String = ""
        @State var rePassword: String = ""
        @State var selectedCountryCodeText: String? = "Select country"
    #endif

    @State var countryCode: String = Country(isoCode: "CM").isoCode
    @State var isLoading = false
    @State var otpRequired = false
    @State var failed: Bool = false
    @State var acceptTermsConditions: Bool = false
    @State var passwordsNotMatch: Bool = false
    @State var completedSuccessfully: Bool = false
    @State var otpRetryTimer: Int = 0
    @State var errorMessage: String = ""
    @State var callbackText: String = "Account created successfully!"
    @State var type = OTPAuthType.TYPE.CREATE

    @Binding var loginRequested: Bool
    @Binding var accountCreated: Bool

    var body: some View {
        ScrollView {
            VStack {
                NavigationLink(
                    destination:
                        OTPSheetView(
                            countryCode: $countryCode,
                            phoneNumber: $phoneNumber,
                            password: $password,
                            failed: $failed,
                            completedSuccessfully: $completedSuccessfully,
                            type: $type
                        ),
                    isActive: $otpRequired
                ) {
                    EmptyView()
                }

                if completedSuccessfully {
                    SuccessAnimations(callbackText: $callbackText) {
                        do {
                            let vault = Vault()
                            let llt = try Vault.getLongLivedToken()
                            try vault.refreshStoredTokens(
                                llt: llt,
                                context: context,
                                storedTokenEntities: nil
                            )
                        } catch {
                            print("Error refreshing tokens: \(error)")
                            failed = true
                            errorMessage = error.localizedDescription
                        }
                    } callback: {
                        accountCreated = true
                        dismiss()
                    }
                } else {
                    VStack(spacing: 16) {
                        VStack {
                            Image("Logo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 75, height: 75)
                                .padding()

                            Text("Create account")
                                .font(RelayTypography.titleLarge)
                                .padding(.bottom, 16)

                            Group {
                                Text("If you don't have an account")
                                Text("Please create one to save your platforms")
                            }
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                        }
                        .padding(.bottom, 24)

                        RelayContactField(
                            label: "Phone Number",
                            initialValue: phoneNumber,
                            onPhoneNumberInputted: { relayContact in
                                print("Phone number received from contact field callback: \(relayContact.rawValue)")
                                self.phoneNumber = relayContact.internationalPhoneNumber
                            }
                        ).padding(.bottom, 8)

                        RelayPasswordField(label: "Password", text: $password)
                            .padding(.bottom, 8)

                        RelayPasswordField(
                            label: "Re-enter password", text: $rePassword)
                        if passwordsNotMatch {
                            Text("Passwords don't match")
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        HStack {
                            CheckBoxView(checked: $acceptTermsConditions)
                            Text("I accept the")
                            Link(
                                "terms and conditions",
                                destination: URL(
                                    string:
                                        "https://smswithoutborders.com/privacy-policy"
                                )!)
                        }
                        .frame(
                            maxWidth: .infinity,
                            alignment: .init(
                                horizontal: .leading, vertical: .center)
                        )
                        Spacer()

                        Button {
                            if password != rePassword {
                                passwordsNotMatch = true
                                return
                            }
                            self.isLoading = true
                            Task {
                                do {
                                    self.otpRetryTimer =
                                        try await signupAuthenticateRecover(
                                            phoneNumber: phoneNumber,
                                            countryCode: countryCode,
                                            password: password,
                                            type: OTPAuthType.TYPE.CREATE,
                                            context: context
                                        )

                                    self.otpRequired = true
                                } catch Vault.Exceptions.requestNotOK(
                                    let status)
                                {
                                    print(
                                        "Something went wrong authenticating: \(status)"
                                    )
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
                            if self.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Create account")
                            }
                        }
                        .disabled(!acceptTermsConditions)
                        .buttonStyle(.relayButton(variant: .primary))
                        .alert("Error", isPresented: $failed) {
                            Button(role: .destructive) {
                                failed = false
                            } label: {
                                Text("Okay!")
                            }
                        } message: {
                            Text(errorMessage)
                        }

                        Button {
                            // phoneNumber = getPhoneNumber()
                            self.otpRequired = true
                        } label: {
                            Text("Already got code")
                                .font(.subheadline)
                        }
                        .disabled(phoneNumber.isEmpty)

                        HStack {
                            Text("Already have an account?")
                            Button {
                                loginRequested = true
                            } label: {
                                Text("Log in").bold()
                            }
                        }
                        .font(.subheadline)
                        .padding(.bottom, 24)
                    }
                    .padding([.leading, .trailing], 16)

                }

            }
            .onChange(of: failed) { v in
                if v {
                    isLoading = false
                    otpRequired = false
                }
            }

        }
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
