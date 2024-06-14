//
//  OnboardingTabAdapterView.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 14/06/2024.
//

import SwiftUI

struct Tab<ButtonView: View>: View {
    let buttonView: ButtonView
    @State var title: String = "Let's get you started"
    @State var subTitle: String
    @State var description: String
    @State var imageName: String
    @State var subDescription: String
    

    var body: some View {
        Text(title)
            .font(.title)
            .fontWeight(.semibold)
        
        Text(subTitle)
            .font(.subheadline)
            .fontWeight(.semibold)

        Spacer()
            
        VStack {
            Text(description)
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.bottom, 60)


            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 200, height: 200)
            
            Text(subDescription)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding(.bottom, 30)
                .padding()
            
            self.buttonView

        }.padding()
        
        Spacer()
    }
}
