//
//  RecentsView.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 26/07/2024.
//

import SwiftUI
import MessageUI
import CoreData
import UIKit

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
    
    let radius = 20.0
    var squareSide: CGFloat {
        2.0.squareRoot() * radius
    }

    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(.white)
                    .frame(width: radius * 2, height: radius * 2)
                logo
                    .resizable()
                    .aspectRatio(1.0, contentMode: .fit)
                    .frame(width: squareSide, height: squareSide)
                
            }
            VStack {
                HStack {
                    Text(subject)
                        .bold()
                        .font(.subheadline)
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
            .font(.subheadline)
    }
}

@ViewBuilder
func getNoLoggedInView() -> some View {
    VStack {
        Image("NoLoggedIn")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 200, height: 200)
            .padding(.bottom, 20)
        Text("No Vault account")
            .font(.title)
            .padding(.bottom, 3)
        Text("Create new account or log into existing one to begin sending messages from stored online platforms")
            .font(.subheadline)
            .multilineTextAlignment(.center)
            .foregroundColor(.secondary)
    }.padding()
    Spacer()
}

struct RecentsView: View {
    @Environment(\.managedObjectContext) var context
    @FetchRequest(sortDescriptors: []) var platforms: FetchedResults<PlatformsEntity>
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \MessageEntity.date, ascending: false)])
    var messages: FetchedResults<MessageEntity>

    @Binding var codeVerifier: String
    @Binding var isLoggedIn: Bool

    @State var errorMessage: String = ""
    @State var otpRetryTimer: Int?

    @State var showAvailablePlatforms: Bool = false
    @State var showComposePlatforms: Bool = false
    
    @State var messagePlatformViewRequested: Bool = false
    @State var emailPlatformViewRequested: Bool = false
    @State var textPlatformViewRequested: Bool = false
    
    @State var messagePlatformViewPlatformName: String = ""
    @State var messagePlatformViewFromAccount: String = ""

    @State var loginSheetVisible: Bool = false
    @State var signupSheetVisible: Bool = false
    @State var loginFailed: Bool = false
    
    var body: some View {
        NavigationView {
            VStack {
                if !isLoggedIn {
                    notLoggedInView()
                }
                else {
                    if messages.isEmpty {
                        noSentMessages()
                    }
                    else {
                        sentMessages()
                    }
                }
            }
            .navigationTitle("Recents")
        }
        .task {
            do {
                try await refreshLocalDBs(context: context)
            } catch {
                print("Failed to refresh remote db")
            }
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
                else if platform.service_type == "message" {
                    MessagingView(
                        platformName: message.platformName,
                        fromAccount: message.fromAccount,
                        message: message)
                }
            }
        }
    }
    
    func refreshLocalDBs(context: NSManagedObjectContext) async throws {
        await Task.detached(priority: .userInitiated) {
            Publisher.getPlatforms() { result in
                switch result {
                case .success(let data):
                    print("Success: \(data)")
                    for platform in data {
                        if(ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1") {
                            downloadAndSaveIcons(
                                url: URL(string: platform.icon_png)!,
                                platform: platform, viewContext: context)
                        }
                    }
                case .failure(let error):
                    print("Failed to load JSON data: \(error)")
                }
            }
        }
    }
    
    @ViewBuilder
    func notLoggedInView() -> some View {
        Spacer()
        getNoLoggedInView()
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
    }
    
    @ViewBuilder
    func sentMessages() -> some View {
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
                    
                }.background(
                    NavigationLink(
                        destination: OfflineAvailablePlatformsSheetsView(), isActive: $showComposePlatforms) {
                                EmptyView()
                            }
                )
                    
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
                }.background(
                    NavigationLink(destination: OnlineAvailablePlatformsSheetsView(codeVerifier: $codeVerifier), isActive: $showAvailablePlatforms) {
                        EmptyView()
                    }
                )
            }
            .padding()
        }
        
    }
    
    @ViewBuilder
    func noSentMessages() -> some View {
        getNoRecentsView()
                .padding()
        
        VStack {
            Button {
                showComposePlatforms = true
            } label: {
                Text("Send new message")
                    .bold()
                    .frame(maxWidth: .infinity)
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
            .buttonStyle(.bordered)
            .controlSize(.large)
            
        }
        .padding()
        .background(
            Group {
                NavigationLink(
                    destination: OfflineAvailablePlatformsSheetsView(),
                    isActive: $showComposePlatforms) {
                        EmptyView()
                    }

                NavigationLink(destination: OnlineAvailablePlatformsSheetsView(
                    codeVerifier: $codeVerifier), isActive: $showAvailablePlatforms) {
                        EmptyView()
                }
            }.hidden()
        )
    }


}

struct RecentsView_Preview: PreviewProvider {
    static var previews: some View {
        @State var codeVerifier: String = ""
        @State var isLoggedIn: Bool = false
        
        let container = createInMemoryPersistentContainer()
        populateMockData(container: container)

        return RecentsView(codeVerifier: $codeVerifier, isLoggedIn: $isLoggedIn)
            .environment(\.managedObjectContext, container.viewContext)
    }
}
