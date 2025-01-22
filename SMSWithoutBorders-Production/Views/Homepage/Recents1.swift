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
            .tint(.primary)
            .padding()
        }
    }
}

struct SendFirstMessageView: View {
    @Binding var sheetCreateAccountIsPresented: Bool
    
    var body: some View {
        HStack(spacing: 50) {
            Button(action: {
                sheetCreateAccountIsPresented.toggle()
            }) {
                VStack {
                    Image(systemName: "pencil.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 75, height: 75)
                        .padding(.bottom)
                    Text("Compose new message")
                        .font(.footnote)
                }
                .padding()
            }
            .buttonStyle(.bordered)
            .tint(Color("PrimaryColor"))
            .sheet(isPresented: $sheetCreateAccountIsPresented) {
            }
        }
        VStack {
            Text("Your phone number is your primary account!")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(Color("SecondaryColor"))
            Text("your_phonenumber@relaysms.me")
                .font(.caption2)
        }

    }
}

struct LoginWithInternetView : View {
    @Binding var sheetCreateAccountIsPresented: Bool

    var body: some View {
        VStack {
            Text("Login with internet")
                .font(.headline)
            Text("These features requires you to have an internet connection")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(Color("SecondaryColor"))
        }
        HStack(spacing: 50) {
            Button(action: {
                sheetCreateAccountIsPresented.toggle()
            }) {
                VStack {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 75, height: 75)
                    Text("Create Account")
                        .font(.caption)
                }
            }
            .sheet(isPresented: $sheetCreateAccountIsPresented) {
                CreateAccountSheetView()
                    .applyPresentationDetentsIfAvailable()
            }
            .buttonStyle(.bordered)
            .tint(Color("PrimaryColor"))
            
            Button(action: {
                sheetCreateAccountIsPresented.toggle()
            }) {
                VStack {
                    Image(systemName: "person.crop.circle.badge")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 75, height: 75)
                    Text("Log in")
                        .font(.caption)
                }
            }
            .sheet(isPresented: $sheetCreateAccountIsPresented) {
                CreateAccountSheetView()
                    .applyPresentationDetentsIfAvailable()
            }
            .buttonStyle(.bordered)
            .tint(Color("PrimaryColor"))
        }
        .padding()
    }
}

struct WalkthroughViews: View {
    @Binding var sheetCreateAccountIsPresented: Bool

    var body: some View {
        VStack {
            Text("Having trouble using the app?")
                .font(.headline)
                .foregroundColor(Color("SecondaryColor"))
            Text("Check out our step-by-step guide")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(Color("SecondaryColor"))
        }

        HStack {
            Button(action: {
                sheetCreateAccountIsPresented.toggle()
            }) {
                ZStack {
                    VStack {
                        Image("learn1")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 75, height: 75)
                            .padding()
                        Text("Messaging with your RelaySMS account")
                            .font(.caption2)
                    }
                    .padding()
                    
                    Image(systemName: "info.circle")
                        .offset(x: 55, y: -70)
                }
            }
            .buttonStyle(.bordered)
            .tint(Color("SecondaryColor"))
            .padding(.top)
            .sheet(isPresented: $sheetCreateAccountIsPresented) {
            }

            Button(action: {
                sheetCreateAccountIsPresented.toggle()
            }) {
                ZStack {
                    VStack {
                        Image("learn1")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 75, height: 75)
                            .padding()
                        Text("Messaging with your personal accounts")
                            .font(.caption2)
                    }
                    .padding()
                    
                    Image(systemName: "info.circle")
                        .offset(x: 55, y: -70)
                }
            }
            .buttonStyle(.bordered)
            .tint(Color("SecondaryColor"))
            .padding(.top)
            .sheet(isPresented: $sheetCreateAccountIsPresented) {
            }

        }
        HStack {
            Button(action: {
                sheetCreateAccountIsPresented.toggle()
            }) {
                ZStack {
                    VStack {
                        Image("learn1")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 75, height: 75)
                            .padding()
                        Text("Choosing a country for routing your messages")
                            .font(.caption2)
                    }
                    .padding()
                    
                    Image(systemName: "info.circle")
                        .offset(x: 120, y: -60)
                }
            }
            .buttonStyle(.bordered)
            .tint(Color("SecondaryColor"))
            .padding(.top)
            .sheet(isPresented: $sheetCreateAccountIsPresented) {
            }
        }
    }
}

struct Recents1: View {
    @State var sendFirstMessageViewShown: Bool = false
    @State var loginWithInternetViewShown: Bool = false
    @State var walkthroughViewsShown: Bool = false
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 10) {
                    SendFirstMessageView(sheetCreateAccountIsPresented: $sendFirstMessageViewShown)

                    Divider()
                        .padding(.bottom, 16)
                    
                    LoginWithInternetView(sheetCreateAccountIsPresented: $loginWithInternetViewShown)
                        .padding(.bottom)

                    WalkthroughViews(sheetCreateAccountIsPresented: $walkthroughViewsShown)
                }
                .navigationTitle("Get Started")
                .padding()
            }
        }
    }
}

#Preview {
    Recents1()
}
