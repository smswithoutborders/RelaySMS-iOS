//
//  TextView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 11/4/22.
//

import MessageUI
import SwiftUI

struct TextComposeView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var context
    @Environment(\.presentationMode) var presentationMode

    @FetchRequest(sortDescriptors: []) private var platforms:
        FetchedResults<PlatformsEntity>
    @FetchRequest(sortDescriptors: []) private var storedPlatforms:
        FetchedResults<StoredPlatformsEntity>

    #if DEBUG
        private var defaultGatewayClientMsisdn: String =
            ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"]
                == "1"
            ? ""
            : UserDefaults.standard.object(
                forKey: GatewayClients.DEFAULT_GATEWAY_CLIENT_MSISDN) as? String
                ?? ""
    #else
        @AppStorage(GatewayClients.DEFAULT_GATEWAY_CLIENT_MSISDN)
        private var defaultGatewayClientMsisdn: String = ""
    #endif

    @AppStorage(SettingsKeys.SETTINGS_STORE_PLATFORMS_ON_DEVICE)
    private var isPlatformsStoredOnDevice: Bool = false

    @State var textBody: String = ""
    @State var placeHolder: String = "What's happening?"
    @State private var fromAccount: String = ""

    @State private var encryptedFormattedContent = ""
    @State private var isPosting: Bool = false
    @State private var isShowingMessages: Bool = false

    @State private var dismissRequested: Bool = false
    @State private var requestToChooseAccount: Bool = false

    @State var platform: PlatformsEntity?

    @Binding var message: Messages?
    @Binding var platformName: String

    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var isLoading = false

    init(platformName: Binding<String>, message: Binding<Messages?>) {
        _platformName = platformName
        _message = message
        let platformNameWrapped = platformName.wrappedValue

        print("Searching platform: \(platformNameWrapped)")
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    HStack {
                        Text("From account: ")
                            .font(RelayTypography.bodyMedium)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)

                        Text("\(fromAccount)")
                            .font(RelayTypography.bodyMedium)
                            .foregroundStyle(RelayColors.colorScheme.primary)
                            .multilineTextAlignment(.leading)
                            .padding()
                    }.padding()

                    #if DEBUG
                        Button("Present missing token error alert") {
                            showAlert = true
                            alertTitle = "Missing Tokens"
                            alertMessage =
                                "Your tokens have not been found on this device. Please revoke access to your account and log back in to continue."
                        }
                    #endif

                    Spacer().frame(height: 16)
                    RelayTextEditor(label: "Post", text: $textBody)

                    //                ZStack {
                    //                    if self.textBody.isEmpty {
                    //                        TextEditor(text: $placeHolder)
                    //                            .font(.body)
                    //                            .foregroundColor(.secondary)
                    //                            .disabled(true)
                    //                    }
                    //                    RelayTextEditor(label: "Post", text: $textBody)
                    ////                    TextEditor(text: $textBody)
                    ////                        .font(.body)
                    ////                        .opacity(self.textBody.isEmpty ? 0.25 : 1)
                    ////                        .textFieldStyle(PlainTextFieldStyle())
                    //                }

                    Spacer(minLength: 24)
                    Button("Post") {
                        let platform = platforms.first { $0.name == platformName }
                        if let platformShortCode = platform?.shortcode {
                            print(
                                "Platform shortcode is available: \(platformShortCode)"
                            )
                            isPosting = true
                            DispatchQueue.background(background: {
                                do {
                                    let messageComposer = try Publisher.publish(
                                        context: context)
                                    var shortcode: UInt8? = nil
                                    shortcode = platformShortCode.bytes[0]

                                    // Get the stored platform and use the tokens if the platform tokens exist
                                    let storedPlatformEntity = storedPlatforms.first
                                    {
                                        $0.account == fromAccount
                                    }  // Gets the speciic account that matches the currently selected `fromAccount`

                                    encryptedFormattedContent =
                                        try messageComposer.textComposerV1(
                                            platform_letter: shortcode!,
                                            sender: fromAccount,
                                            text: textBody,
                                            accessToken: storedPlatformEntity?
                                                .access_token ?? nil,
                                            refreshToken: storedPlatformEntity?
                                                .refresh_token ?? nil
                                        )

                                    print(
                                        "Transmitting to sms app: \(encryptedFormattedContent)"
                                    )

                                    isPosting = false
                                    isShowingMessages.toggle()
                                } catch {
                                    print(
                                        "Some error occured while sending: \(error)"
                                    )
                                }
                            })
                        }

                    }
                    .buttonStyle(.relayButton(variant: .secondary))
                    .disabled(isPosting || fromAccount.isEmpty)
                    .sheet(isPresented: $isShowingMessages) {
                        SMSComposeMessageUIView(
                            recipients: [defaultGatewayClientMsisdn],
                            body: $encryptedFormattedContent,
                            completion: handleCompletion(_:)
                        )
                        .ignoresSafeArea()
                    }
                    Spacer().frame(height: 48)
                }
                .padding()
            }
            .sheet(isPresented: $requestToChooseAccount) {
                SelectAccountSheetView(
                    filter: platformName,
                    fromAccount: $fromAccount,
                    dismissParent: $dismissRequested,
                    isSendingMessage: true
                ) {
                    requestToChooseAccount.toggle()

                    if self.message != nil {
                        textBody = self.message!.data
                    }
                }
                .applyPresentationDetentsIfAvailable()
                .interactiveDismissDisabled(true)
            }
            .navigationBarTitle("Compose Post")
        }
        .onChange(of: dismissRequested) { state in
            if state {
                dismiss()
            }
        }
        .task {
            if storedPlatforms.count > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    requestToChooseAccount = true
                }
            }
        }
    }

    func handleCompletion(_ result: MessageComposeResult) {
        switch result {
        case .cancelled:
            break
        case .failed:
            break
        case .sent:
            DispatchQueue.background(background: {
                var messageEntities = MessageEntity(context: context)
                messageEntities.id = UUID()
                messageEntities.platformName = platformName
                messageEntities.fromAccount = fromAccount
                messageEntities.toAccount = ""
                messageEntities.subject = fromAccount
                messageEntities.body = textBody
                messageEntities.date = Int32(Date().timeIntervalSince1970)

                DispatchQueue.main.async {
                    do {
                        try context.save()
                        dismiss()
                    } catch {
                        print("Failed to save message entity: \(error)")
                    }
                }
            })
            break
        @unknown default:
            break
        }
    }
}

//struct TextView_Preview: PreviewProvider {
//    static var previews: some View {
//        let container = createInMemoryPersistentContainer()
//        populateMockData(container: container)
//
//        @State var message: Messages? = Messages(
//            id: UUID(),
//            subject: "Hello world",
//            data:"The scroll view displays its content within the scrollable content region. As the user performs platform-appropriate scroll gestures, the scroll view adjusts what portion of the underlying content is visible. ScrollView can scroll horizontally, vertically, or both, but does not provide zooming functionality.",
//            fromAccount: "@afkanerd",
//            toAccount: "toAccount@gmail.com",
//            platformName: "twitter",
//            date: Int(Date().timeIntervalSince1970))
//
//        @State var globalDismiss = false
//        @State var platformName = "twitter"
//        return TextComposeView(platformName: $platformName, message: $message)
//            .environment(\.managedObjectContext, container.viewContext)
//    }
//}
