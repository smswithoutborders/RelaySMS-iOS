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
            Spacer()
            
            VStack {
                Image("4")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 300, height: 300)
                    .padding()
                
                Text("You are ready to begin sending messages from RelaySMS!")
                    .font(.title2)
                    .padding(.bottom, 30)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)

            }.padding()
            
            Spacer()
            
            Button {
                
            } label: {
                Text("Great!")
                    .frame(maxWidth: .infinity)
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
    OnboardingFinished(pageIndex: $pageIndex)
}
