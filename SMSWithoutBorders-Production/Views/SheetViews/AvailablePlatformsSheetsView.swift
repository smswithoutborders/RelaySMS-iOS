//
//  AvailablePlatformsView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/15/22.
//

import SwiftUI
import SwiftSVG
import CachedAsyncImage

func getMockData() -> [PlatformsEntity] {
    let gmailMock = PlatformsEntity()
    gmailMock.name = "gmail"
    gmailMock.image = nil
    gmailMock.protocol_type = "oauth"
    gmailMock.service_type = "email"
    gmailMock.shortcode = "g"
    
    let xMock = PlatformsEntity()
    xMock.name = "x"
    xMock.image = nil
    xMock.protocol_type = "oauth"
    xMock.service_type = "text"
    xMock.shortcode = "x"

    return [gmailMock, xMock]
}

struct AvailablePlatformsSheetsView: View {
    enum TYPE {
        case AVAILABLE
        case STORED
    }
    
    @Environment(\.managedObjectContext) var datastore
    @Environment(\.openURL) var openURL
    @Environment(\.dismiss) var dismiss
    
    @FetchRequest(sortDescriptors: []) var platforms: FetchedResults<PlatformsEntity>

    @State var services = [Publisher.PlatformsData]()
    
    @State var platformsLoading = false
    
    @Binding var codeVerifier: String
    
    private let publisher = Publisher()
    
    @State var title: String
    @State var description: String
    
    @State var type: TYPE = TYPE.AVAILABLE

    var body: some View {
        VStack {
            if(platforms.isEmpty) {
                Text("No platforms")
                    .padding()
            }
            else {
                VStack {
                    Text(title).font(.system(size: 32, design: .rounded))
                    
                    Text(description)
                        .font(.system(size: 16, design: .rounded))
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 55) {
                            ForEach(platforms, id: \.name) { platform in
                                VStack {
                                    Button(action: {
                                        switch type {
                                        case TYPE.AVAILABLE:
                                            do {
                                                let response = try publisher.getURL(platform: platform.name!)
                                                codeVerifier = response.codeVerifier
                                                openURL(URL(string: response.authorizationURL)!)
                                            }
                                            catch {
                                                print("Some error occured: \(error)")
                                            }
                                        case TYPE.STORED:
                                            print("Checking stored")
                                        }
                                        dismiss()
                                    }) {
                                        getImageWithMock(platform: platform)
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
    }
    
    func getImageWithMock(platform: PlatformsEntity) -> Image {
        if platform.image == nil {
            return Image(uiImage: UIImage(named: "exampleGmail")!)
        }
        return Image(uiImage: UIImage(data: platform.image!)!)
    }
}

#Preview {
    @State var codeVerifier = ""
    @State var title = "Available Platforms"
    @State var description = "Select a platform to save it for offline use"
    AvailablePlatformsSheetsView(codeVerifier: $codeVerifier, 
                                 title: title,
                                 description: description)
}
