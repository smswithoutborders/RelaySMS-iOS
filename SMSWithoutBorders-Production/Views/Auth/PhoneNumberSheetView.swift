//
//  PhoneNumberSheetView.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 03/08/2024.
//

import CountryPicker
import SwiftUI

struct PhoneNumberCodeEntryView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var context
    @FetchRequest(sortDescriptors: []) var storedPlatforms:
        FetchedResults<StoredPlatformsEntity>

    var platformName: String
    @Binding var phoneNumber: String
    @Binding var completed: Bool

    @State var loading = false
    @State var failed = false
    @State var havePassword = false

    @State var code: String = ""
    @State var password: String = ""
    @State var errorMessage: String = ""

    var body: some View {
        VStack {
            if platformName == "telegram" {
                Text(
                    "Please enter your Telegram code without copying it from the message - copying might get flagged and Telegram might block your account."
                )
                .padding()
                .font(RelayTypography.bodyMedium)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(RelayColors.colorScheme.secondary.opacity(0.2))
                ).foregroundStyle(RelayColors.colorScheme.secondary)
                .multilineTextAlignment(.leading)
            }
            Spacer().frame(height: 24)

            RelayTextField(label: "Code", text: $code)
                .keyboardType(.numberPad)
                .autocapitalization(.none)
                .padding(.bottom, 24)

            if havePassword {
                RelayPasswordField(label: "Enter password", text: $password)
            }

            Button {
                phoneNumberAuthExchange()
            } label: {
                if loading {
                    ProgressView()
                } else {
                    Text("Submit")
                }
            }
            .disabled(code.count < 3 || (havePassword && password.isEmpty))
            .buttonStyle(.relayButton(variant: .secondary))

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

        self.loading = true
        self.failed = false
        self.errorMessage = ""
        DispatchQueue.background(
            background: {
                do {
                    let publisher = Publisher()
                    let llt = try Vault.getLongLivedToken()
                    print("Sending code for phone number: \(phoneNumber)")

                    let response =
                        try publisher.phoneNumberBaseAuthenticationExchange(
                            authorizationCode: code,
                            llt: llt,
                            phoneNumber: phoneNumber,
                            platform: platformName,
                            password: password
                        )

                    DispatchQueue.main.async {
                        if response.success {
                            if response.twoStepVerificationEnabled {
                                havePassword = true
                            } else {
                                print("Successfully stored: \(platformName)")
                                do {
                                    try Vault().refreshStoredTokens(
                                        llt: llt,
                                        context: context,
                                        storedTokenEntities: storedPlatforms
                                    )
                                    self.completed = true
                                    self.dismiss()
                                } catch {
                                    print("Failed to refresh tokens: \(error)")
                                    self.failed = true
                                    self.errorMessage =
                                        "Failed to store platform: \(error.localizedDescription)"
                                }

                            }
                        } else {
                            print("Failed to store platform: \(platformName)")
                        }
                    }

                } catch {
                    DispatchQueue.main.async {
                        print("Failed to submit code: \(error)")
                        self.failed = true
                        self.errorMessage = error.localizedDescription
                    }
                }
            },
            completion: {
                //            submittingCode = false
                self.loading = false
            })
    }
}

struct PhoneNumberEntryView: View {
    @Environment(\.dismiss) var dismiss
    @State private var errorMessage: String = ""
    @State var platformName: String
    @State private var submittingCode = false
    @State private var isLoading = false
    @State private var failed = false

    @Binding var codeRequested: Bool
    @Binding var phoneNumber: String

    var body: some View {
        VStack {
            Spacer().frame(height: 32)
            RelayContactField(
                label: "\(platformName.localizedCapitalized) phone number",
                onPhoneNumberInputted: { contact in
                    phoneNumber = contact.internationalPhoneNumber
                }
            )
            .keyboardType(.numberPad)
            .disabled(isLoading)
            .padding(.horizontal, 16)

            Spacer().frame(height: 32)

            Button {
                phoneNumberAuthRequest()
            } label: {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Get Code")
                }
            }
            .disabled(phoneNumber.count < 3)
            .buttonStyle(.relayButton(variant: .secondary))
            .padding()

        }
        .alert(isPresented: $failed) {
            Alert(
                title: Text("Error! You did nothing wrong..."),
                message: Text(errorMessage),
                dismissButton: .default(Text("Not my fault!"))
            )
        }
        .padding(.bottom, 32)
    }

    func phoneNumberAuthRequest() {
        self.isLoading = true
        self.failed = false
        self.errorMessage = ""

        DispatchQueue.background(
            background: {
                isLoading = true
                do {
                    let publisher = Publisher()
                    let response =
                        try publisher.phoneNumberBaseAuthenticationRequest(
                            phoneNumber: phoneNumber,
                            platform: platformName
                        )

                    DispatchQueue.main.async {
                        self.phoneNumber = phoneNumber

                        if response.success {
                            codeRequested = true
                        } else {
                            self.failed = true
                            self.errorMessage = response.message
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        print("Some error occured: \(error)")
                        self.failed = true
                        self.errorMessage = error.localizedDescription
                    }
                }
            },
            completion: {
                self.isLoading = false
            })
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
            } else {
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
