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
            Spacer()
            VStack {
                Image("3")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 300, height: 300)
                    .padding()
                
                Text("You can add online accounts to your Vault")
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
    OnboardingIntroToAccounts(pageIndex: $pageIndex)
}
