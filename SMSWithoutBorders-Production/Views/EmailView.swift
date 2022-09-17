//
//  ContentView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/5/22.
//

import SwiftUI


func formatEmailForPublishing(
    platformLetter: String,
    to: String, cc: String, bcc: String, subject: String, body: String) -> String {
        
        let formattedString: String = platformLetter + ":" + to + ":" + cc + ":" + bcc + ":" + subject + ":" + body
        
        return formattedString
}

struct EmailView: View {
    
    @State var platform: PlatformsEntity?
    
    @State private var composeTo :String = ""
    @State private var composeCC :String = ""
    @State private var composeBCC :String = ""
    @State private var composeSubject :String = ""
    @State private var composeBody :String = ""
    
    @State private var encryptedInput: String = ""
    var body: some View {
        VStack {
            TextField("to: ", text: $composeTo)
                .overlay(RoundedRectangle(cornerRadius: 1)
                    .stroke(Color.black))
            
            TextField("cc: ", text: $composeCC)
                    .overlay(RoundedRectangle(cornerRadius: 1)
                        .stroke(Color.black))
            
            TextField("bcc: ", text: $composeBCC)
                .overlay(RoundedRectangle(cornerRadius: 1)
                    .stroke(Color.black))
            
            TextField("subject: ", text: $composeSubject)
                .overlay(RoundedRectangle(cornerRadius: 1)
                    .stroke(Color.black))
            
            
            Text("Email Body")
                .multilineTextAlignment(.leading)
            
            TextEditor(text: $composeBody)
                .frame(height: 450.0)
                .foregroundColor(Color.gray)
                .overlay(RoundedRectangle(cornerRadius: 1)
                    .stroke(Color.black))
        }.padding()
        
        VStack {
            Button("Send", action: {
                // TODO: Get formatted input
                let formattedEmail = formatEmailForPublishing(platformLetter: platform!.platform_letter!, to: composeTo, cc: composeCC, bcc: composeBCC, subject: composeSubject, body: composeBody)
                
                let encryptedFormattedContent = formatForPublishing(formattedContent: formattedEmail)
                
                print("Encrypted formatted content: \(encryptedFormattedContent)")
            })
            .buttonStyle(.bordered)
        }
    }
}

struct EmailView_Preview: PreviewProvider {
    static var previews: some View {
        EmailView()
    }
}
