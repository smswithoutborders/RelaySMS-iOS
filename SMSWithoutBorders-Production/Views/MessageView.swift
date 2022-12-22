//
//  MessengerView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 12/22/22.
//

import SwiftUI

struct MessageView: View {
    
    @State var textBody :String = ""
    @State var contactInformation :String = ""
    var body: some View {
        VStack {
            NavigationView {
                VStack {
                    VStack{
                        HStack {
                            Text("To ")
                                .foregroundColor(Color.gray)
                            Spacer()
                            TextField("", text: $contactInformation)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                        }
                        .padding(.leading)
                        Rectangle().frame(height: 1).foregroundColor(.gray)
                    }
                    VStack {
                        TextEditor(text: $textBody)
                            .textFieldStyle(PlainTextFieldStyle())
                            .foregroundColor(Color.primary.opacity(0.25))
                            .cornerRadius(16)
                            .accessibilityLabel("textBody")
                            .padding()
                    }
                }
            }
            .navigationBarTitle("Compose Tweet", displayMode: .inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                    }) {
                        Text("Tweet")
                    }
                }
            })
        }
    }
}

struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        MessageView()
    }
}
