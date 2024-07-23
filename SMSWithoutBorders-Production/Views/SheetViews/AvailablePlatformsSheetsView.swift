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
    enum TYPE {
        case AVAILABLE
        case STORED
    }
    
    @Environment(\.dismiss) var dismiss
    @FetchRequest(sortDescriptors: []) var platforms: FetchedResults<PlatformsEntity>
    @State var mPlatforms: [PlatformsEntity] = []

    @State var services = [Publisher.PlatformsData]()
    
    @State var platformsLoading = false
    
    @Binding var codeVerifier: String
    
    
    @State var title: String
    @State var description: String
    
    @State var mockTesting: Bool = false

    @State var type: TYPE = TYPE.AVAILABLE
    @Environment(\.openURL) var openURL
    
    
    var body: some View {
        VStack {
            if(!mockTesting && platforms.isEmpty) {
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
                            if mockTesting {
                                ForEach(getMockData(), id: \.name) { platform in
                                    getPlatformsSubViews(platform: platform, image: nil)
                                }
                            } else {
                                ForEach(platforms, id: \.name) { platform in
                                    let mPlatform = Publisher.PlatformsData(
                                        name: platform.name!,
                                        shortcode: platform.shortcode!,
                                        service_type: platform.service_type!,
                                        protocol_type: platform.protocol_type!,
                                        icon_svg: "<svg>...</svg>",
                                        icon_png: "example.png"
                                    )
                                    getPlatformsSubViews(platform: mPlatform,
                                                         image: platform.image)
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
    
    @ViewBuilder
    func getPlatformsSubViews(platform: Publisher.PlatformsData, image: Data?) -> some View{
        VStack {
            Button(action: {
                switch type {
                case AvailablePlatformsSheetsView.TYPE.AVAILABLE:
                    do {
                        let publisher = Publisher()
                        let response = try publisher.getURL(platform: platform.name)
                        codeVerifier = response.codeVerifier
                        openURL(URL(string: response.authorizationURL)!)
                    }
                    catch {
                        print("Some error occured: \(error)")
                    }
                case AvailablePlatformsSheetsView.TYPE.STORED:
                    print("Checking stored")
                }
                dismiss()
            }) {
                if image == nil {
                    Image("exampleGmail")
                        .resizable()
                        .scaledToFill()
                        .clipped()
                        .cornerRadius(10)
                        .shadow(radius: 3)
                        .frame(width: 100, height: 100)
                        .padding()
                }
                else {
                    Image(uiImage: UIImage(data: image!)!)
                        .resizable()
                        .scaledToFill()
                        .clipped()
                        .cornerRadius(10)
                        .shadow(radius: 3)
                        .frame(width: 100, height: 100)
                        .padding()
                }
            }
            .shadow(color: Color.white, radius: 8, x: -9, y: -9)
            .shadow(color: Color(red: 163/255, green: 177/255, blue: 198/255), radius: 8, x: 9, y: 9)
            .padding(.vertical, 20)
            Text(platform.name)
                .font(.system(size: 16, design: .rounded))
            Text(platform.protocol_type)
                .font(.system(size: 10, design: .rounded))
        }
    }
    func getMockData() -> [Publisher.PlatformsData] {
        return [
            Publisher.PlatformsData(
            name: "gmail",
            shortcode: "g",
            service_type: "email",
            protocol_type: "oauth",
            icon_svg: "<svg>...</svg>",
            icon_png: "example.png"
        ), Publisher.PlatformsData(
            name: "twitter",
            shortcode: "ix",
            service_type: "text",
            protocol_type: "oauth",
            icon_svg: "<svg>...</svg>",
            icon_png: "example.png"
        )]
    }
}

#Preview {
    @State var codeVerifier = ""
    @State var title = "Available Platforms"
    @State var description = "Select a platform to save it for offline use"
    @State var mockTesting = true
    AvailablePlatformsSheetsView(codeVerifier: $codeVerifier,
                                 title: title,
                                 description: description, mockTesting: mockTesting)
}
