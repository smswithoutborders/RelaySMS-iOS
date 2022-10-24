//
//  RecentsView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/28/22.
//

import SwiftUI

struct RecentsView: View {
    @Environment(\.managedObjectContext) var datastore
    @State var platformType: Int? = 0
    @State var platform: PlatformsEntity?
    @State var encryptedContent: EncryptedContentsEntity?
    
    var body: some View {
        NavigationView {
            if self.platform != nil && platformType != nil {
                NavigationLink(destination: PlatformHandler.getView(platform: self.platform!, encryptedContent: encryptedContent)
                                .environment(\.managedObjectContext, datastore), tag: 1, selection:$platformType) {}
            }
            else {
                RecentsViewAdapter(platformType: $platformType, platform: $platform)
                    .environment(\.managedObjectContext, datastore)
            }
        }
    }
}

func getPlatform(encryptedContent: EncryptedContentsEntity, platforms: FetchedResults<PlatformsEntity>) -> PlatformsEntity {
    var retPlatform: PlatformsEntity?
    
    for platform in platforms {
        if encryptedContent.platform_name == platform.platform_name {
            retPlatform = platform
            break
        }
    }
    
    return retPlatform!
}

struct RecentsViewAdapter: View {
    @Environment(\.managedObjectContext) var datastore
    @FetchRequest(sortDescriptors: []) var encryptedContents: FetchedResults<EncryptedContentsEntity>
    @FetchRequest(sortDescriptors: []) var platforms: FetchedResults<PlatformsEntity>
    
    @State var showPlatforms : Bool = false;
    
    @Binding var platformType: Int?
    @Binding var platform: PlatformsEntity?
    
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
                        NavigationLink {
                            PlatformHandler.getView(platform: getPlatform(encryptedContent: encryptedContent, platforms: platforms), encryptedContent: encryptedContent)
                                .environment(\.managedObjectContext, datastore)
                        } label: {
                            Text(encryptedContent.encrypted_content ?? "unknown")
                        }
                    }
                    
                    Button(action: {
                        self.showPlatforms.toggle()
//                        EncryptedContentHandler.clearStoredEncryptedContents(encryptedContents: encryptedContents, datastore: datastore)
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
                    .sheet(isPresented: $showPlatforms) {
                        AvailablePlatformsView(platform: $platform, platformType: $platformType)
                            .environment(\.managedObjectContext, datastore)
                    }
                    .padding()
                }
                
            }
            .frame(
                minWidth: 0,
                maxWidth: .infinity,
                minHeight: 0,
                maxHeight: .infinity,
                alignment: .topLeading
            )
        }
        .navigationTitle("Recents")
    }
}


struct RecentsView_Previews: PreviewProvider {
    @State static var platform: PlatformsEntity?
    @State static var platformType: Int?
    
    static var previews: some View {
        RecentsViewAdapter(platformType: $platformType, platform: $platform)
    }
}
