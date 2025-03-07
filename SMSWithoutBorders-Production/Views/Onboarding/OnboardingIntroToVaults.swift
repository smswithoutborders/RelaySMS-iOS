//
//  OnboardingIntroToVaults.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 13/06/2024.
//

import SwiftUI

struct OnboardingIntroToVaults: View {
    @Binding var pageIndex: Int
    
    var body: some View {
        VStack {
            PreviousAndSkipButton(pageIndex: $pageIndex)
            Spacer()
            
            VStack {
                Spacer()
                
                Image("2")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 300, height: 300)
                    .padding()
                
                Text(String(localized:"RelaySMS Vaults securely stores your online accounts, so that you can access them without an internet connection", comment: "Explains that your online platforms are stored securely"))
                    .font(RelayTypography.titleLarge)
                    .padding(.bottom, 30)
                    .multilineTextAlignment(.center)
                
            }.padding([.leading, .trailing], 16)
            
            Spacer()
            
            Button {
                pageIndex += 1
            } label: {
                Image(systemName: "arrow.right")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .clipShape(.circle).padding(.bottom, 24)
        }
    }
}


#Preview {
    @State var pageIndex = 0
    OnboardingIntroToVaults(pageIndex: $pageIndex)
}


