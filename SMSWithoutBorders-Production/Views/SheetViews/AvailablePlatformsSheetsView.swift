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
    @State var title: String = "Compose for platform"
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
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "name", ascending: false, selector: #selector(NSString.localizedStandardCompare))])
    var storedPlatforms: FetchedResults<StoredPlatformsEntity>
    
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
        VStack(alignment: .leading) {
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
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Button {
                        loadingOAuthURLScreen.toggle()
                        DispatchQueue.background(background: {
                            do {
                                let vault = Vault()
                                let llt = try Vault.getLongLivedToken()
                                try vault.refreshStoredTokens(
                                    llt: llt,
                                    context: viewContext)
                            } catch {
                                print(error.localizedDescription)
                            }
                        }, completion: {
                            loadingOAuthURLScreen.toggle()
                        })
                    } label: {
                        Image(systemName: "arrow.clockwise.circle")
                    }.padding()

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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    
    func getStoredPlatforms(platform: PlatformsEntity) -> Bool {
        print("checking against: \(platform.name) : \(platform.service_type)")
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
                    accountViewShown.toggle()
                    print("changed accountViewShown: \(accountViewShown)")
                }
            }) {
                (platform.image == nil ? Image("Logo") : Image(uiImage: UIImage(data: platform.image!)!))
                    .resizable()
                    .frame(width: 50, height: 50)
            }
            .background(
                NavigationLink(destination: AccountSheetView(
                    filter: filterPlatformName,
                    globalDismiss: $accountViewShown,
                    isRevoke: type == AvailablePlatformsSheetsView.TYPE.REVOKE), isActive: $accountViewShown) {
                        EmptyView()
                    }.hidden()
            )
            .sheet(isPresented: $showPhonenumberView) {
                PhoneNumberSheetView(platformName: phonenumberViewPlatform)
            }
            .padding(.horizontal, 20)
            
            VStack(alignment: .leading) {
                Text(platform.name!)
                    .bold()
                
                Text(platform.protocol_type!)
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
                DispatchQueue.main.async {
                    dismiss()
                }
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
        @State var isRevoke: Bool = true

        let container = createInMemoryPersistentContainer()
        populateMockData(container: container)
        
        return OfflineAvailablePlatformsSheetsView(
            codeVerifier: codeVerifier, isRevoke: isRevoke)
        .environment(\.managedObjectContext, container.viewContext)
    }
}
