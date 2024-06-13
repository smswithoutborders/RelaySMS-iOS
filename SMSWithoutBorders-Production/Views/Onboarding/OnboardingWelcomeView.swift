//
//  SwiftUIView.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 13/06/2024.
//

import SwiftUI

struct OnboardingWelcomeView: View {
    var body: some View {
        VStack {
            Text("Welcome to RelaySMS")
                .font(.title)
                .fontWeight(.semibold)
            
            Spacer()
            
            VStack {
                Text("Send Emails, Tweets and Messages using RelaySMS") .multilineTextAlignment(.center)
                
                Image("OnboardingWelcome")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 200)
                

                Button("English", systemImage: "globe") {
                    
                }
                .buttonStyle(.borderedProminent)
                
            }
            
            
            Spacer()
            VStack {
                Button("Get started!", systemImage: "arrow.right") {
                    
                }
                .buttonStyle(.borderedProminent)
                .padding()
                Button("Read our privacy policy"){}
                    .font(.caption)
            }
        }
    }
}

#Preview {
    OnboardingWelcomeView()
}
