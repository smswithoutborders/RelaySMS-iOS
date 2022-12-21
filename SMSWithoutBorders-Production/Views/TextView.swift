//
//  TextView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 11/4/22.
//

import SwiftUI

extension UITextView {
    open override var frame: CGRect {
        didSet {
            backgroundColor = .clear //<<here clear
//            drawsBackground = true
        }

    }
}


struct TextView: View {
    @State var textBody :String = ""
    
//    init() {
//        UITextView.appearance().backgroundColor = .clear
//    }
    
    var body: some View {
        VStack {
            NavigationView {
                VStack {
                    TextEditor(text: $textBody)
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(Color.primary.opacity(0.25))
                        .cornerRadius(16)
                        .accessibilityLabel("textBody")
                        .padding()
                }
                .onAppear() {
                    UITextView.appearance().backgroundColor = .clear
                }
                .onDisappear() {
                    UITextView.appearance().backgroundColor = nil
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

struct TextView_Previews: PreviewProvider {
    static var previews: some View {
        TextView()
    }
}
