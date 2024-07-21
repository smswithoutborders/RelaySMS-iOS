//
//  AvailablePlatformsView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/15/22.
//

import SwiftUI
import SwiftSVG
import CachedAsyncImage

struct AvailablePlatformsSheetsView: View {
    @Environment(\.managedObjectContext) var datastore
    @Environment(\.openURL) var openURL
    @Environment(\.dismiss) var dismiss
    
    @FetchRequest(sortDescriptors: []) var platforms: FetchedResults<PlatformsEntity>
    @FetchRequest(sortDescriptors: []) var platformsIcons: FetchedResults<PlatformsIconEntity>
    
    @State var services = [Publisher.PlatformsData]()
    
    @State var platformsLoading = false
    
    @Binding var codeVerifier: String
    
    private let publisher = Publisher()
    
    var body: some View {
        VStack {
            if(platformsLoading && services.isEmpty) {
                ProgressView()
            }
            else if(!platformsLoading && services.isEmpty) {
                Text("No platforms")
                    .padding()
            }
            else {
                VStack {
                    Text("Available Platforms").font(.system(size: 32, design: .rounded))
                    
                    Text("Select a platform to save use for offline access")
                        .font(.system(size: 16, design: .rounded))
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 55) {
                            ForEach(platforms, id: \.name) { platform in
                                VStack {
                                    Button(action: {
                                        do {
                                            let response = try publisher.getURL(platform: platform.name!)
                                            codeVerifier = response.codeVerifier
                                            openURL(URL(string: response.authorizationURL)!)
                                        }
                                        catch {
                                            print("Some error occured: \(error)")
                                        }
                                        dismiss()
                                    }) {
                                        Image(uiImage: getImageFromStore(name: platform.name!)!)
                                            .resizable()
                                            .scaledToFill()
                                            .clipped()
                                            .cornerRadius(10)
                                            .shadow(radius: 3)
                                            .frame(width: 100, height: 100)
                                            .padding()
                                    }
                                    .shadow(color: Color.white, radius: 8, x: -9, y: -9)
                                    .shadow(color: Color(red: 163/255, green: 177/255, blue: 198/255), radius: 8, x: 9, y: 9)
                                    .padding(.vertical, 20)
                                    Text(platform.name!)
                                        .font(.system(size: 16, design: .rounded))
                                    Text(platform.protocol_type!)
                                        .font(.system(size: 10, design: .rounded))
                                }
                            }
                        }
                    }
                    
                    Button("Close") {
                        dismiss()
                    }
                    .padding(.vertical, 50)
                }
            }
        }
        .task {
            platformsLoading = true
            Publisher.getPlatforms() { result in
                switch result {
                case .success(let data):
                    print("Success: \(data)")
                    services = data
                case .failure(let error):
                    print("Failed to load JSON data: \(error)")
                }
                platformsLoading = false
            }
        }
    }
    
    private func getImageFromStore(name: String) -> UIImage? {
        print("Platforms length: \(platformsIcons.count)")
        for platformIcon in platformsIcons {
            print("Checking icon for platform: \(platformIcon.name)")
            if platformIcon.name == name {
                return UIImage(data: platformIcon.image!)
            }
        }
        return nil
    }
    
}

#Preview {
    @State var codeVerifier = ""
    AvailablePlatformsSheetsView(codeVerifier: $codeVerifier)
}
