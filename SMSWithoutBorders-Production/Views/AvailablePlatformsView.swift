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
            List(platforms) { platform in
                Text(platform.platform_name ?? "unknown")
            }
        }
    }
}

struct AvailablePlatformsView_Previews: PreviewProvider {
    static var previews: some View {
        AvailablePlatformsView()
    }
}
