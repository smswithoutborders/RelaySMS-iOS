//
//  LoginSheet.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 26/03/2025.
//

import SwiftUI

struct LoginSheet: View {
    @Binding var loginSheetRequested: Bool
    @Binding var parentSheetShown: Bool

    var body: some View {
        VStack {
            Image(systemName: "person.crop.circle.badge")
                .resizable()
                .scaledToFit()
                .frame(width: 75, height: 75)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(
                    RelayColors.colorScheme.primary)

            Text("Login")
                .font(RelayTypography.titleLarge)
                .multilineTextAlignment(.center)
                .padding()

            Text("Access your account to save or use your online platforms without an internet connection.").multilineTextAlignment(.center)
            Spacer().frame(height: 32)
            
            Button(action: {
                parentSheetShown.toggle()
                loginSheetRequested.toggle()
            }) {
                Text("Continue").frame(maxWidth: .infinity)
            }
            .buttonStyle(.relayButton(variant: .primary))
            .padding(.bottom, 16)
            
            Text("An SMS would be sent to your phone number to verify you own the number.")
                .multilineTextAlignment(.center)
                .font(.footnote)
                .foregroundStyle(.gray)
                .padding(.bottom, 10)
        }
        .padding([.leading, .trailing], 16)
    }
}
