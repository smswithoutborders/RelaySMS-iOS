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
            .fixedSize(horizontal: false, vertical: true)
            .foregroundColor(.secondary)
    }.padding()
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
            DispatchQueue.background(background: {
                do {
                    try refreshLocalDBs()
                    print("Finished refreshing local db")
                } catch {
                    print("Failed to refresh local DBs: \(error)")
                }
            }, completion: {

            })
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

    func refreshLocalDBs() throws {
        Publisher.getPlatforms() { result in
            switch result {
            case .success(let data):
                print("Success: \(data)")
                for platform in data {
                    if(ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1") {
                        do {
                            DownloadContent.downloadAndSaveIcons(
                                url: URL(string: platform.icon_png)!,
                                platform: platform,
                                viewContext: context)
                        } catch {
                            print("Issue downloading icons: \(error)")
                        }
                    }
                }
            case .failure(let error):
                print("Failed to load JSON data: \(error)")
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
//                LoginSheetView(isLoggedIn: $isLoggedIn)
            }
            .buttonStyle(.bordered)
            .padding(.bottom, 10)
            .controlSize(.large)

            Button {
                loginSheetVisible = true
            } label: {
                Text("Continue without internet")
                    .bold()
                    .frame(maxWidth: .infinity)
            }
            .sheet(isPresented: $loginSheetVisible) {
//                LoginSheetView(completed: $isLoggedIn,
//                               failed: $loginFailed, isLoggedIn: $isLoggedIn)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

        }
        .padding()
        Spacer()
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

#Preview {
    @State var codeVerifier: String = ""
    @State var isLoggedIn: Bool = true

    let container = createInMemoryPersistentContainer()
    populateMockData(container: container)

    return RecentsView(codeVerifier: $codeVerifier, isLoggedIn: $isLoggedIn)
        .environment(\.managedObjectContext, container.viewContext)
}

#Preview {
    @State var codeVerifier: String = ""
    @State var isLoggedIn: Bool = false

    return RecentsView(codeVerifier: $codeVerifier, isLoggedIn: $isLoggedIn)
}

