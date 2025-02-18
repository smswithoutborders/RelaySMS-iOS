//
//  SMSWithoutBorders_ProductionApp.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/5/22.
//

import SwiftUI
import Foundation
import CoreData

struct ControllerView: View {
    public static var ONBOARDING_COMPLETED: String = "com.afkanerd.relaysms.ONBOARDING_COMPLETED"
    
    @Environment(\.managedObjectContext) var viewContext
    @Binding var isFinished: Bool
    
    @Binding var onboardingViewIndex: Int
    @State private var lastOnboardingView = false
    
    @Binding var codeVerifier: String
    @Binding var backgroundLoading: Bool
    @Binding var isLoggedIn: Bool

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
                                        onboardingIndex: $onboardingViewIndex,
                                        isLoggedIn: $isLoggedIn)
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
}


@main
struct SMSWithoutBorders_ProductionApp: App {
    @Environment(\.scenePhase) var scenePhase
    @StateObject private var dataController = DataController()

    @State var isFinished = false
    @State var navigatingFromURL: Bool = false
    @State var absoluteURLString: String = ""
    @State var codeVerifier: String = ""
    
    @State var backgroundLoading: Bool = false
    @State private var onboardingViewIndex: Int = 0
    
//    @AppStorage(GatewayClients.DEFAULT_GATEWAY_CLIENT_MSISDN)
    private var defaultGatewayClientMsisdn: String = UserDefaults.standard.string(forKey: GatewayClients.DEFAULT_GATEWAY_CLIENT_MSISDN) ?? ""
    
//    @AppStorage(ControllerView.ONBOARDING_COMPLETED)
    private var onboardingCompleted: Bool = UserDefaults.standard.bool(forKey: ControllerView.ONBOARDING_COMPLETED)
    
    @State private var alreadyLoggedIn: Bool = false
    @State private var isLoggedIn: Bool = false

    var body: some Scene {
        WindowGroup {
            Group {
                if(!isFinished && !onboardingCompleted) {
                    ControllerView(isFinished: $isFinished,
                                   onboardingViewIndex: $onboardingViewIndex,
                                   codeVerifier: $codeVerifier,
                                   backgroundLoading: $backgroundLoading,
                                   isLoggedIn: $isLoggedIn)
                    .environment(\.managedObjectContext, dataController.container.viewContext)
                }
                else {
                    HomepageView(codeVerifier: $codeVerifier)
                        .environment(\.managedObjectContext, dataController.container.viewContext)
                        .alert("You are being logged out!", isPresented: $alreadyLoggedIn) {
                            Button("Get me out!") {
                                getMeOut()
                            }
                        } message: {
                            Text("It seems you logged into another device. You can use RelaySMS on only one device at a time.")
                        }
                        .onAppear() {
                            validateLLT()
                        }
                        .onChange(of: scenePhase) { newPhase in
                            if newPhase == .active {
                                validateLLT()
                            }
                        }
                }
            }
            .onAppear {
                Publisher.refreshPlatforms(context: dataController.container.viewContext)
            }
            .onOpenURL { url in
                processIncomingUrls(url: url)
            }
        }
    }
    
    func processIncomingUrls(url: URL) {
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
        if(code == nil) {
            return
        }
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
                try Vault().refreshStoredTokens(llt: llt, context: dataController.container.viewContext)
            }
        } catch {
            print("An error occured sending code: \(error)")
        }
        backgroundLoading = false
    }
    
    func getMeOut() {
        logoutAccount(context: dataController.container.viewContext)
        isLoggedIn = false
    }
    
    func validateLLT() {
        print("Validating LLT for continuation...")
        DispatchQueue.background(background: {
            do {
                let vault = Vault()
                let llt = try Vault.getLongLivedToken()
                if llt.isEmpty{
                    return
                }
                
                let result = try vault.validateLLT(llt: llt,
                                  context: dataController.container.viewContext)
                if !result {
                    alreadyLoggedIn = true
                }
            } catch {
                print(error)
            }
        }, completion: {
            
        })
    }

    func getIsLoggedIn() -> Bool {
        do {
            isLoggedIn = try !Vault.getLongLivedToken().isEmpty
        } catch {
            print("Failed to check if llt exist: \(error)")
        }
        return false
    }
    
}

#Preview {
    @State var codeVerifier = ""
    @State var isLoggedIn = false
    return HomepageView(codeVerifier: $codeVerifier)
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
        @State var isLoggedIn: Bool = false

        ControllerView(isFinished: $isFinished,
                       onboardingViewIndex: $onboardingIndex,
                       codeVerifier: $codeVerifier,
                       backgroundLoading: $isBackgroundLoading,
                       isLoggedIn: $isLoggedIn)
    }
}
