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
    
    @Binding var platformClicked: PlatformsEntity?
    
    var body: some View {
        VStack {
            NavigationView {
                List(platforms) { platform in
                    NavigationLink {
                        ComposeViewAdapter(platform: platform)
                    } label: {
                        AvailablePlatformView(platform: platform)
                    }
                }
                .navigationTitle("Available Platforms")
            }
        }
    }
}

struct AvailablePlatformsView_Previews: PreviewProvider {
    @State static var platformClicked: PlatformsEntity?
    
    static var previews: some View {
        AvailablePlatformsView(platformClicked: $platformClicked)
    }
}
