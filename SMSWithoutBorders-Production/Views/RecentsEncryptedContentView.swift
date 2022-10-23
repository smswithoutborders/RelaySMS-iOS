//
//  RecentsEncryptedContentView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 10/22/22.
//

import SwiftUI

struct RecentsEncryptedContentView: View {
    var encryptedContent: EncryptedContentsEntity?
    
    var body: some View {
        HStack {
            Text(encryptedContent?.encrypted_content ?? "unknown")
            Spacer()
        }
    }
}

struct RecentsEncryptedContentView_Previews: PreviewProvider {
    static var previews: some View {
        RecentsEncryptedContentView()
    }
}
