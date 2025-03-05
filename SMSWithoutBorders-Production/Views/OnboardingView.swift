//
//  OnboardingView.swift
//  SMSWithoutBorders-Production
//
//  Created by MAC on 28/02/2025.
//

import SwiftUI
struct OnboardingView: View {
    @Environment(\.dismiss) var dismiss
    public static var ONBOARDING_COMPLETED: String = "com.afkanerd.relaysms.ONBOARDING_COMPLETED"

    @State var pageIndex: Int = 0

//    init() {
//        for family in UIFont.familyNames.sorted() {
//            let names = UIFont.fontNames(forFamilyName: family)
//            print("Family: \(family) Font names: \(names)")
//        }
//    }

    var body: some View {
        NavigationView {
            VStack {
                switch pageIndex {
                case 3:
                    OnboardingFinished(
                        pageIndex: $pageIndex
                    )
                case 2:
                    OnboardingIntroToAccounts(
                        pageIndex: $pageIndex
                    )
                case 1:
                    OnboardingIntroToVaults(
                        pageIndex: $pageIndex
                    )
                default:
                    OnboardingWelcomeView(
                        pageIndex: $pageIndex
                    )
                }
            }
        }
    }
}

#Preview {
    OnboardingView()
}
