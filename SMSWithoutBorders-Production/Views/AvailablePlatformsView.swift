//
//  AvailablePlatformsView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/15/22.
//

import SwiftUI

struct AvailablePlatformsView: View {
    @Environment(\.managedObjectContext) var datastore
    @Environment(\.dismiss) var dismiss
    
    @FetchRequest(sortDescriptors: []) var platforms: FetchedResults<PlatformsEntity>
    
    @Binding var platform: PlatformsEntity?
    @Binding var platformType: Int?
    
    var body: some View {
        VStack {
            NavigationView {
                List(platforms) { platform in
                    AvailablePlatformView(platform: platform)
                        .onTapGesture {
                            self.platform = platform
                            if platform.type == "email" {
                                self.platformType = 1
                            }
                            dismiss()
                        }
                }
                .navigationTitle("Available Platforms")
            }
        }
    }
}

struct AvailablePlatformsView_Previews: PreviewProvider {
    @State static var platform: PlatformsEntity?
    @State static var platformType: Int?
    
    static var previews: some View {
        AvailablePlatformsView(platform: $platform, platformType: $platformType)
    }
}
