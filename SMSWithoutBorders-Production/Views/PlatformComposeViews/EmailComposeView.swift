//
//  ContentView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/5/22.
//

import CoreData
import CryptoKit
import MessageUI
import SwiftUI
import PhotosUI
import lib_image_ios
import Combine

struct EmailAttachmentView: View {
    @Binding var image: Image?
    
    var body: some View {
        if(image != nil) {
            VStack {
                image!
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 150)
                    .clipped()
                HStack {
                    Spacer()
                    VStack(alignment: .trailing) {
                        Button("x") {
                            image = nil
                        }
                    }
                }
                .frame(width: 200)
                .padding(.trailing, 12,)
                .padding(.bottom, 4)
                .padding(.top, 4)
                .background(.secondary)
            }
            .padding(20)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            .padding(.horizontal)
        }
    }
}

struct EmailComposeForm: View {
    @Binding var composeTo: String
    @Binding var composeFrom: String
    @Binding var composeCC: String
    @Binding var composeBCC: String
    @Binding var composeSubject: String
    @Binding var composeBody: String
    @Binding var fromAccount: String

    var isBridge: Bool

    var body: some View {
        VStack {
            VStack {
                if !isBridge {
                    HStack {
                        Text("From")
                        TextField("From", text: $fromAccount)
                    }
                    .autocapitalization(.none)
                    .textContentType(.emailAddress)
                    .disabled(true)
                }
                
                HStack {
                    Text("To: ")
                    TextField("", text: $composeTo)
                    .autocapitalization(.none)
                    .textContentType(.emailAddress)
                }
                .frame(height: 30)
                .padding(.leading, 8)
                .clipShape(RoundedRectangle(cornerRadius: 15)) // Clips the editor's background to a rounded shape
                .overlay( // Adds the actual border overlay
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray, lineWidth: 1)
                )

                HStack {
                    Text("CC:")
                    TextField("", text: $composeCC)
                    .autocapitalization(.none)
                    .textContentType(.emailAddress)

                }
                .frame(height: 30)
                .padding(.leading, 8)
                .clipShape(RoundedRectangle(cornerRadius: 15)) // Clips the editor's background to a rounded shape
                .overlay( // Adds the actual border overlay
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray, lineWidth: 1)
                )

                HStack {
                    Text("BCC:")
                    TextField("", text: $composeBCC)
                    .autocapitalization(.none)
                    .textContentType(.emailAddress)
                }
                .frame(height: 30)
                .padding(.leading, 8)
                .clipShape(RoundedRectangle(cornerRadius: 15)) // Clips the editor's background to a rounded shape
                .overlay( // Adds the actual border overlay
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray, lineWidth: 1)
                )

                HStack {
                    Text("Subject:")
                    TextField("", text: $composeSubject)
                    .autocapitalization(.sentences)
                }
                .frame(height: 30)
                .padding(.leading, 8)
                .clipShape(RoundedRectangle(cornerRadius: 15)) // Clips the editor's background to a rounded shape
                .overlay( // Adds the actual border overlay
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray, lineWidth: 1)
                )
            }

            Spacer(minLength: 32)
            VStack {
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $composeBody)
                        .frame(height: 200)
                        .padding()
                        .clipShape(RoundedRectangle(cornerRadius: 15)) // Clips the editor's background to a rounded shape
                        .overlay( // Adds the actual border overlay
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                        .autocapitalization(.sentences)
                    
                    if composeBody.isEmpty {
                        Text("Content")
                        .foregroundColor(Color(.systemGray3))
                        .padding(.top, 16) // Adjust padding to align with TextEditor's text
                        .padding(.leading, 12)
                        .allowsHitTesting(false) // Allows taps to pass through to the TextEditor
                    }
                }
            }
        }
    }
}

struct EmailComposeView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var context
    @FetchRequest var storedPlatforms: FetchedResults<StoredPlatformsEntity>
    @FetchRequest var platforms: FetchedResults<PlatformsEntity>

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

    @AppStorage(SettingsKeys.SETTINGS_MESSAGE_WITH_PHONENUMBER)
    private var messageWithPhoneNumber = false

    @State private var encryptedFormattedContent: String = ""
    @State var isShowingMessages: Bool = false
    @State var isSendingRequest: Bool = false
    @State var requestToChooseAccount: Bool = false
    @State var composeFrom: String = ""
    @State var fromAccount: String = ""

    @State var dismissRequested = false

    private var isBridge: Bool = false

    @Binding var message: Messages?
    @Binding var platformName: String

    @State var composeTo: String = ""
    @State var composeCC: String = ""
    @State var composeBCC: String = ""
    @State var composeSubject: String = ""
    @State var composeBody: String = ""

    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var isLoading = false
    
    @State private var showImagePicker = false
    @State private var showEditImage = false
    @State private var imageSelected = false
    
    @State var imageViewModel = ImageCustomizationViewModel()

    @State private var selectedPhoto : PhotosPickerItem?
    @State private var attachmentImage: Image?

    init(
        platformName: Binding<String>,
        isBridge: Bool = false,
        message: Binding<Messages?>
    ) {
        print("Requested platform name: \(platformName.wrappedValue )")
        _storedPlatforms = FetchRequest<StoredPlatformsEntity>(
            sortDescriptors: [],
            predicate: NSPredicate(
                format: "name == %@", platformName.wrappedValue))
        _message = message

        _platforms = FetchRequest<PlatformsEntity>(
            sortDescriptors: [],
            predicate: NSPredicate(
                format: "name == %@", platformName.wrappedValue))

        _platformName = platformName
        self.isBridge = isBridge
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    EmailComposeForm(
                        composeTo: $composeTo,
                        composeFrom: $composeFrom,
                        composeCC: $composeCC,
                        composeBCC: $composeBCC,
                        composeSubject: $composeSubject,
                        composeBody: $composeBody,
                        fromAccount: $fromAccount,
                        isBridge: isBridge
                    )
                    
                    Spacer()
                    Button(action: {
                        showEditImage.toggle()
                    }) {
                        EmailAttachmentView(image: $attachmentImage)
                        Spacer()
                    }

                }
                .sheet(isPresented: $isShowingMessages) {
                    SMSComposeMessageUIView(
                        recipients: [defaultGatewayClientMsisdn],
                        body: $encryptedFormattedContent,
                        completion: handleCompletion(_:)
                    )
                    .ignoresSafeArea()
                }
                .sheet(isPresented: $showEditImage) {
                    VStack {
                        if(selectedPhoto == nil) {
                            Button("Select image") {
                                showImagePicker.toggle()
                            }
                            .buttonStyle(BorderedButtonStyle())
                            
                            Text("You will be prompted to edit the image after this. You can modify the images to the size you seem most comfortable with sending.")
                                .padding()
                        } else {
                            ImageProcessingView(viewModel: $imageViewModel){ image in
                                Task {
                                    attachmentImage = Image(uiImage: imageViewModel.displayImage)
                                    do {
                                        let dp = divideImagePayload(
                                            payload: [UInt8](Data(image).base64EncodedData()),
                                            version: 1,
                                            sessionId: 2,
                                            imageLength: UInt16(image.count),
                                            textLength: 0
                                        )
                                        showEditImage.toggle()
                                        if(dp != nil) {
                                            // TODO()
                                        }
                                    } catch {
                                        print(error)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .photosPicker(isPresented: $showImagePicker, selection: $selectedPhoto, matching: .images)
                }
                .padding()
                .toolbar(content: {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if #available(iOS 17.0, *) {
                            if(isBridge || message?.platformName == "BRIDGE") {
                                Button {
                                    selectedPhoto = nil
                                    attachmentImage = nil
                                    imageSelected = false
                                    showEditImage.toggle()
                                } label: {
                                    Image(systemName: "paperclip.circle")
                                }
                            }
                        }
                    }
                    ToolbarItem {
                        Button {
                            isSendingRequest = true
                            DispatchQueue.background(background: {
                                do {
                                    encryptedFormattedContent =
                                        try getEncryptedContent(
                                            isBridge: self.isBridge)
                                } catch {
                                    print(
                                        "Some error occured while sending: \(error)"
                                    )
                                }
                                isShowingMessages.toggle()
                                isSendingRequest = false
                            })
                        } label: {
                            if isSendingRequest {
                                ProgressView()
                            } else {
                                Image(systemName: "paperplane.circle")
                            }
                        }
                        .disabled(!isBridge && fromAccount.isEmpty)
                    }
                })
                .onReceive(Just(selectedPhoto)) { _ in
                    if(selectedPhoto != nil && !imageSelected) {
                        Task {
                            if let loaded = try? await selectedPhoto?.loadTransferable(type: Image.self) {
                                let renderer = ImageRenderer(content: loaded)
                                imageViewModel = ImageCustomizationViewModel()
                                imageViewModel.setImage(renderer.uiImage!)
                                imageSelected = true
                                print("[+] Image selected...")
                            } else {
                                print("Failed")
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $requestToChooseAccount) {
                SelectAccountSheetView(
                    filter: platformName,
                    fromAccount: $fromAccount,
                    dismissParent: $dismissRequested,
                    callback:  {
                        requestToChooseAccount.toggle()
                        if self.message != nil {
                            composeTo = self.message!.toAccount
                            composeCC = self.message!.cc
                            composeBCC = self.message!.bcc
                            composeSubject = self.message!.subject
                            composeBody = self.message!.data
                        }
                    },
                    isSendingMessage: true
                )
                .applyPresentationDetentsIfAvailable()
                .interactiveDismissDisabled(true)
            }
        }
        .onChange(of: dismissRequested) { state in
            if state {
                dismiss()
            }
        }
        .task {
            if storedPlatforms.count > 0 && !isBridge {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    requestToChooseAccount = true
                }
            }
            if isBridge {
                requestToChooseAccount = false
                if self.message != nil {
                    composeTo = self.message!.toAccount
                    composeCC = self.message!.cc
                    composeBCC = self.message!.bcc
                    composeSubject = self.message!.subject
                    composeBody = self.message!.data
                }
            }
        }
        .navigationTitle("Compose email")
    }

    func getEncryptedContent(isBridge: Bool = false) throws -> String {
        if !isBridge {
            let messageComposer = try Publisher.publish(context: context)
            let shortcode: UInt8 = "g".data(using: .utf8)!.first!

            // Get the stored platform and use the tokens if the platform tokens exist
            let storedPlatformEntity = storedPlatforms.first {
                $0.account == fromAccount
            }  // Gets the speciic account that matches the currently selected fromAccount

            return try messageComposer.emailComposerV1(
                platform_letter: shortcode,
                from: fromAccount,
                to: composeTo,
                cc: composeCC,
                bcc: composeBCC,
                subject: composeSubject,
                body: composeBody,
                accessToken: storedPlatformEntity?.access_token ?? nil,
                refreshToken: storedPlatformEntity?.refresh_token ?? nil
            )
        } else {
            let (cipherText, clientPublicKey) = try Bridges.compose(
                to: composeTo,
                cc: composeCC,
                bcc: composeBCC,
                subject: composeSubject,
                body: composeBody,
                context: context
            )
            if try !Vault.getLongLivedToken().isEmpty {
                return try Bridges.payloadOnly(
                    context: context, cipherText: cipherText)!
            } else {
                return try Bridges.authRequestAndPayload(
                    context: context,
                    cipherText: cipherText,
                    clientPublicKey: clientPublicKey!
                )!
            }
        }
    }

    func handleCompletion(_ result: MessageComposeResult) {
        switch result {
        case .cancelled:
            print("Yep cancelled")
            #if DEBUG
                saveMessageEntity()
            #endif
            break
        case .failed:
            print("Yep failed")
            #if DEBUG
                saveMessageEntity()
            #endif
            break
        case .sent:
            saveMessageEntity()
            dismiss()
            break
        @unknown default:
            print("Not even sure what this means")
            break
        }
    }

    private func saveMessageEntity() {
        DispatchQueue.background(background: {
            let messageEntities = MessageEntity(context: context)
            messageEntities.id = UUID()
            messageEntities.platformName = platformName
            messageEntities.fromAccount = fromAccount
            messageEntities.toAccount = composeTo
            messageEntities.cc = composeCC
            messageEntities.bcc = composeBCC
            messageEntities.subject = composeSubject
            messageEntities.body = composeBody
            messageEntities.date = Int32(Date().timeIntervalSince1970)

            if isBridge {
                messageEntities.type = Bridges.SERVICE_NAME
            }

            DispatchQueue.main.async {
                do {
                    try context.save()
                    dismiss()
                } catch {
                    print("Failed to save message entity: \(error)")
                }
            }
        })
    }

    func formatEmailForViewing(decryptedData: String) -> (
        platformLetter: String, to: String, cc: String, bcc: String,
        subject: String, body: String
    ) {
        let splitString = decryptedData.components(separatedBy: ":")

        let platformLetter: String = splitString[0]
        let to: String = splitString[1]
        let cc: String = splitString[2]
        let bcc: String = splitString[3]
        let subject: String = splitString[4]
        let body: String = splitString[5]

        return (platformLetter, to, cc, bcc, subject, body)
    }

}

struct EmailView_Preview: PreviewProvider {
    static var previews: some View {
        @State var message: Messages? = Messages(
            id: UUID(),
            subject: "Test subject",
            data: "Test body",
            fromAccount: "from@test.com",
            toAccount: "to@test.com",
            platformName: "BRIDGE",
            date: 0
        )

        @State var platformName = ""
        return EmailComposeView(
            platformName: $platformName, message: $message
        )
    }
}

//struct EmailCompose_Preview: PreviewProvider {
//    static var previews: some View {
//        @State var composeTo: String = ""
//        @State var composeFrom: String = ""
//        @State var composeCC: String = ""
//        @State var composeBCC: String = ""
//        @State var composeSubject: String = ""
//        @State var composeBody: String = ""
//        @State var fromAccount: String = ""
//
//        return EmailComposeForm(
//            composeTo: $composeTo,
//            composeFrom: $composeFrom,
//            composeCC: $composeCC,
//            composeBCC: $composeBCC,
//            composeSubject: $composeSubject,
//            composeBody: $composeBody,
//            fromAccount: $fromAccount,
//            isBridge: false
//        )
//    }
//}

#Preview {
    @State var image: Image? = Image("OnboardingTryExample")
    EmailAttachmentView(image: $image)
}
