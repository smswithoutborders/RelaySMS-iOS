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
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding()
            
            Text("This is precise information for what happens")
            
            Button(action: {
                parentSheetShown.toggle()
                createAccountSheetRequested.toggle()
            }) {
                Text("Continue")
            }
            .buttonStyle(.bordered)
            .tint(.primary)
            .padding()
        }
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
        HStack(spacing: 50) {
            Button(action: {
                sheetComposeNewPresented.toggle()
            }) {
                VStack {
                    Image(systemName: "pencil.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 75, height: 75)
                        .padding(.bottom)
                    Text("Compose new message")
                        .font(.footnote)
                }
                .padding()
            }
            .buttonStyle(.bordered)
            .sheet(isPresented: $sheetComposeNewPresented) {
                ComposeNewMessageSheetView(
                    composeNewMessageSheetRequested: $sheetComposeNewPresented,
                    parentSheetShown: $composeNewSheetRequested)
                .applyPresentationDetentsIfAvailable()
            }
            .padding()
        }
        VStack {
            Text("Your phone number is your primary account!")
                .font(.caption)
                .multilineTextAlignment(.center)
            Text("your_phonenumber@relaysms.me")
                .font(.caption2)
        }

    }
}

struct LoginWithInternetView : View {
    @State private var sheetCreateAccountIsPresented: Bool = false
    @State private var sheetLoginIsPresented: Bool = false
    @State private var isLoggedIn: Bool = false
    @Binding var loginSheetRequested: Bool
    @Binding var createAccountSheetRequsted: Bool

    var body: some View {
        VStack {
            Text("Login with internet")
                .font(.headline)
            Text("These features requires you to have an internet connection")
                .font(.caption2)
                .multilineTextAlignment(.center)
        }
        HStack(spacing: 50) {
            Button(action: {
                sheetCreateAccountIsPresented.toggle()
            }) {
                VStack {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 75, height: 75)
                    Text("Create Account")
                        .font(.caption)
                }
            }
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
                VStack {
                    Image(systemName: "person.crop.circle.badge")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 75, height: 75)
                    Text("Log in")
                        .font(.caption)
                }
            }
            .sheet(isPresented: $sheetLoginIsPresented) {
                LoginAccountSheetView(
                    loginSheetRequested: $loginSheetRequested,
                    parentSheetShown: $sheetLoginIsPresented)
                    .applyPresentationDetentsIfAvailable()
            }
            .buttonStyle(.bordered)
        }
        .padding()
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
    @FetchRequest(sortDescriptors: []) var inboxMessages: FetchedResults<MessageEntity>
    @FetchRequest(sortDescriptors: []) var platforms: FetchedResults<PlatformsEntity>
    
    @State var composeNewRequested = false
    
    @Binding var composeNewMessageRequested: Bool
    @Binding var loginSheetRequested: Bool
    @Binding var createAccountSheetRequested: Bool

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
                }
            }
            VStack {
                Button {
                    composeNewRequested.toggle()
                } label: {
                    Image(systemName: "person.crop.circle.fill.badge.plus")
                        .font(.system(.title))
                        .frame(width: 57, height: 50)
                        .foregroundColor(Color.white)
                        .padding(.bottom, 7)
                }
                .background(.blue)
                .cornerRadius(18)
                 .shadow(color: Color.black.opacity(0.3),
                         radius: 3,
                         x: 3,
                         y: 3
                 )
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
        let image = platforms.filter { $0.name == name}.first?.image
        if image != nil {
            return Image( uiImage: UIImage(data: image!)!)
        }
        return Image("Logo")
    }
}

struct NotLoggedInNoMessagesView: View {
    @Binding var composeNewMessageRequested: Bool
    @Binding var loginSheetRequested: Bool
    @Binding var createAccountSheetRequested: Bool
    
    var body : some View {
        ScrollView {
            VStack(spacing: 10) {
                SendFirstMessageView(
                    composeNewSheetRequested: $composeNewMessageRequested
                )

                Divider()
                    .padding(.bottom, 16)
                
                LoginWithInternetView(
                    loginSheetRequested: $loginSheetRequested,
                    createAccountSheetRequsted: $createAccountSheetRequested
                ).padding(.bottom)

//                    WalkthroughViews(sheetCreateAccountIsPresented: $walkthroughViewsShown)
            }
            .navigationTitle("Get Started")
            .padding()
        }
    }
}


struct RecentsViewNotLoggedIn: View {
    @FetchRequest(sortDescriptors: []) var messages: FetchedResults<MessageEntity>
    
    @State var walkthroughViewsShown: Bool = false
    
    @Binding var isLoggedIn: Bool
    @Binding var composeNewMessageRequested: Bool
    @Binding var createAccountSheetRequested: Bool 
    @Binding var loginSheetRequested: Bool

    var body: some View {
        NavigationView {
            VStack {
                if !messages.isEmpty {
                    NotLoggedInMessagesPresentInboxView(
                        composeNewMessageRequested: $composeNewMessageRequested,
                        loginSheetRequested: $loginSheetRequested,
                        createAccountSheetRequested: $createAccountSheetRequested
                    )
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
        RecentsViewNotLoggedIn(
            isLoggedIn: $isLoggedIn,
            composeNewMessageRequested: $composeNewMessageRequested,
            createAccountSheetRequested: $createAccountSheetRequested,
            loginSheetRequested: $loginSheetRequested
        )
    }
}

struct RecentsViewNotLoggedInMessage_Preview: PreviewProvider {
    static var previews: some View {
        @State var isLoggedIn = false
        @State var composeNewMessageRequested = false
        @State var createAccountSheetRequested = false
        @State var loginSheetRequested = false
        
        let container = createInMemoryPersistentContainer()
        populateMockData(container: container)
        
        return RecentsViewNotLoggedIn(
            isLoggedIn: $isLoggedIn,
            composeNewMessageRequested: $composeNewMessageRequested,
            createAccountSheetRequested: $createAccountSheetRequested,
            loginSheetRequested: $loginSheetRequested
        )
        .environment(\.managedObjectContext, container.viewContext)
    }
}

