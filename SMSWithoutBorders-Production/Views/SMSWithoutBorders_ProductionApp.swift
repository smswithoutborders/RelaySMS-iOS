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
        
        DispatchQueue.main.async {
            do {
                try viewContext.save()
            } catch {
                print("Failed save download image: \(error) \(error.localizedDescription)")
            }
        }
    }
    task.resume()
}

struct ControllerView: View {
    public static var ONBOARDING_COMPLETED: String = "com.afkanerd.relaysms.ONBOARDING_COMPLETED"
    
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
                    Button {
                        self.onboardingViewIndex = storedPlatforms.isEmpty ? 1 : 2
                        DispatchQueue.background(background: {
                            do {
                                try refreshLocalDBs()
                                print("Finished refreshing local db")
                            } catch {
                                print("Failed to refresh local DBs: \(error)")
                            }
                        }, completion: {
                            
                        })
                    } label: {
                        Text("Get started!")
                            .bold()
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.bottom, 10)
                    
                    Link("Read our privacy policy", destination: URL(string:"https://smswithoutborders.com/privacy-policy")!)
                        .font(.caption)
                }
                .padding()
            case 1:
                OnboardingIntroToVaults(codeVerifier: $codeVerifier,
                                        backgroundLoading: $backgroundLoading,
                                        onboardingIndex: $onboardingViewIndex)
            case 2:
                OnboardingTryExample()
            default:
                OnboardingFinish(lastOnboardingView: $lastOnboardingView)
            }
            
            if(!backgroundLoading) {
                HStack {
                    if(self.onboardingViewIndex > 0) {
                        if(!lastOnboardingView) {
                            Button("skip") {
                                self.onboardingViewIndex = 3
                            }
                            .padding()
                            .frame(alignment: .bottom)
                        } else {
                            Button {
                                isFinished = true
                                UserDefaults.standard.set(true, forKey: ControllerView.ONBOARDING_COMPLETED)
                            } label: {
                                Text("Finish!")
                                    .bold()
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .padding(.bottom, 10)
                        }
                    }
                    
                }.padding()
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
    
    @AppStorage(ControllerView.ONBOARDING_COMPLETED)
    private var onboardingCompleted: Bool = false

    var body: some Scene {
        WindowGroup {
            Group {
                if(!isFinished && !onboardingCompleted) {
                    ControllerView(isFinished: $isFinished,
                                   onboardingViewIndex: $onboardingViewIndex,
                                   codeVerifier: $codeVerifier,
                                   backgroundLoading: $backgroundLoading)
                    .environment(\.managedObjectContext, dataController.container.viewContext)
                }
                else {
                    HomepageView(codeVerifier: $codeVerifier, isLoggedIn: getIsLoggedIn())
                        .environment(\.managedObjectContext, dataController.container.viewContext)
                        
                }
            }
            .task {
                GatewayClients.addDefaultGatewayClients(
                    context: dataController.container.viewContext,
                    defaultAvailable: !defaultGatewayClientMsisdn.isEmpty)
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

struct SMSWithoutBorders_ProductionApp_Preview: PreviewProvider {
    @State static var platform: PlatformsEntity?
    @State static var platformType: Int?
    @State static var codeVerifier: String = ""

    static var previews: some View {
        @State var isFinished = false
        @State var codeVerifier = ""
        @State var onboardingIndex = 0
        @State var isBackgroundLoading: Bool = true
        
        ControllerView(isFinished: $isFinished,
                       onboardingViewIndex: $onboardingIndex,
                       codeVerifier: $codeVerifier,
                       backgroundLoading: $isBackgroundLoading)
    }
}
