//
//  RecentsView.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 26/07/2024.
//

import SwiftUI

struct RecentsView: View {
    @Environment(\.managedObjectContext) var datastore
    @FetchRequest(sortDescriptors: []) var encryptedContents: FetchedResults<EncryptedContentsEntity>
    @FetchRequest(sortDescriptors: []) var platforms: FetchedResults<PlatformsEntity>
    
    @State var platformType: Int? = 0
    @State var platform: PlatformsEntity?
    @Binding var codeVerifier: String

    
    var things: [String: String] = ["sample":"one"]
    
    var body: some View {
        NavigationView {
            VStack {
                if encryptedContents.isEmpty {
                    VStack {
                        Spacer()
                        Text("No Recent Messages")
                            .font(.largeTitle)
                    }
                }
                
                ZStack(alignment: .bottomTrailing) {
                    List(encryptedContents){ encryptedContent in
//                        NavigationLink {
//                            PlatformHandler.getView(platform: getPlatform(encryptedContent: encryptedContent, platforms: platforms), encryptedContent: encryptedContent)
//                                .environment(\.managedObjectContext, datastore)
//                        } label: {
//                            Text(encryptedContent.encrypted_content ?? "unknown")
//                        }
                    }
                    Button(action: {
                    }, label: {
                        Image(systemName: "square.and.pencil")
                        .font(.system(.largeTitle))
                            .frame(width: 77, height: 70)
                            .foregroundColor(Color.white)
                            .padding(.bottom, 7)
                    })
                    .background(Color.blue)
                    .cornerRadius(38.5)
                    .shadow(color: Color.black.opacity(0.3),
                            radius: 3,
                            x: 3,
                            y: 3)
                    .padding()
                }
                
            }
            .navigationTitle("Recents")
        }
    }
}



#Preview {
    @State var codeVerifier: String = ""
    RecentsView(codeVerifier: $codeVerifier)
}
