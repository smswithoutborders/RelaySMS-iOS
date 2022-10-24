//
//  SpinnerView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 10/24/22.
//

import SwiftUI
import UIKit


struct SpinnerView: View {
    @State var stateText: String = "Loading..."
    @State var spinning: Bool = false
    @State private var isKeyboardVisible = false
    
    var body: some View {
        ZStack {
            Text(stateText)
                .font(.system(.body, design: .rounded))
                .bold()
                .offset(x: 0, y: -25)
 
            RoundedRectangle(cornerRadius: 3)
                .stroke(Color(.systemGray5), lineWidth: 3)
                .frame(width: 250, height: 3)
 
            RoundedRectangle(cornerRadius: 3)
                .stroke(Color.blue, lineWidth: 3)
                .frame(width: 30, height: 3)
                .offset(CGSize(width: spinning ? 110 : -110, height: 0))
                .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false))
        }
        .onAppear() {
            self.spinning = true
        }
    }
}

struct SpinnerView_Previews: PreviewProvider {
    static var previews: some View {
        SpinnerView()
    }
}
