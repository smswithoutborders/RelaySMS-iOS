//
//  Recents1.swift
//  SMSWithoutBorders-Production
//
//  Created by MAC on 21/01/2025.
//

import SwiftUI

struct CreateAccountSheetView: View {
    var body: some View {
        VStack {
            Image(systemName: "person.crop.circle.badge.plus")
                .resizable()
                .scaledToFit()
                .frame(width: 75, height: 75)
            
            Text("This is a brief summary of what happens")
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding()
            
            Text("This is precise information for what happens")
            
            Button(action: {}) {
                Text("Continue")
            }
            .buttonStyle(.bordered)
            .tint(.accentColor)
            .padding()
        }
    }
}

struct SendFirstMessageView: View {
    var body: some View {
        VStack {
            Text("Your phone number is your primary account!")
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        HStack(spacing: 50) {
            Button(action: {}) {
                VStack {
                    Image(systemName: "pencil.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 75, height: 75)
                        .padding(.bottom)
                    Text("Send your first message!")
                        .font(.footnote)
                        .foregroundColor(.primary)
                }
                .padding()
            }
            .buttonStyle(.bordered)
            .tint(.accentColor)
        }
        .padding()
        
    }
}

struct LoginWithInternetView : View {
    var body: some View {
        VStack {
            Text("Login with internet")
                .font(.headline)
            Text("These features requires you to have an internet connection")
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        HStack(spacing: 50) {
            Button(action: {
//                sheetCreateAccountIsPresented.toggle()
            }) {
                VStack {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 75, height: 75)
                    Text("Create Account")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
            .buttonStyle(.bordered)
            .tint(.accentColor)
//            .sheet(isPresented: $sheetCreateAccountIsPresented) {
//                CreateAccountSheetView()
//                    .applyPresentationDetentsIfAvailable()
//            }

            Button(action: {}) {
                VStack {
                    Image(systemName: "person.crop.circle.badge")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 75, height: 75)
                    Text("Log in")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
            .buttonStyle(.bordered)
            .tint(.accentColor)
        }
        .padding()
    }
}

struct WalkthroughViews: View {
    var body: some View {
        VStack {
            Text("Having trouble using the app?")
                .font(.headline)
            Text("Check out our step-by-step guide")
                .font(.caption)
                .multilineTextAlignment(.center)
        }

        HStack {
            Button(action: {}) {
                VStack {
                    Image("learn1")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 75, height: 75)
                        .padding()
                    Text("Messaging with your RelaySMS account")
                        .font(.caption2)
                        .foregroundColor(.accentColor)
                }
                .padding()
            }
            .buttonStyle(.bordered)
            .tint(.accentColor)
            .padding(.top)
            
            Button(action: {}) {
                VStack {
                    Image("learn1")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 75, height: 75)
                        .padding()
                    Text("Messaging with your personal accounts")
                        .font(.caption2)
                        .foregroundColor(.accentColor)
                }
                .padding()
            }
            .buttonStyle(.bordered)
            .tint(.accentColor)
            .padding(.top)
            
        }
        HStack {
            Button(action: {}) {
                VStack {
                    Image("learn1")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 75, height: 75)
                        .padding()
                    Text("Choosing a country for routing your messages")
                        .font(.caption2)
                        .foregroundColor(.accentColor)
                }
                .padding()
            }
            .buttonStyle(.bordered)
            .tint(.accentColor)
            .padding(.top)
        }
    }
}

struct Recents1: View {
    @State private var sheetCreateAccountIsPresented: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                ScrollView {
                    VStack(spacing: 10) {
                        SendFirstMessageView()

                        Divider()
                            .padding(.bottom, 16)
                        
                        LoginWithInternetView()

                        Divider()
                            .padding(.bottom, 16)

                        WalkthroughViews()
                    }
                    .navigationTitle("Get Started")
                    .padding()
                }
            }
        }
    }
}

#Preview {
    Recents1()
}
