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

func createInMemoryPersistentContainer() -> NSPersistentContainer {
    let container = NSPersistentContainer(name: "Datastore")
    let description = NSPersistentStoreDescription()
    description.type = NSInMemoryStoreType
    container.persistentStoreDescriptions = [description]
    
    container.loadPersistentStores { description, error in
        if let error = error {
            fatalError("Failed to load in-memory store: \(error)")
        }
    }
    
    return container
}

func populateMockData(container: NSPersistentContainer) {
    let context = container.viewContext
    
    let platformEntityGmail = PlatformsEntity(context: context)
    platformEntityGmail.image = nil
    platformEntityGmail.name = "gmail"
    platformEntityGmail.protocol_type = "oauth"
    platformEntityGmail.service_type = "email"
    platformEntityGmail.shortcode = "g"
    
    let platformEntityTwitter = PlatformsEntity(context: context)
    platformEntityTwitter.image = nil
    platformEntityTwitter.name = "twitter"
    platformEntityTwitter.protocol_type = "oauth"
    platformEntityTwitter.service_type = "text"
    platformEntityTwitter.shortcode = "x"
    
    let platformEntityGmail1 = PlatformsEntity(context: context)
    platformEntityGmail1.image = nil
    platformEntityGmail1.name = "telegram"
    platformEntityGmail1.protocol_type = "pnba"
    platformEntityGmail1.service_type = "messaging"
    platformEntityGmail1.shortcode = "T"
    
    let platformEntityTwitter1 = PlatformsEntity(context: context)
    platformEntityTwitter1.image = nil
    platformEntityTwitter1.name = "slack"
    platformEntityTwitter1.protocol_type = "oauth"
    platformEntityTwitter1.service_type = "messaging"
    platformEntityTwitter1.shortcode = "s"

    for i in 0..<3 {
        let name = "gmail"
        let account = "account_\(i)@gmail.com"
        let storedPlatformsEntity = StoredPlatformsEntity(context: context)
        storedPlatformsEntity.name = name
        storedPlatformsEntity.account = account
        storedPlatformsEntity.id = Vault.deriveUniqueKey(platformName: name, 
                                                         accountIdentifier: account)
    }
    for i in 0..<3 {
        let name = "twitter"
        let account = "@twitter_account_\(i)"
        let storedPlatformsEntity = StoredPlatformsEntity(context: context)
        storedPlatformsEntity.name = name
        storedPlatformsEntity.account = account
        storedPlatformsEntity.id = Vault.deriveUniqueKey(platformName: name,
                                                         accountIdentifier: account)
    }

    do {
        try context.save()
    } catch {
        fatalError("Failed to save mock data: \(error)")
    }
}


struct OfflineAvailablePlatformsSheetsView: View {
    @State var codeVerifier: String = ""
    @State var title: String = "Store Platforms"
    @State var description: String = "Select a platform to send an example message - you can send a message to yourself"
    
    var body: some View {
        AvailablePlatformsSheetsView(
            codeVerifier: $codeVerifier,
            title: title,
            description: description,
            type: AvailablePlatformsSheetsView.TYPE.STORED)
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
                                        if type == TYPE.STORED {
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
        VStack {
            Button(action: {
                if type == AvailablePlatformsSheetsView.TYPE.AVAILABLE {
                    loadingOAuthURLScreen = true
                    Task {
                        do {
                            let publisher = Publisher()
                            let response = try publisher.getURL(
                                platform: platform.name!,
                                supportsUrlSchemes: platform.support_url_scheme)
                            codeVerifier = response.codeVerifier
                            print("Requesting url: \(response.authorizationURL)")
                            openURL(URL(string: response.authorizationURL)!)
                        }
                        catch {
                            print("Some error occured: \(error)")
                        }
                    }
                }
                else if type == AvailablePlatformsSheetsView.TYPE.STORED {
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
            .sheet(isPresented: $accountViewShown) {
                AccountSheetView(filter: filterPlatformName)
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
