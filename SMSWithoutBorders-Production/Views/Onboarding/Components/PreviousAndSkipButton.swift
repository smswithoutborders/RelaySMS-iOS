//
//  BackButtonAndSkip.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 05/03/2025.
//

import SwiftUI

struct PreviousAndSkipButton: View {
    @Binding var pageIndex: Int
    var body: some View {
        HStack(alignment: VerticalAlignment.center) {
            Button {
                pageIndex -= 1
            } label: {
                Image(systemName: "arrow.left")
                    .resizable()
                    .aspectRatio(contentMode: .fit).frame( width: 20.0, height: 20.0 )
                Text("Previous")
            }                                .padding(12)
                .background(Color.blue.opacity(0.1))
                .clipShape(Capsule())

            Spacer()
            Button {
                UserDefaults.standard.set(true, forKey: OnboardingView.ONBOARDING_COMPLETED)
            } label: {
                Text("Skip")
                Image(systemName: "arrow.right")
                    .resizable()
                    .aspectRatio(contentMode: .fit).frame( width: 20.0, height: 20.0 )
            }                                .padding(12)
                .background(Color.blue.opacity(0.1))
                .clipShape(Capsule())

        }.padding([.leading, .trailing], 16)
    }
}
