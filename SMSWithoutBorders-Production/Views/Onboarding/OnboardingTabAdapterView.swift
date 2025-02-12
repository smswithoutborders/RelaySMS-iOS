//
//  OnboardingTabAdapterView.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 14/06/2024.
//

import SwiftUI

struct Tab<ButtonView: View>: View {
    let buttonView: ButtonView
    @State var title: LocalizedStringKey = "Let's get you started"
    @State var subTitle: LocalizedStringKey
    @State var description: LocalizedStringKey
    @State var imageName: String
    @State var subDescription: LocalizedStringKey
    

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
                .padding()


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
