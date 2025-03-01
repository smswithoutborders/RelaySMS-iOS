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
            Spacer()
            
            VStack {
                Image("2")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 300, height: 300)
                    .padding()
                
                Text(String(localized:"RelaySMS Vaults securely stores your online accounts, so that you can access them without an internet connection", comment: "Explains that your online platforms are stored securely"))
                    .font(.title2)
                    .padding(.bottom, 30)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                

            }.padding()
            
            Spacer()

            Button {
                pageIndex += 1
            } label: {
                Image(systemName: "arrow.right")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 30)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .cornerRadius(100)
            .padding()
        }
    }
}


#Preview {
    @State var pageIndex = 0
    OnboardingIntroToVaults(pageIndex: $pageIndex)
}
