//
//  ContentView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 9/5/22.
//

import SwiftUI
import MessageUI


func formatEmailForPublishing(
    platformLetter: String,
    to: String, cc: String, bcc: String, subject: String, body: String) -> String {
        
        let formattedString: String = platformLetter + ":" + to + ":" + cc + ":" + bcc + ":" + subject + ":" + body
        
        return formattedString
}

struct EmailView: View {
    @Environment(\.managedObjectContext) var datastore
    @Environment(\.dismiss) var dismiss
    @Environment(\.presentationMode) var presentationMode
    
    @FetchRequest(entity: GatewayClientsEntity.entity(), sortDescriptors: []) var gatewayClientsEntities: FetchedResults<GatewayClientsEntity>

    @State var platform: PlatformsEntity?
    
    @State private var composeTo :String = ""
    @State private var composeCC :String = ""
    @State private var composeBCC :String = ""
    @State private var composeSubject :String = ""
    @State private var composeBody :String = ""
    
    @State private var encryptedInput: String = ""
    var body: some View {
        NavigationView {
            VStack {
                VStack{
                    HStack {
                        Text("To ")
                            .foregroundColor(Color.gray)
                        Spacer()
                        TextField("", text: $composeTo)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    .padding(.leading)
                    Rectangle().frame(height: 1).foregroundColor(.gray)
                }
                Spacer(minLength: 9)
                
                VStack {
                    HStack {
                        Text("Cc ")
                            .foregroundColor(Color.gray)
                        Spacer()
                        TextField("", text: $composeCC)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    .padding(.leading)
                    Rectangle().frame(height: 1).foregroundColor(.gray)
                }
                Spacer(minLength: 9)
                
                VStack {
                    HStack {
                        Text("Bcc ")
                            .foregroundColor(Color.gray)
                        Spacer()
                        TextField("", text: $composeBCC)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    .padding(.leading)
                    Rectangle().frame(height: 1).foregroundColor(.gray)
                }
                Spacer(minLength: 9)
                
                VStack {
                    HStack {
                        Text("Subject ")
                            .foregroundColor(Color.gray)
                        Spacer()
                        TextField("", text: $composeSubject)
                    }
                    .padding(.leading)
                    Rectangle().frame(height: 1).foregroundColor(.gray)
                }
                Spacer(minLength: 9)
                
                VStack {
                    TextEditor(text: $composeBody)
                        .accessibilityLabel("composeBody")
                }
            }
        }
        .padding()
        .navigationBarTitle("Compose email", displayMode: .inline)
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // TODO: Get formatted input
                    do {
                        let formattedEmail = formatEmailForPublishing(platformLetter: self.platform!.platform_letter!, to: composeTo, cc: composeCC, bcc: composeBCC, subject: composeSubject, body: composeBody)
                        
                        let encryptedFormattedContent = formatForPublishing(formattedContent: formattedEmail)
                        
                        print("Encrypted formatted content: \(encryptedFormattedContent)")
                        
                        let gatewayClientHandler = GatewayClientHandler(gatewayClientsEntities: gatewayClientsEntities)
                        
                        let defaultGatewayClient: String = gatewayClientHandler.getDefaultGatewayClientMSISDN()
                        
                        print("Default Gateway client: " + defaultGatewayClient)
                        
                        SMSSharing().sendSMS(message: encryptedFormattedContent, receipient: defaultGatewayClient)
                    }
                    catch {
                        print(error)
                    }
                }) {
//                    Image(systemName: "paperplane.circle.fill")
//                        .imageScale(.large)
                    Text("Send")
                }
            }
        })
    }
}

struct EmailView_Preview: PreviewProvider {
    static var previews: some View {
        EmailView()
    }
}
