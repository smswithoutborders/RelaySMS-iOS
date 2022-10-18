//
//  ComposeViewAdapter.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 10/18/22.
//

import SwiftUI

struct ComposeViewAdapter: View {
    let platform: PlatformsEntity?
    
    var body: some View {
        Group {
            if platform?.type == "email" {
                EmailView()
            }
        }
    }
}

struct ComposeViewAdapter_Previews: PreviewProvider {
    @State static var platformClicked: PlatformsEntity?
    static var previews: some View {
        ComposeViewAdapter(platform: platformClicked)
    }
}
