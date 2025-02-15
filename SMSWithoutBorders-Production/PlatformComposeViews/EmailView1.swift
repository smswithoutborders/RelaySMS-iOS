//
//  EmailView1.swift
//  SMSWithoutBorders-Production
//
//  Created by MAC on 27/01/2025.
//

import SwiftUI

struct EmailComposeView: View {
    @Binding var composeTo: String
    @Binding var composeFrom: String
    @Binding var composeCC: String
    @Binding var composeBCC: String
    @Binding var composeSubject: String
    @Binding var composeBody: String
    @Binding var fromAccount: String?

    var body: some View {
        NavigationView {
            VStack {
                if(fromAccount != nil) {
                    VStack{
                        HStack {
                            Text("From ")
                                .foregroundColor(Color.secondary)
                            Spacer()
                            TextField(fromAccount!, text: $composeFrom)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .disabled(true)
                        }
                        .padding(.leading)
                        Rectangle().frame(height: 1).foregroundColor(.secondary)
                    }
                    Spacer(minLength: 9)
                    
                }
                
                VStack{
                    HStack {
                        Text("To ")
                            .foregroundColor(Color.secondary)
                        Spacer()
                        TextField("", text: $composeTo)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    .padding(.leading)
                    Rectangle().frame(height: 1).foregroundColor(.secondary)
                }
                Spacer(minLength: 9)
                
                VStack {
                    HStack {
                        Text("Cc ")
                            .foregroundColor(Color.secondary)
                        Spacer()
                        TextField("", text: $composeCC)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    .padding(.leading)
                    Rectangle().frame(height: 1).foregroundColor(.secondary)
                }
                Spacer(minLength: 9)
                
                VStack {
                    HStack {
                        Text("Bcc ")
                            .foregroundColor(Color.secondary)
                        Spacer()
                        TextField("", text: $composeBCC)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    .padding(.leading)
                    Rectangle().frame(height: 1).foregroundColor(.secondary)
                }
                Spacer(minLength: 9)
                
                VStack {
                    HStack {
                        Text("Subject ")
                            .foregroundColor(Color.secondary)
                        Spacer()
                        TextField("", text: $composeSubject)
                    }
                    .padding(.leading)
                    Rectangle().frame(height: 1).foregroundColor(.secondary)
                }
                Spacer(minLength: 9)
                
                VStack {
                    TextEditor(text: $composeBody)
                        .accessibilityLabel("composeBody")
                }
            }
        }
    }
}


struct EmailCompose1_Preview: PreviewProvider {
    static var previews: some View {
        @State var composeTo: String = ""
        @State var composeFrom: String = ""
        @State var composeCC: String = ""
        @State var composeBCC: String = ""
        @State var composeSubject: String = ""
        @State var composeBody: String = ""
        @State var fromAccount: String? = ""

        return EmailComposeView(
            composeTo: $composeTo,
            composeFrom: $composeFrom,
            composeCC: $composeCC,
            composeBCC: $composeBCC,
            composeSubject: $composeSubject,
            composeBody: $composeBody,
            fromAccount: $fromAccount
        )
    }
}
