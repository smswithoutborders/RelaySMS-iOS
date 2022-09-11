//
//  PasswordView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/11/22.
//

import SwiftUI

struct PasswordView: View {
    @State public var userPassword: String;
    
    var body: some View {
        VStack {
            Spacer()
            Text("Enter your password")
                .font(.title)
                .bold()
            
            TextEditor(text: $userPassword)
                        .frame(width: 300.0, height: 50.0)
                        .overlay(RoundedRectangle(cornerRadius: 1)
                            .stroke(Color.black))
                        .textContentType(.password)
            
            Button("Sign-in", action: {})
                .buttonStyle(.bordered)
            Spacer()
        }
        .padding()
    }
}

struct PasswordView_Previews: PreviewProvider {
    static var previews: some View {
        PasswordView(userPassword: "")
    }
}
