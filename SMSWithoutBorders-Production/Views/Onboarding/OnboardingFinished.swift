//
//  OnboardingFinished.swift
//  SMSWithoutBorders-Production
//
//  Created by MAC on 28/02/2025.
//

import SwiftUI

struct OnboardingFinished: View {
    @Binding var pageIndex: Int
    
    var body: some View {
    
        VStack {
            PreviousAndSkipButton(pageIndex: $pageIndex)
            Spacer()
            
            VStack {
                Image("4")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 300, height: 300)
                    .padding()
                
                Text("You are ready to begin sending messages from RelaySMS!")
                    .font(Font.custom("unbounded", size: 18))
                    .padding(.bottom, 30)
                    .multilineTextAlignment(.center)

            }.padding()
            
            Spacer().frame(height: 100)
            
            Button {
                UserDefaults.standard.set(true, forKey: OnboardingView.ONBOARDING_COMPLETED)
            } label: {
                Text("Great!")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .clipShape(.capsule)
            .padding([.leading, .trailing], 16)
            .padding(.bottom, 24)
        }
    }
}

#Preview {
    @State var pageIndex = 0
    OnboardingFinished(pageIndex: $pageIndex)
}
