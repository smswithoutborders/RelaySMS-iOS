//
//  RecentsView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/28/22.
//

import SwiftUI

struct RecentsView: View {
    
    @State var platformClicked: PlatformsEntity?
    
    var body: some View {
        NavigationView {
            if platformClicked != nil {
                EmailView()
            }
            else {
                RecentsViewAdapter(platformClicked: $platformClicked)
            }
        }.navigationTitle("Recents")
    }
}

struct RecentsViewAdapter: View {
    @Environment(\.managedObjectContext) var datastore
    @State var showPlatforms : Bool = false;
    
    @Binding var platformClicked: PlatformsEntity?
    
    var body: some View {
        NavigationView {
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
                AvailablePlatformsView(platformClicked: $platformClicked)
                    .environment(\.managedObjectContext, datastore)
            }
        }
    }
}


struct RecentsView_Previews: PreviewProvider {
    @State static var platformClicked: PlatformsEntity?
    
    static var previews: some View {
        RecentsViewAdapter(platformClicked: $platformClicked)
    }
}
