//
//  AvailablePlatformsView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/15/22.
//

import SwiftUI

let jsonString = """
[
    {
        "name": "gmail",
        "shortcode": "g",
        "service_type": "email",
        "protocol_type": "oauth2"
    },
    {
        "name": "twitter",
        "shortcode": "t",
        "service_type": "text",
        "protocol_type": "oauth2"
    }
]
"""

struct AvailablePlatformsView: View {
    @Environment(\.managedObjectContext) var datastore
    @Environment(\.dismiss) var dismiss
    
//    @FetchRequest(sortDescriptors: []) var platforms: FetchedResults<PlatformsEntity>
    
//    @Binding var platform: PlatformsEntity?
//    @Binding var platformType: Int?
    
    
    @State var services = [Publisher.PlatformsData]()
    
    var body: some View {
        VStack {
            if(services.isEmpty) {
                Text("No platforms")
                    .padding()
            }
            else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 55) {
                        ForEach(services, id: \.name) { service in
                            VStack {
                                AsyncImage(url: URL(string: "https://www.macworld.com/wp-content/uploads/2023/01/swift_1200home-1.jpg?quality=50&strip=all")) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .clipped()
                                        .cornerRadius(10)
                                        .frame(width: 100)
                                        .shadow(radius: 3)
                                } placeholder: {
                                    ProgressView()
                                }
                                .frame(width: 100, height: 100)
                                .padding()
                                
                                Text(service.name)
                                    .font(.system(size: 16, design: .rounded))
                            }
                        }
                    }
                }
            }
        }
        .task {
            let jsonData = jsonString.data(using: .utf8)
            do {
                services = try JSONDecoder().decode([Publisher.PlatformsData].self, from: jsonData!)
                print(services)
            } catch {
                print("Failed to decode some error occured: \(error)")
            }
        }
    }
}

#Preview {
    AvailablePlatformsView()
}
