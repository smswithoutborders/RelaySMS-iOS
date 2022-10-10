//
//  RecentsView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/28/22.
//

import SwiftUI

struct RecentsView: View {
    @Environment(\.managedObjectContext) var datastore
    @State var showPlatforms : Bool = false;
    
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
                AvailablePlatformsView()
                    .environment(\.managedObjectContext, datastore)
            }
        }
    }
}


struct RecentsView_Previews: PreviewProvider {
    static var previews: some View {
        RecentsView()
    }
}
