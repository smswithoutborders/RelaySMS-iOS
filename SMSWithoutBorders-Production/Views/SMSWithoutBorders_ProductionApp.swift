//
//  SMSWithoutBorders_ProductionApp.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/5/22.
//

import SwiftUI
import Foundation
import CoreData

func downloadAndSaveIcons(url: URL, 
                          platform: Publisher.PlatformsData,
                          viewContext: NSManagedObjectContext) {
    print("Storing Platform Icon: \(platform.name)")
    let task = URLSession.shared.dataTask(with: url) { data, response, error in
        guard let data = data, error == nil else { return }
        
        let platformsEntity = PlatformsEntity(context: viewContext)
        platformsEntity.image = data
        platformsEntity.name = platform.name
        platformsEntity.protocol_type = platform.protocol_type
        platformsEntity.service_type = platform.service_type
        platformsEntity.shortcode = platform.shortcode
        platformsEntity.support_url_scheme = platform.support_url_scheme
        do {
            try viewContext.save()
        } catch {
            print("Failed save download image: \(error)")
        }
    }
    task.resume()
}

struct ControllerView: View {
    @Environment(\.managedObjectContext) var viewContext
    @Binding var isFinished: Bool
    
    @Binding var onboardingViewIndex: Int
    @State private var lastOnboardingView = false
    
    @Binding var codeVerifier: String
    @Binding var backgroundLoading: Bool

    @FetchRequest(sortDescriptors: []) var storedPlatforms: FetchedResults<StoredPlatformsEntity>
    
    @State var onboardingCompleted: Bool = false
    
    @Environment(\.dismiss) var dismiss

    var body: some View {
        Group {
            switch onboardingViewIndex {
            case ...0:
                OnboardingWelcomeView()
                VStack {
                    Button("Get started!") {
                        self.onboardingViewIndex = storedPlatforms.isEmpty ? 1 : 2
                        Task {
                            do {
                                try refreshLocalDBs()
                            } catch {
                                print("Failed to refresh local DBs: \(error)")
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                    Link("Read our privacy policy", destination: URL(string:"https://smswithoutborders.com/privacy-policy")!)
                        .font(.caption)
                }
            case 1:
                OnboardingIntroToVaults(codeVerifier: $codeVerifier,
                                        backgroundLoading: $backgroundLoading,
                                        complete: $onboardingCompleted)
            case 2:
                OnboardingTryExample()
            default:
                OnboardingFinish(isFinished: $lastOnboardingView)
            }
            
            if(!backgroundLoading) {
                HStack {
                    if(self.onboardingViewIndex > 0) {
                        if(!lastOnboardingView) {
                            Button("skip") {
                                self.onboardingViewIndex = 3
                            }.frame(alignment: .bottom)
                                .padding()
                        } else {
                            Button("Finish") {
                                isFinished = true
                            }.buttonStyle(.borderedProminent)
                                .padding()
                        }
                    }
                    
                }.padding()
            }
            
        }.task {
            
        }
    }
    
    func refreshLocalDBs() throws {
        DispatchQueue.background(background: {
            Publisher.getPlatforms() { result in
                switch result {
                case .success(let data):
                    print("Success: \(data)")
                    for platform in data {
                        if(ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1") {
                            downloadAndSaveIcons(
                                url: URL(string: platform.icon_png)!,
                                platform: platform,
                                viewContext: viewContext)
                        }
                    }
                case .failure(let error):
                    print("Failed to load JSON data: \(error)")
                }
            }
        }, completion: {
            
        })
    }
}


@main
struct SMSWithoutBorders_ProductionApp: App {
    @StateObject private var dataController = DataController()

    @State var isFinished = false
    @State var navigatingFromURL: Bool = false
    @State var absoluteURLString: String = ""
    @State var codeVerifier: String = ""
    
    @State var backgroundLoading: Bool = false
    @State private var onboardingViewIndex: Int = 0
    
    @AppStorage(GatewayClients.DEFAULT_GATEWAY_CLIENT_MSISDN)
    private var defaultGatewayClientMsisdn: String = ""

    var body: some Scene {
        WindowGroup {
            Group {
                if(!isFinished) {
                    ControllerView(isFinished: $isFinished,
                                   onboardingViewIndex: $onboardingViewIndex,
                                   codeVerifier: $codeVerifier,
                                   backgroundLoading: $backgroundLoading)
                    .environment(\.managedObjectContext, dataController.container.viewContext)
                    .task {
                    }
                }
                else {
                    HomepageView(codeVerifier: $codeVerifier, isLoggedIn: getIsLoggedIn())
                        .environment(\.managedObjectContext, dataController.container.viewContext)
                        
                }
            }
            .task {
                Task {
                    let gatewayClient = GatewayClients.addDefaultGatewayClients(
                        context: dataController.container.viewContext,
                        defaultAvailable: !defaultGatewayClientMsisdn.isEmpty)
                    print("GatewayClient: \(gatewayClient)")
                    if gatewayClient != nil {
                        UserDefaults.standard.register(defaults: [
                            GatewayClients.DEFAULT_GATEWAY_CLIENT_MSISDN: gatewayClient!.msisdn
                        ])
                    }
                    
                }
            }
            .onOpenURL { url in
                let stateB64Values = url.valueOf("state")
                // Decode the Base64 string to Data
                guard let decodedData = Data(base64Encoded: stateB64Values!) else {
                    fatalError("Failed to decode Base64 string")
                }

                // Convert Data to String
                guard let decodedString = String(data: decodedData, encoding: .utf8) else {
                    fatalError("Failed to convert Data to String")
                }
                
                print("decoded string: \(decodedString)")
                let values = decodedString.split(separator: ",")
                let state = values[0]
                let supportsUrlScheme = values[1] == "true"
                
                let code = url.valueOf("code")
                print("state: \(state)\ncode: \(code)\ncodeVerifier: \(codeVerifier)")
                
                do {
                    let llt = try Vault.getLongLivedToken()
                    let publisher = Publisher()
                    
                    backgroundLoading = true
                    
                    print("support url scheme: \(supportsUrlScheme)")
                    
                    let response = try publisher.sendOAuthAuthorizationCode(
                        llt: llt,
                        platform: String(state),
                        code: code!,
                        codeVerifier: codeVerifier,
                        supportsUrlSchemes: supportsUrlScheme)
                    
                    if(response.success) {
                        onboardingViewIndex += 1
                        Task {
                            try Vault().refreshStoredTokens(llt: llt, context: dataController.container.viewContext)
                        }
                    }
                } catch {
                    print("An error occured sending code: \(error)")
                }
                backgroundLoading = false
            }
        }
    }

    func getIsLoggedIn() -> Bool {
        do {
            return try !Vault.getLongLivedToken().isEmpty
        } catch {
            print("Failed to check if llt exist: \(error)")
        }
        return false
    }
    
}

#Preview {
    @State var isFinished = false
    @State var codeVerifier = ""
    @State var onboardingIndex = 0
    @State var isBackgroundLoading: Bool = true
    
    ControllerView(isFinished: $isFinished,
                   onboardingViewIndex: $onboardingIndex,
                   codeVerifier: $codeVerifier,
                   backgroundLoading: $isBackgroundLoading)
}
