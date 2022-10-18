//
//  AvailablePlatormView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 10/18/22.
//

import SwiftUI

struct AvailablePlatformView: View {
    let platform: PlatformsEntity
    
    var body: some View {
        HStack {
            Text(platform.platform_name ?? "unknown")
            Spacer()
        }
    }
}

struct AvailablePlatormView_Previews: PreviewProvider {
    @State static var platform: PlatformsEntity?
    static var previews: some View {
        AvailablePlatformView(platform: platform!)
            .previewLayout(.fixed(width: 300, height: 70))
    }
}
