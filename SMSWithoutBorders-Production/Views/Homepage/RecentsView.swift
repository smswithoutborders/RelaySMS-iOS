//
//  RecentsView.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 26/07/2024.
//

import SwiftUI

public extension Color {

    #if os(macOS)
    static let background = Color(NSColor.windowBackgroundColor)
    static let secondaryBackground = Color(NSColor.underPageBackgroundColor)
    static let tertiaryBackground = Color(NSColor.controlBackgroundColor)
    #else
    static let background = Color(UIColor.systemBackground)
    static let secondaryBackground = Color(UIColor.secondarySystemBackground)
    static let tertiaryBackground = Color(UIColor.tertiarySystemBackground)
    #endif
}

struct Card: View {
    @State var logo: Image
    @State var subject: String
    @State var toAccount: String
    @State var messageBody: String
    @State var date: Int

    var body: some View {
        HStack {
            logo
                .resizable()
                .frame(width: 30, height: 30)
            
            VStack {
                HStack {
                    Text(subject)
                        .bold()
                        .font(.subheadline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(Date(timeIntervalSince1970: TimeInterval(date)), formatter: RelativeDateTimeFormatter())
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .font(.caption)
                }
                .padding(.bottom, 3)

                Text(toAccount)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 5)

                Text(messageBody)
                    .lineLimit(2)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

@ViewBuilder
func getNoRecentsView() -> some View {
    VStack {
        Image("NoRecents")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 200, height: 200)
            .padding(.bottom, 20)
        Text("No recent messages")
            .font(.title)
    }
}

struct RecentsView: View {
    @Environment(\.managedObjectContext) var datastore
    @FetchRequest(sortDescriptors: []) var platforms: FetchedResults<PlatformsEntity>
    @FetchRequest(sortDescriptors: []) var messages: FetchedResults<MessageEntity>

    @Binding var codeVerifier: String
    @Binding var isLoggedIn: Bool

    @State var errorMessage: String = ""
    @State var otpRetryTimer: Int?

    @State var showAvailablePlatforms: Bool = false
    @State var showComposePlatforms: Bool = false
    
    @State var loginSheetVisible: Bool = false
    @State var signupSheetVisible: Bool = false
    @State var loginFailed: Bool = false
    
    var body: some View {
        NavigationView {
            VStack {
                if !isLoggedIn {
                    Spacer()
                    getNoRecentsView()
                    .padding()
                    Spacer()
                    
                    VStack {
                        Button {
                            signupSheetVisible = true
                        } label: {
                            Text("Create account")
                                .bold()
                                .frame(maxWidth: .infinity)
                        }
                        .sheet(isPresented: $signupSheetVisible) {
                            SignupSheetView(
                                completed: $isLoggedIn,
                                failed: $loginFailed,
                                otpRetryTimer: otpRetryTimer ?? 0,
                                errorMessage: errorMessage)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .padding(.bottom, 10)

                        Button {
                            loginSheetVisible = true
                        } label: {
                            Text("Log in")
                                .bold()
                                .frame(maxWidth: .infinity)
                        }
                        .sheet(isPresented: $loginSheetVisible) {
                            LoginSheetView(completed: $isLoggedIn,
                                           failed: $loginFailed)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)

                    }
                    .padding()
                    Spacer()

                } else {
                    if messages.isEmpty {
                        getNoRecentsView()
                    
                        VStack {
                            Button {
                                showComposePlatforms = true
                            } label: {
                                Text("Send new message")
                                    .bold()
                                    .frame(maxWidth: .infinity)
                            }
                            .sheet(isPresented: $showComposePlatforms) {
                                OfflineAvailablePlatformsSheetsView()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .padding(.bottom, 10)

                            Button {
                                showAvailablePlatforms = true
                            } label: {
                                Text("Save platforms")
                                    .bold()
                                    .frame(maxWidth: .infinity)
                            }
                            .sheet(isPresented: $showAvailablePlatforms) {
                                OnlineAvailablePlatformsSheetsView(codeVerifier: $codeVerifier)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)

                        }
                        .padding()
                    } else {
                        ZStack(alignment: .bottomTrailing) {
                            VStack {
                                List {
                                    ForEach(messages, id: \.self) { message in
                                        NavigationLink(
                                            destination: getPlatformView(
                                                message: Messages(
                                                    subject: message.subject!,
                                                    data: message.body!,
                                                    fromAccount: message.fromAccount!,
                                                    toAccount: message.toAccount!,
                                                    platformName: message.platformName!,
                                                    date: Int(message.date)))) {
                                            Card(logo: getImageForPlatform(name: message.platformName!),
                                                 subject: message.subject!,
                                                 toAccount: message.toAccount!,
                                                 messageBody: message.body!,
                                                 date: Int(message.date))
                                        }
                                    }
                                }
                            }
                            
                            VStack {
                                VStack {
                                    Button(action: {
                                        showComposePlatforms = true
                                    }, label: {
                                        Image(systemName: "square.and.pencil")
                                            .font(.system(.title))
                                            .frame(width: 57, height: 50)
                                            .foregroundColor(Color.white)
                                            .padding(.bottom, 7)
                                    })
                                    .background(Color.blue)
                                    .cornerRadius(18)
                                    .shadow(color: Color.black.opacity(0.3),
                                            radius: 3,
                                            x: 3,
                                            y: 3)
                                    .sheet(isPresented: $showComposePlatforms) {
                                        OfflineAvailablePlatformsSheetsView()
                                    }
                                    
                                    VStack {
                                        Button(action: {
                                            showAvailablePlatforms = true
                                        }, label: {
                                            Image(systemName: "rectangle.stack.badge.plus")
                                                .font(.system(.title))
                                                .frame(width: 57, height: 50)
                                                .foregroundColor(Color.white)
                                                .padding(.bottom, 7)
                                        })
                                        .background(Color.blue)
                                        .cornerRadius(18)
                                        .shadow(color: Color.black.opacity(0.3),
                                                radius: 3,
                                                x: 3,
                                                y: 3)
                                        .padding()
                                        .sheet(isPresented: $showAvailablePlatforms) {
                                            OnlineAvailablePlatformsSheetsView(codeVerifier: $codeVerifier)
                                        }
                                    }
                                }
                            }
                            
                            
                        }
                    }
                }
            }
            .navigationTitle("Recents")
        }
    }
    
    func getImageForPlatform(name: String) -> Image {
        for platform in platforms {
            if platform.name == name {
                if platform.image != nil {
                    return Image( uiImage: UIImage(data: platform.image!)!)
                }
            }
        }
        return Image("Logo")
    }
    
    @ViewBuilder func getPlatformView(message: Messages) -> some View {
        ForEach(platforms) { platform in
            if platform.name == message.platformName {
                if platform.service_type == "email" {
                    EmailPlatformView(message: message)
                }
                else if platform.service_type == "text" {
                    TextPlatformView(message: message)
                }
            }
        }
    }
}

struct RecentsView_Preview: PreviewProvider {
    static var previews: some View {
        @State var codeVerifier: String = ""
        @State var isLoggedIn: Bool = true
        
        let container = createInMemoryPersistentContainer()
        populateMockData(container: container)

        return RecentsView(codeVerifier: $codeVerifier, isLoggedIn: $isLoggedIn)
            .environment(\.managedObjectContext, container.viewContext)
    }
}
