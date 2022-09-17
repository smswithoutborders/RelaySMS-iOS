//
//  AvailablePlatformsView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/15/22.
//

import SwiftUI

struct AvailablePlatformsView: View {
    @Environment(\.managedObjectContext) var datastore
    
    @FetchRequest(sortDescriptors: []) var platforms: FetchedResults<PlatformsEntity>
    
    var body: some View {
        VStack {
            NavigationView {
                List(platforms) { platform in
                    NavigationLink {
                        if(platform.type == "email") {
                            EmailView(platform: platform)
                        }
                    } label: {
                        Text(platform.platform_name ?? "unknown")
                    }
                }
                .navigationTitle("Available Platforms")
            }
        }
    }
}

struct AvailablePlatformsView_Previews: PreviewProvider {
    static var previews: some View {
        AvailablePlatformsView()
    }
}
