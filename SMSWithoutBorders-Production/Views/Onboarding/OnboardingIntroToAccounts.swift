//
//  OnboardingIntroToAccounts.swift
//  SMSWithoutBorders-Production
//
//  Created by MAC on 28/02/2025.
//

import SwiftUI

struct OnboardingIntroToAccounts: View {
    @Binding var pageIndex: Int
    
    var body: some View {
        VStack {
            PreviousAndSkipButton(pageIndex: $pageIndex)
            Spacer()
            VStack {
                Image("3")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 300, height: 300)
                    .padding()
                
                Text("You can add online accounts to your Vault")
                    .font(Font.custom("unbounded", size: 18)).fontWeight(.medium)
                    .padding(.bottom, 10)
                    .multilineTextAlignment(.center)
            }.padding()
            
            Spacer().frame(maxHeight: 24)

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
            .clipShape(.circle)
            .padding(.bottom, 24)
        }
    }
}

#Preview {
    @State var pageIndex = 0
    OnboardingIntroToAccounts(pageIndex: $pageIndex)
}
