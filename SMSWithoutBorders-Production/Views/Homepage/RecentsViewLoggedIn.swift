//
//  RecentsViewLoggedIn.swift
//  SMSWithoutBorders-Production
//
//  Created by MAC on 17/02/2025.
//

import SwiftUI


struct NoSentMessages: View {
    var body: some View {
        VStack {
            Spacer()
            
            VStack {
                Image("NoRecents")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 200)
                    .padding(.bottom, 20)
                Text("No recent messages")
            }
            
            Spacer()

            VStack {
                Button {
                } label: {
                    Text("Send new message")
                        .bold()
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.bottom, 10)
                
                Button {
                } label: {
                    Text("Save platforms")
                        .bold()
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                
            }
            .padding()
            .padding(.bottom, 32)
            .background(
                Group {
//                    NavigationLink(
//                        destination: OfflineAvailablePlatformsSheetsView(),
//                        isActive: $showComposePlatforms) {
//                            EmptyView()
//                        }
//
//                    NavigationLink(destination: OnlineAvailablePlatformsSheetsView(
//                        codeVerifier: $codeVerifier), isActive: $showAvailablePlatforms) {
//                            EmptyView()
//                    }
                }.hidden()
            )
        }
    }
}

struct RecentsViewLoggedIn: View {
    var body: some View {
        NavigationView {
            VStack {
                NoSentMessages()
            }
            .navigationTitle("Recents")
        }
    }
}

#Preview {
    RecentsViewLoggedIn()
}

#Preview {
    NoSentMessages()
}
