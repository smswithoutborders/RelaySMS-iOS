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

class MessageComposerDelegate: NSObject, MFMessageComposeViewControllerDelegate {
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        // Customize here
        print("external - dismissing")
        controller.viewControllers = [UIViewController]()
        controller.dismiss(animated: true, completion: nil)
    }
}


class ViewController: UIViewController, MFMessageComposeViewControllerDelegate {
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func dismiss() {
        print("self - dismissing")
        self.dismiss(animated: true, completion: nil)
    }

    public func sendSMS(message: String, receipient: String) {
        
        let messageComposeDelegate: MFMessageComposeViewControllerDelegate = MessageComposerDelegate()
        let messageVC = MFMessageComposeViewController()
        messageVC.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done, target: self, action: Selector(("dismiss")))
        messageVC.navigationBar.isHidden = true
        
        messageVC.messageComposeDelegate = self
        messageVC.recipients = [receipient]
        messageVC.body = message
        
        let vc = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController
        
        if MFMessageComposeViewController.canSendText() {
//            vc?.present(messageVC, animated: true)
            vc?.present(messageVC, animated: true)
        }
        else {
            print("User hasn't setup Messages.app")
        }
    }

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
    }
}

struct RecentsView: View {
    @Environment(\.managedObjectContext) var context
    @FetchRequest(sortDescriptors: []) var platforms: FetchedResults<PlatformsEntity>
    @FetchRequest(sortDescriptors: []) var messages: FetchedResults<MessageEntity>

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
    
    var vc: ViewController = ViewController()

    var body: some View {
        NavigationView {
            VStack {
                if !isLoggedIn {
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

                } else {
                    if messages.isEmpty {
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
                                    destination: OfflineAvailablePlatformsSheetsView(
                                        messagePlatformViewRequested: $messagePlatformViewRequested,
                                        messagePlatformViewPlatformName: $messagePlatformViewPlatformName,
                                        messagePlatformViewFromAccount: $messagePlatformViewFromAccount),
                                    isActive: $showComposePlatforms) {
                                        EmptyView()
                                    }

                                NavigationLink(destination: OnlineAvailablePlatformsSheetsView(
                                    codeVerifier: $codeVerifier), isActive: $showAvailablePlatforms) {
                                        EmptyView()
                                }
                            }.hidden()
                        )
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
                                    
                                }.background(
                                    NavigationLink(
                                        destination: OfflineAvailablePlatformsSheetsView(
                                            messagePlatformViewRequested: $messagePlatformViewRequested,
                                            messagePlatformViewPlatformName: $messagePlatformViewPlatformName,
                                            messagePlatformViewFromAccount: $messagePlatformViewFromAccount), isActive: $showComposePlatforms) {
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
