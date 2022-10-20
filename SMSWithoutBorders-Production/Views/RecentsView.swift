//
//  RecentsView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/28/22.
//

import SwiftUI

struct RecentsView: View {
    @State var platformType: Int? = 0
    @State var platform: PlatformsEntity?
    
    var body: some View {
        NavigationView {
            if self.platform != nil && platformType != nil {
                NavigationLink(destination: EmailView(platform: self.platform), tag: 1, selection:$platformType) {}
            }
            else {
                RecentsViewAdapter(platformType: $platformType, platform: $platform)
            }
        }
    }
}

struct RecentsViewAdapter: View {
    @Environment(\.managedObjectContext) var datastore
    @State var showPlatforms : Bool = false;
    
    @Binding var platformType: Int?
    @Binding var platform: PlatformsEntity?
    
    var things: [String] = ["sample", "one"]
    
    var body: some View {
        Button(action: {
            self.showPlatforms.toggle()
        }, label: {
            Image(systemName: "square.and.pencil")
            .font(.system(.largeTitle))
                .frame(width: 77, height: 70)
                .foregroundColor(Color.white)
                .padding(.bottom, 7)
        })
        .background(Color.blue)
        .cornerRadius(38.5)
        .padding()
        .shadow(color: Color.black.opacity(0.3),
                radius: 3,
                x: 3,
                y: 3)
        .sheet(isPresented: $showPlatforms) {
            AvailablePlatformsView(platform: $platform, platformType: $platformType)
                .environment(\.managedObjectContext, datastore)
        }
        .navigationTitle("Recents")
    }
}


struct RecentsView_Previews: PreviewProvider {
    @State static var platform: PlatformsEntity?
    @State static var platformType: Int?
    
    static var previews: some View {
        RecentsViewAdapter(platformType: $platformType, platform: $platform)
    }
}
