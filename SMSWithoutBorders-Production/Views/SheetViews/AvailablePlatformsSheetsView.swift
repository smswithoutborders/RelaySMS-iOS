//
//  AvailablePlatformsView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/15/22.
//

import SwiftUI
import SwiftSVG
import CachedAsyncImage
import CoreData

struct OfflineAvailablePlatformsSheetsView: View {
    @Binding var messagePlatformViewRequested: Bool
    @Binding var messagePlatformViewPlatformName: String
    @Binding var messagePlatformViewFromAccount: String

    @State var codeVerifier: String = ""
    @State var title: String = "Compose for platform"
    @State var titleRevoke: String = "Revoke Platforms"
    @State var description: String = "Select a platform to send an example message - you can send a message to yourself"
    @State var descriptionRevoke: String = "Choose the platform you will like to revoke accounts from. Next screen will let you choose which account to revoke for the platform."
    @State var isRevoke: Bool = false
    
    var body: some View {
        AvailablePlatformsSheetsView(
            codeVerifier: $codeVerifier,
            messagePlatformViewRequested: $messagePlatformViewRequested, 
            messagePlatformViewPlatformName: $messagePlatformViewPlatformName,
            messagePlatformViewFromAccount: $messagePlatformViewFromAccount, 
            title: isRevoke ? titleRevoke : title,
            description: isRevoke ? descriptionRevoke : description,
            type: isRevoke ? AvailablePlatformsSheetsView.TYPE.REVOKE :
                AvailablePlatformsSheetsView.TYPE.STORED)
    }
}


struct OnlineAvailablePlatformsSheetsView: View {
    @Binding var codeVerifier: String
    @State var messagePlatformViewRequested: Bool = false
    @State var messagePlatformViewPlatformName: String = ""
    @State var messagePlatformViewFromAccount: String = ""

    @State var title = "Available Platforms"
    @State var description = "Select a platform to save it for offline use"
    
    var body: some View {
        AvailablePlatformsSheetsView(
            codeVerifier: $codeVerifier, 
            messagePlatformViewRequested: $messagePlatformViewRequested, 
            messagePlatformViewPlatformName: $messagePlatformViewPlatformName,
            messagePlatformViewFromAccount: $messagePlatformViewFromAccount,
            title: title,
            description: description)
    }
}


struct AvailablePlatformsSheetsView: View {
    enum TYPE {
        case AVAILABLE
        case STORED
        case REVOKE
    }
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var viewContext
    
    @FetchRequest(sortDescriptors: []) var storedPlatforms: FetchedResults<StoredPlatformsEntity>
    @FetchRequest(sortDescriptors: []) var platforms: FetchedResults<PlatformsEntity>

    @State var platformsLoading = false
    
    @Binding var codeVerifier: String
    @Binding var messagePlatformViewRequested: Bool
    @Binding var messagePlatformViewPlatformName: String
    @Binding var messagePlatformViewFromAccount: String
    
    @State var title: String
    @State var description: String
    
    @State var type: TYPE = TYPE.AVAILABLE
    @Environment(\.openURL) var openURL
    
    @State var accountViewShown: Bool = false
    @State var filterPlatformName: String = ""
    
    @State var loadingOAuthURLScreen: Bool = false
    
    @State private var isAnimating: Bool = false
    
    @State private var showPhonenumberView: Bool = false
    @State private var phonenumberViewPlatform: String = ""

    @State var phoneNumber: String?

    var body: some View {
        NavigationView {
            VStack {
                if(platforms.isEmpty) {
                    Text("No platforms")
                        .padding()
                }
                else {
                    VStack {
                        Text(title)
                            .font(.title2)
                        
                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                            .multilineTextAlignment(.center)
                            .padding()

                        if loadingOAuthURLScreen {
                            ProgressView()
                                .padding()
                        }
                        else {
                            VStack {
                                if type == TYPE.STORED || type == TYPE.REVOKE {
                                    List(platforms, id: \.name) { platform in
                                        if getStoredPlatforms(platform: platform) {
                                            getPlatformsSubViews(platform: platform)
                                        }
                                    }
                                }
                                else {
                                    List(platforms, id: \.name) { platform in
                                        getPlatformsSubViews(platform: platform)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
        }
        .task {
            do {
                try await refreshLocalDBs()
            } catch {
                print("Failed to refresh remote db")
            }
        }
    }
    
    
    func refreshLocalDBs() async throws {
        await Task.detached(priority: .userInitiated) {
            Publisher.getPlatforms() { result in
                switch result {
                case .success(let data):
                    print("Success: \(data)")
                    for platform in data {
                        if(ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1") {
                            downloadAndSaveIcons(
                                url: URL(string: platform.icon_png)!, 
                                platform: platform, viewContext: viewContext)
                        }
                    }
                case .failure(let error):
                    print("Failed to load JSON data: \(error)")
                }
            }
        }
    }
    
    func getStoredPlatforms(platform: PlatformsEntity) -> Bool {
        print("checking against: \(platform.name)")
        return storedPlatforms.contains{ $0.name == platform.name}
    }
    
    
    @ViewBuilder
    func getPlatformsSubViews(platform: PlatformsEntity) -> some View{
        HStack {
            Button(action: {
                if type == AvailablePlatformsSheetsView.TYPE.AVAILABLE {
                    triggerPlatformRequest(platform: platform)
                }
                else if type == AvailablePlatformsSheetsView.TYPE.STORED || 
                            type == AvailablePlatformsSheetsView.TYPE.REVOKE {
                    filterPlatformName = platform.name!
                    accountViewShown = true
                    messagePlatformViewPlatformName = platform.name!
                }
            }) {
                (platform.image == nil ? Image("Logo") : Image(uiImage: UIImage(data: platform.image!)!))
                    .resizable()
                    .cornerRadius(10)
                    .shadow(radius: 3)
                    .frame(width: 50, height: 50)
            }
            .id(platform.id)
            .sheet(isPresented: $showPhonenumberView) {
                PhoneNumberSheetView(platformName: phonenumberViewPlatform)
            }
            .sheet(isPresented: $accountViewShown) {
                AccountSheetView(
                    filter: filterPlatformName,
                    globalDismiss: $accountViewShown,
                    messagePlatformViewRequested: $messagePlatformViewRequested,
                    messagePlatformViewFromAccount: $messagePlatformViewFromAccount,
                    isRevoke: type == AvailablePlatformsSheetsView.TYPE.REVOKE)
            }
            .shadow(color: Color.white, radius: 8, x: -9, y: -9)
            .shadow(color: Color(red: 163/255, green: 177/255, blue: 198/255), radius: 8, x: 9, y: 9)
            .padding(.horizontal, 20)
            
            VStack(alignment: .leading) {
                Text(platform.name!)
                    .bold()
                
                Text(platform.protocol_type!)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
        }
    }
    
    private func triggerPlatformRequest(platform: PlatformsEntity) {
        let backgroundQueueu = DispatchQueue(label: "addingNewPlatformQueue", qos: .background)
        
        switch platform.protocol_type {
        case "oauth2":
            loadingOAuthURLScreen = true
            backgroundQueueu.async {
                do {
                    let publisher = Publisher()
                    let response = try publisher.getOAuthURL(
                        platform: platform.name!,
                        supportsUrlSchemes: platform.support_url_scheme)
                    codeVerifier = response.codeVerifier
                    print("Requesting url: \(response.authorizationURL)")
                    openURL(URL(string: response.authorizationURL)!)
                }
                catch {
                    print("Some error occured: \(error)")
                }
                dismiss()
            }
        case "pnba":
            phonenumberViewPlatform = platform.name!
            showPhonenumberView = true
        case .none:
            Task {}
        case .some(_):
            Task {}
        }
    }
}

struct AvailablePlatformsSheetsView_Previews: PreviewProvider {
    static var previews: some View {
        @State var codeVerifier = ""
        @State var messagePlatformViewRequested: Bool = false
        @State var messagePlatformViewFromAccount: String = ""
        @State var messagePlatformViewPlatformName: String = ""

        let container = createInMemoryPersistentContainer()
        populateMockData(container: container)
        
        return OfflineAvailablePlatformsSheetsView(
            messagePlatformViewRequested: $messagePlatformViewRequested, 
            messagePlatformViewPlatformName: $messagePlatformViewPlatformName,
            messagePlatformViewFromAccount: $messagePlatformViewFromAccount,
            codeVerifier: codeVerifier)
        .environment(\.managedObjectContext, container.viewContext)
    }
}
