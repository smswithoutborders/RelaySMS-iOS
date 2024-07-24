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
    @Binding var isFinished: Bool
    
    @Binding var onboadingViewIndex: Int
    @State private var lastOnboardingView = false
    
    @Binding var codeVerifier: String
    @Binding var backgroundLoading: Bool
    
    @FetchRequest(sortDescriptors: []) var platforms: FetchedResults<PlatformsEntity>

    var body: some View {
        switch self.onboadingViewIndex {
        case ...0:
            OnboardingWelcomeView()
            VStack {
                Button("Get started!") {
                    self.onboadingViewIndex += platforms.isEmpty ? 1 : 2
                }
                .buttonStyle(.borderedProminent)
                .padding()
                Link("Read our privacy policy", destination: URL(string:"https://smswithoutborders.com/privacy-policy")!)
                    .font(.caption)
            }
        case 1:
            OnboardingIntroToVaults(codeVerifier: $codeVerifier,
                                    backgroundLoading: $backgroundLoading)
        case 2:
            OnboardingTryExample()
        default:
            OnboardingFinish(isFinished: $lastOnboardingView)
        }
        
        if(!backgroundLoading) {
            HStack {
                if(self.onboadingViewIndex > 0) {
                    if(!lastOnboardingView) {
                        Button("skip") {
                            self.onboadingViewIndex += 1
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
    
    var body: some Scene {
        WindowGroup {
            Group {
                if(!isFinished) {
                    ControllerView(isFinished: $isFinished,
                                   onboadingViewIndex: $onboardingViewIndex,
                                   codeVerifier: $codeVerifier,
                                   backgroundLoading: $backgroundLoading)
                    .environment(\.managedObjectContext, dataController.container.viewContext)
                }
                else {
                    RecentsView(codeVerifier: $codeVerifier)
                        .environment(\.managedObjectContext, dataController.container.viewContext)
                }
            }
            .task {
                Publisher.getPlatforms() { result in
                    switch result {
                    case .success(let data):
                        print("Success: \(data)")
                        for platform in data {
                            if(ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1") {
                                downloadAndSaveIcons(url: URL(string: platform.icon_png)!, platform: platform)
                            }
                        }
                    case .failure(let error):
                        print("Failed to load JSON data: \(error)")
                    }
                }
            }
            .onOpenURL { url in
                let state = url.valueOf("state")
                let code = url.valueOf("code")
                print("state: \(state)\ncode: \(code)\ncodeVerifier: \(codeVerifier)")
                
                do {
                    let llt = try Vault.getLongLivedToken()
                    let publisher = Publisher()
                    
                    backgroundLoading = true
                    
                    let response = try publisher.sendAuthorizationCode(
                        llt: llt,
                        platform: state!,
                        code: code!,
                        codeVerifier: codeVerifier)
                    
                    if(response.success) {
                        onboardingViewIndex += 1
                        Task {
                            Vault().refreshStoredTokens(llt: llt, context: dataController.container.viewContext)
                        }
                    }
                } catch {
                    print("An error occured sending code: \(error)")
                }
                backgroundLoading = false
            }
        }
    }
    
    
    
    private func downloadAndSaveIcons(url: URL, platform: Publisher.PlatformsData) {
        print("Storing Platform Icon: \(platform.name)")
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else { return }
            
            let context = dataController.container.viewContext
            let platformsEntity = PlatformsEntity(context: context)
            platformsEntity.image = data
            platformsEntity.name = platform.name
            platformsEntity.protocol_type = platform.protocol_type
            platformsEntity.service_type = platform.service_type
            platformsEntity.shortcode = platform.shortcode
            do {
                try context.save()
            } catch {
                print("Failed save download image: \(error)")
            }
        }
        task.resume()
    }
}

#Preview {
    @State var isFinished = false
    @State var codeVerifier = ""
    @State var onboardingIndex = 0
    @State var isBackgroundLoading: Bool = true
    
    ControllerView(isFinished: $isFinished,
                   onboadingViewIndex: $onboardingIndex,
                   codeVerifier: $codeVerifier,
                   backgroundLoading: $isBackgroundLoading)
}
