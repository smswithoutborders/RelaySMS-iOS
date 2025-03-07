//
//  Recents1.swift
//  SMSWithoutBorders-Production
//
//  Created by MAC on 21/01/2025.
//

import SwiftUI

struct ComposeNewMessageSheetView: View {
    @Binding var composeNewMessageSheetRequested: Bool
    @Binding var parentSheetShown: Bool

    var body: some View {
        VStack {
            Image(systemName: "person.crop.circle.badge.plus")
                .resizable()
                .scaledToFit()
                .frame(width: 75, height: 75)

            Text("This is a brief summary of what happens")
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding()

            Text("This is precise information for what happens")

            Button(action: {
                parentSheetShown.toggle()
                composeNewMessageSheetRequested.toggle()
            }) {
                Text("Continue")
            }
            .buttonStyle(.bordered)
            .tint(.primary)
            .padding()
        }
    }
}

struct CreateAccountSheetView: View {
    @Binding var createAccountSheetRequested: Bool
    @Binding var parentSheetShown: Bool

    var body: some View {
        VStack {
            Image(systemName: "person.crop.circle.badge.plus")
                .resizable()
                .scaledToFit()
                .frame(width: 75, height: 75)

            Text("This is a brief summary of what happens")
                .font(RelayTypography.titleLarge)
                .multilineTextAlignment(.center)
                .padding()

            Text("This is precise information for what happens")
            Spacer().frame(height: 32)
            Button(action: {
                parentSheetShown.toggle()
                createAccountSheetRequested.toggle()
            }) {
                Text("Continue").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .clipShape(.capsule)
            .controlSize(.large)
            .padding(.bottom, 10)
        }
        .padding([.leading, .trailing], 16)
    }
}

struct LoginAccountSheetView: View {
    @Binding var loginSheetRequested: Bool
    @Binding var parentSheetShown: Bool

    var body: some View {
        VStack {
            Image(systemName: "person.crop.circle.badge")
                .resizable()
                .scaledToFit()
                .frame(width: 75, height: 75)

            Text("This is a brief summary of what happens")
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding()

            Text("This is precise information for what happens")

            Button(action: {
                parentSheetShown.toggle()
                loginSheetRequested.toggle()
            }) {
                Text("Continue")
            }
            .buttonStyle(.bordered)
            .padding()
        }
    }
}

struct SendFirstMessageView: View {
    @State private var sheetComposeNewPresented: Bool = false
    @Binding var composeNewSheetRequested: Bool

    var body: some View {
        VStack() {
            Image("5")
            Button {
                sheetComposeNewPresented.toggle()
            } label: {
                Label("Compose new message", systemImage: "pencil.circle")
            }
            .buttonStyle(.relayButton(variant: .primary))
            .sheet(isPresented: $sheetComposeNewPresented) {
                ComposeNewMessageSheetView(
                    composeNewMessageSheetRequested: $sheetComposeNewPresented,
                    parentSheetShown: $composeNewSheetRequested)
                    .applyPresentationDetentsIfAvailable()
            }
            
            Spacer().frame(height: 16)
            
            Text("Your phone number is your primary account!")
                .font(.caption)
                .multilineTextAlignment(.center)
            Text("your_phonenumber@relaysms.me")
                .font(.caption2)
                .foregroundStyle(Color("AccentColor"))
        }

    }
}

struct LoginWithInternetView: View {
    @State private var sheetCreateAccountIsPresented: Bool = false
    @State private var sheetLoginIsPresented: Bool = false
    @State private var isLoggedIn: Bool = false
    @Binding var loginSheetRequested: Bool
    @Binding var createAccountSheetRequsted: Bool

    var body: some View {
        VStack(spacing: 16) {
            Text("Login with internet")
                .font(RelayTypography.titleLarge)
                .foregroundColor(Color("AccentColor"))

            Text("These features requires you to have an internet connection")
                .font(.caption)
                .multilineTextAlignment(.center)
        }

        HStack(spacing: 8) {
            Button(action: {
                sheetCreateAccountIsPresented.toggle()
            }) {

                Label("Sign Up", systemImage: "person.crop.circle.badge.plus")
                    .frame(maxWidth: .infinity)

            }
            .buttonStyle(.relayButton(variant: .secondary))
            .sheet(isPresented: $sheetCreateAccountIsPresented) {
                CreateAccountSheetView(
                    createAccountSheetRequested: $createAccountSheetRequsted,
                    parentSheetShown: $sheetCreateAccountIsPresented)
                    .applyPresentationDetentsIfAvailable()
            }
            .buttonStyle(.bordered)

            Button(action: {
                sheetLoginIsPresented.toggle()
            }) {
                Label("Log in", systemImage: "person.crop.circle.badge")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.relayButton(variant: .secondary))
            .sheet(isPresented: $sheetLoginIsPresented) {
                LoginAccountSheetView(
                    loginSheetRequested: $loginSheetRequested,
                    parentSheetShown: $sheetLoginIsPresented)
                    .applyPresentationDetentsIfAvailable()
            }
            .buttonStyle(.bordered)
        }
    }
}

struct WalkthroughViews: View {
    @Binding var sheetCreateAccountIsPresented: Bool

    var body: some View {
        VStack {
            Text("Having trouble using the app?")
                .font(.headline)
            Text("Check out our step-by-step guide")
                .font(.caption)
                .multilineTextAlignment(.center)
        }

        HStack {
            Button(action: {
                sheetCreateAccountIsPresented.toggle()
            }) {
                ZStack {
                    VStack {
                        Image("learn1")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 75, height: 75)
                            .padding()
                        Text("Messaging with your RelaySMS account")
                            .font(.caption2)
                    }
                    .padding()

                    Image(systemName: "info.circle")
                        .offset(x: 55, y: -70)
                }
            }
            .buttonStyle(.bordered)
            .padding(.top)
            .sheet(isPresented: $sheetCreateAccountIsPresented) {
            }

            Button(action: {
                sheetCreateAccountIsPresented.toggle()
            }) {
                ZStack {
                    VStack {
                        Image("learn1")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 75, height: 75)
                            .padding()
                        Text("Messaging with your personal accounts")
                            .font(.caption2)
                    }
                    .padding()

                    Image(systemName: "info.circle")
                        .offset(x: 55, y: -70)
                }
            }
            .buttonStyle(.bordered)
            .padding(.top)
            .sheet(isPresented: $sheetCreateAccountIsPresented) {
            }

        }
        HStack {
            Button(action: {
                sheetCreateAccountIsPresented.toggle()
            }) {
                ZStack {
                    VStack {
                        Image("learn1")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 75, height: 75)
                            .padding()
                        Text("Choosing a country for routing your messages")
                            .font(.caption2)
                    }
                    .padding()

                    Image(systemName: "info.circle")
                        .offset(x: 120, y: -60)
                }
            }
            .buttonStyle(.bordered)
            .padding(.top)
            .sheet(isPresented: $sheetCreateAccountIsPresented) {
            }
        }
    }
}


struct NotLoggedInMessagesPresentInboxView: View {
    @FetchRequest var inboxMessages: FetchedResults<MessageEntity>
    @FetchRequest(sortDescriptors: []) var platforms: FetchedResults<PlatformsEntity>

    @State var composeNewRequested = false

    @Binding var composeNewMessageRequested: Bool
    @Binding var loginSheetRequested: Bool
    @Binding var createAccountSheetRequested: Bool

    @Binding var requestedMessage: Messages?
    @Binding var emailIsRequested: Bool

    init(
        composeNewMessageRequested: Binding<Bool>,
        loginSheetRequested: Binding<Bool>,
        createAccountSheetRequested: Binding<Bool>,
        requestedMessage: Binding<Messages?>,
        emailIsRequested: Binding<Bool>
    ) {
        _inboxMessages = FetchRequest<MessageEntity>(
            sortDescriptors: [
                NSSortDescriptor(
                    keyPath: \MessageEntity.date,
                    ascending: false
                )
            ],
            predicate: NSPredicate(format: "type != %@", Bridges.SERVICE_NAME_INBOX)
        )

        _composeNewMessageRequested = composeNewMessageRequested
        _loginSheetRequested = loginSheetRequested
        _createAccountSheetRequested = createAccountSheetRequested
        _requestedMessage = requestedMessage
        _emailIsRequested = emailIsRequested
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack {
                List(inboxMessages, id: \.self) { message in
                    Card(
                        logo: getImageForPlatform(name: message.platformName!),
                        subject: message.subject!,
                        toAccount: message.toAccount!,
                        messageBody: message.body!,
                        date: Int(message.date)
                    )
                        .onTapGesture {
                            requestedMessage = Messages(
                                subject: message.subject!,
                                data: message.body!,
                                fromAccount: message.fromAccount!,
                                toAccount: message.toAccount!,
                                platformName: message.platformName!,
                                date: Int(message.date)
                            )
                            if message.type == Bridges.SERVICE_NAME_INBOX ||
                                   message.type == Bridges.SERVICE_NAME {
                                emailIsRequested.toggle()
                            }
                        }
                }
            }
            VStack {
                Button {
                    composeNewRequested.toggle()
                } label: {
                    Image(systemName: "person.crop.circle.fill.badge.plus")
                        .frame(width: 48, height: 48)
                        .foregroundColor(Color.white)
                }
                .background(Color("AccentColor"))
                .cornerRadius(12)
        
            }
            .padding()
        }
        .onChange(of: composeNewMessageRequested) { newValue in
            if newValue {
                composeNewRequested.toggle()
            }
        }
        .onChange(of: loginSheetRequested) { newValue in
            if newValue {
                composeNewRequested.toggle()
            }
        }
        .onChange(of: createAccountSheetRequested) { newValue in
            if newValue {
                composeNewRequested.toggle()
            }
        }
        .sheet(isPresented: $composeNewRequested) {
            VStack(alignment: .center) {
                Text("Get Started")
                    .font(.headline)

                NotLoggedInNoMessagesView(
                    composeNewMessageRequested: $composeNewMessageRequested,
                    loginSheetRequested: $loginSheetRequested,
                    createAccountSheetRequested: $createAccountSheetRequested
                )
            }
            .padding()
        }
    }

    func getImageForPlatform(name: String) -> Image {
        let image = platforms.filter {
            $0.name == name
        }
        .first?.image
        if image != nil {
            return Image(uiImage: UIImage(data: image!)!)
        }
        return Image("Logo")
    }
}

struct NotLoggedInNoMessagesView: View {
    @Binding var composeNewMessageRequested: Bool
    @Binding var loginSheetRequested: Bool
    @Binding var createAccountSheetRequested: Bool

    var body: some View {
            VStack(spacing: 10) {
                Spacer()
                SendFirstMessageView(
                    composeNewSheetRequested: $composeNewMessageRequested
                )
                Spacer()
                LoginWithInternetView(
                    loginSheetRequested: $loginSheetRequested,
                    createAccountSheetRequsted: $createAccountSheetRequested
                ).padding(.bottom, 48)
//                    WalkthroughViews(sheetCreateAccountIsPresented: $walkthroughViewsShown)
            }
            .navigationTitle("Get Started")
            .padding([.trailing, .leading], 16)
    }
}


struct RecentsViewNotLoggedIn: View {
    @FetchRequest(sortDescriptors: []) var messages: FetchedResults<MessageEntity>

    @State var walkthroughViewsShown: Bool = false

    @Binding var isLoggedIn: Bool
    @Binding var composeNewMessageRequested: Bool
    @Binding var createAccountSheetRequested: Bool
    @Binding var loginSheetRequested: Bool

    @Binding var requestedMessage: Messages?
    @Binding var emailIsRequested: Bool

    var body: some View {
        NavigationView {
            VStack {
                if !messages.isEmpty {
                    NotLoggedInMessagesPresentInboxView(
                        composeNewMessageRequested: $composeNewMessageRequested,
                        loginSheetRequested: $loginSheetRequested,
                        createAccountSheetRequested: $createAccountSheetRequested,
                        requestedMessage: $requestedMessage,
                        emailIsRequested: $emailIsRequested
                    )
                        .navigationTitle("Recents")
                } else {
                    NotLoggedInNoMessagesView(
                        composeNewMessageRequested: $composeNewMessageRequested,
                        loginSheetRequested: $loginSheetRequested,
                        createAccountSheetRequested: $createAccountSheetRequested
                    )
                }
            }
        }
    }
}

struct RecentsViewNotLoggedIn_Preview: PreviewProvider {
    static var previews: some View {
        @State var isLoggedIn = false
        @State var composeNewMessageRequested = false
        @State var createAccountSheetRequested = false
        @State var loginSheetRequested = false
        @State var requestedMessage: Messages? = nil
        @State var emailIsRequested = false
        RecentsViewNotLoggedIn(
            isLoggedIn: $isLoggedIn,
            composeNewMessageRequested: $composeNewMessageRequested,
            createAccountSheetRequested: $createAccountSheetRequested,
            loginSheetRequested: $loginSheetRequested,
            requestedMessage: $requestedMessage,
            emailIsRequested: $emailIsRequested
        )
    }
}

struct RecentsViewNotLoggedInMessage_Preview: PreviewProvider {
    static var previews: some View {
        @State var isLoggedIn = false
        @State var composeNewMessageRequested = false
        @State var createAccountSheetRequested = false
        @State var loginSheetRequested = false

        @State var requestedMessage: Messages? = nil
        @State var emailIsRequested = false

        let container = createInMemoryPersistentContainer()
        populateMockData(container: container)

        return RecentsViewNotLoggedIn(
            isLoggedIn: $isLoggedIn,
            composeNewMessageRequested: $composeNewMessageRequested,
            createAccountSheetRequested: $createAccountSheetRequested,
            loginSheetRequested: $loginSheetRequested,
            requestedMessage: $requestedMessage,
            emailIsRequested: $emailIsRequested
        )
            .environment(\.managedObjectContext, container.viewContext)
    }
}

