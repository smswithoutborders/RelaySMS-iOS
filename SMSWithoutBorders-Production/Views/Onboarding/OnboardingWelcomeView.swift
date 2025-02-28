//
//  SwiftUIView.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 13/06/2024.
//

import SwiftUI

struct OnboardingWelcomeView: View {
    @Binding var pageIndex: Int
    
    var body: some View {
        VStack {
            Text("Welcome to RelaySMS!")
                .font(.title)
                .fontWeight(.semibold)
                .padding(.top, 40)
                
                
            VStack {
                Image("1")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 300, height: 300)
                    .padding()
                
                Button("English", systemImage: "globe") {
                    
                }
                .buttonStyle(.borderedProminent)
                .tint(.secondary)
                .cornerRadius(38.5)
                .padding()

                Text("Use SMS to make a post, send emails and messages with no internet connection")
                    .font(.title2)
                    .padding(.bottom, 30)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                

            }.padding()
            
            Button {
                pageIndex += 1
            } label: {
                Text("Learn how it works")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding()

            Button {
                
            } label: {
                Text("Read our privacy policy")
            }
        }
    }
}

#Preview {
    @State var pageIndex = 0
    OnboardingWelcomeView(pageIndex: $pageIndex)
}
