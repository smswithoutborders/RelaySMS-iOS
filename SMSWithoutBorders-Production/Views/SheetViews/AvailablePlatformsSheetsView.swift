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
    @State var codeVerifier: String = ""
    @State var title: String = "Store Platforms"
    @State var titleRevoke: String = "Revoke Platforms"
    @State var description: String = "Select a platform to send an example message - you can send a message to yourself"
    @State var descriptionRevoke: String = "Choose the platform you will like to revoke accounts from. Next screen will let you choose which account to revoke for the platform."
    @State var isRevoke: Bool = false
    
    var body: some View {
        AvailablePlatformsSheetsView(
            codeVerifier: $codeVerifier,
            title: isRevoke ? titleRevoke : title,
            description: isRevoke ? descriptionRevoke : description,
            type: isRevoke ? AvailablePlatformsSheetsView.TYPE.REVOKE :
                AvailablePlatformsSheetsView.TYPE.STORED)
    }
}


struct OnlineAvailablePlatformsSheetsView: View {
    @Binding var codeVerifier: String
    @State var title = "Available Platforms"
    @State var description = "Select a platform to save it for offline use"
    
    var body: some View {
        AvailablePlatformsSheetsView(
            codeVerifier: $codeVerifier, 
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
                        Text(title).font(.system(size: 32, design: .rounded))
                        
                        Text(description)
                            .font(.system(size: 16, design: .rounded))
                        
                        if loadingOAuthURLScreen {
                            ProgressView()
                                .padding()
                        }
                        else {
                            ScrollViewReader { proxy in
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        if type == TYPE.STORED || type == TYPE.REVOKE {
                                            ForEach(platforms, id: \.name) { platform in
                                                if getStoredPlatforms(platform: platform) {
                                                    getPlatformsSubViews(platform: platform)
                                                }
                                            }
                                        }
                                        else {
                                            ForEach(platforms, id: \.name) { platform in
                                                getPlatformsSubViews(platform: platform)
                                            }
                                        }
                                    }
                                }
                            }
                            Button("Close") {
                                dismiss()
                            }
                            .padding(.vertical, 50)
                        }
                    }.padding()
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
        VStack {
            Button(action: {
                if type == AvailablePlatformsSheetsView.TYPE.AVAILABLE {
                    triggerPlatformRequest(platform: platform)
                }
                else if type == AvailablePlatformsSheetsView.TYPE.STORED || 
                            type == AvailablePlatformsSheetsView.TYPE.REVOKE {
                    print("Checking stored")
                    filterPlatformName = platform.name!
                    accountViewShown = true
                    print("Switching to: \(filterPlatformName)")
                }
            }) {
                if platform.image == nil {
                    Image("exampleGmail")
                        .resizable()
                        .scaledToFill()
                        .clipped()
                        .cornerRadius(10)
                        .shadow(radius: 3)
                        .frame(width: 100, height: 100)
                        .padding()
                }
                else {
                    Image(uiImage: UIImage(data: platform.image!)!)
                        .resizable()
                        .scaledToFill()
                        .clipped()
                        .cornerRadius(10)
                        .shadow(radius: 3)
                        .frame(width: 100, height: 100)
                        .padding()
                }
            }
            .id(platform.id)
            .sheet(isPresented: $showPhonenumberView) {
                PhoneNumberSheetView(platformName: phonenumberViewPlatform)
            }
            .sheet(isPresented: $accountViewShown) {
                AccountSheetView(
                    filter: filterPlatformName,
                    isRevoke: type == AvailablePlatformsSheetsView.TYPE.REVOKE)
            }
            .shadow(color: Color.white, radius: 8, x: -9, y: -9)
            .shadow(color: Color(red: 163/255, green: 177/255, blue: 198/255), radius: 8, x: 9, y: 9)
            .padding(.vertical, 20)
            Text(platform.name!)
                .font(.system(size: 16, design: .rounded))
            Text(platform.protocol_type!)
                .font(.system(size: 10, design: .rounded))
            
        }
    }
    
    private func triggerPlatformRequest(platform: PlatformsEntity) {
        print(platform.protocol_type)
        switch platform.protocol_type {
        case "oauth2":
            loadingOAuthURLScreen = true
            Task {
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
                loadingOAuthURLScreen = false
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
        
        let container = createInMemoryPersistentContainer()
        populateMockData(container: container)
        
//        return OfflineAvailablePlatformsSheetsView(codeVerifier: $codeVerifier)
        return OnlineAvailablePlatformsSheetsView(codeVerifier: $codeVerifier)
        .environment(\.managedObjectContext, container.viewContext)
    }
}
