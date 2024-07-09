//
//  AvailablePlatformsView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/15/22.
//

import SwiftUI
import SwiftSVG

let jsonString = """
[
    {
        "name": "gmail",
        "shortcode": "g",
        "service_type": "email",
        "protocol_type": "oauth2",
        "image_url":"https://www.macworld.com/wp-content/uploads/2023/01/swift_1200home-1.jpg?quality=50&strip=all"

    },
    {
        "name": "twitter",
        "shortcode": "t",
        "service_type": "text",
        "protocol_type": "oauth2",
        "image_url":"https://www.macworld.com/wp-content/uploads/2023/01/swift_1200home-1.jpg?quality=50&strip=all"

    }
]
"""


struct SimpleButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding(30)
            .background(
                Circle()
                    .fill(Color("offWhite"))
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 10, y: 10)
                    .shadow(color: Color.white.opacity(0.7), radius: 10, x: -5, y: -5)
            )    }
}

struct AvailablePlatformsSheetsView: View {
    @Environment(\.managedObjectContext) var datastore
    @Environment(\.dismiss) var dismiss
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @State var services = [Publisher.PlatformsData]()
    
    @State var platformsLoading = false

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
                            ForEach(services, id: \.name) { service in
                                VStack {
                                    Button(action: {
                                        do {
                                            let response = try publisher.getURL(platform: service.name)
                                            print(response.authorizationURL)
                                            OAuthViewController(appDelegate: appDelegate,
                                                                url: URL(string: response.authorizationURL)!, clientID: response.clientID, redirectUrl: URL(string: response.redirectURL)!)
                                        } catch {
                                            print("Some error occured: \(error)")
                                        }
                                    }) {
                                        AsyncImage(url: URL(string: service.icon_png)) { image in
                                            image
                                                .resizable()
                                                .frame(width: 80, height: 80)
                                                .padding(20)
                                                .background(Color(red: 224/255, green: 229/255, blue: 236/255))
                                                .cornerRadius(20)
                                        } placeholder: {
                                            ProgressView()
                                        }
                                    }
                                    .shadow(color: Color.white, radius: 8, x: -9, y: -9)
                                    .shadow(color: Color(red: 163/255, green: 177/255, blue: 198/255), radius: 8, x: 9, y: 9)
                                    .padding(.vertical, 20)
                                    Text(service.name)
                                        .font(.system(size: 16, design: .rounded))
                                    Text(service.protocol_type)
                                        .font(.system(size: 10, design: .rounded))
                                }
                            }
                        }
                    }
                    
                    Button("Close") {
                        dismiss()
                    }
                    .padding()
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
}

#Preview {
    AvailablePlatformsSheetsView()
}
