//
//  OnboardingIntroToVaults.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 13/06/2024.
//

import SwiftUI

struct Tab<ButtonView: View>: View {
    let buttonView: ButtonView
    @State var title: String = "Let's get you started"
    @State var subTitle: String
    @State var description: String
    @State var imageName: String
    @State var subDescription: String
    

    var body: some View {
        Text(title)
            .font(.title)
            .fontWeight(.semibold)
        
        Text(subTitle)
            .font(.subheadline)
            .fontWeight(.semibold)

        Spacer()
            
        VStack {
            Text(description)
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.bottom, 60)


            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 200, height: 200)
            
            Text(subDescription)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding(.bottom, 30)
                .padding()
            
            self.buttonView

        }.padding()
        
        Spacer()
    }
    
}

struct OnboardingIntroToVaults: View {
    @State var currentTab = "intro"
    
    var body: some View {
        TabView(selection: $currentTab) {
            VStack {
                Tab(buttonView:
                    Group {
                        Button("Login") {
                            
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Create new") {
                            
                        }
                        .buttonStyle(.borderedProminent)
                    }, 
                    title:"Let's get you started",
                    subTitle: "Introducing Vaults",
                    description: "RelaySMS Vaults keep secure access to your online accounts while you are offline",
                    imageName: "OnboardingVault",
                    subDescription: "Create a new RelaySMS Vault account or signup to your existing."
                )
            }
            .tag("intro")
            
            VStack {
                Tab(buttonView:
                    Button("Add Accounts") {
                        
                    }.buttonStyle(.borderedProminent),
                    subTitle: "Add Accounts to Vault",
                    description: "You can add accounts your Vault. This accounts are accessible to you when you are offline",
                    imageName: "OnboardingVaultOpen",
                    subDescription: "The Vault supports storing for multiple online paltforms. Click Add Accounts storage to see the list"
                )
            }
            .tag("example-store")
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
    }
}

#Preview {
    OnboardingIntroToVaults(currentTab: "example-store")
}
