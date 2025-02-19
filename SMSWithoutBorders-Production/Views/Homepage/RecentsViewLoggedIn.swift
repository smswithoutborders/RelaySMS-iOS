//
//  RecentsViewLoggedIn.swift
//  SMSWithoutBorders-Production
//
//  Created by MAC on 17/02/2025.
//

import SwiftUI


struct NoSentMessages: View {
    @Binding var selectedTab: HomepageTabs
    @Binding var platformRequestType: RequestType

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
                    selectedTab = .platforms
                    platformRequestType = .compose
                } label: {
                    Text("Send new message")
                        .bold()
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.bottom, 10)
                
                Button {
                    selectedTab = .platforms
                    platformRequestType = .available
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
        }
    }
}

struct RecentsViewLoggedIn: View {
    @Binding var selectedTab: HomepageTabs
    @Binding var platformRequestType: RequestType

    var body: some View {
        NavigationView {
            VStack {
                NoSentMessages(
                    selectedTab: $selectedTab,
                    platformRequestType: $platformRequestType
                )
            }
            .navigationTitle("Recents")
        }
    }
}

#Preview {
    @State var selectedTab: HomepageTabs = .recents
    @State var platformRequestType: RequestType = .available
    
    RecentsViewLoggedIn(
        selectedTab: $selectedTab,
        platformRequestType: $platformRequestType
    )
}

#Preview {
    @State var selectedTab: HomepageTabs = .recents
    @State var platformRequestType: RequestType = .available
    
    NoSentMessages(
        selectedTab: $selectedTab,
        platformRequestType: $platformRequestType
    )
}
