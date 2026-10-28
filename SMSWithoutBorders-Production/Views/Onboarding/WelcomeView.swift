//
//  WelcomeView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 28/10/2026.
//

import SwiftUI

enum OnboardingPage: String, Identifiable, CaseIterable {
    case welcome
    case saveAccess

    var id: String { rawValue }

    static var first: Self = .welcome
}

struct SaveAccessView: View {
    
    @State var onComplete: () -> Void
    @State var onPreviousClick: () -> Void
    var body: some View {
        VStack(alignment: .leading) {
            Button(String(localized: "Previous")) {
                onPreviousClick()
            }
            .padding()
            
            VStack {
                Spacer()
                VStack(spacing: 20) {
                    Image("3")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)

                    
                    Text(String(localized: "Save access to your accounts. It is stored securely on your device so you can send messages as yourself."))
                        .multilineTextAlignment(.center)
                    
                }
                
                Spacer()
                
                Button(action: onComplete) {
                    Text(String(localized: "Done"))
                        .foregroundColor(.white)
                        .padding() // 1. Add inner padding first
                        .frame(maxWidth: .infinity) // 2. Stretch to full width
                }
                .buttonStyle(.borderedProminent)
                
            }
            .padding(.bottom, 20)
        }
        .padding()
    }
}

struct WelcomeView: View {
    
    @State var onComplete: () -> Void
    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 20) {
                Text(String(localized: "Welcome to RelaySMS!"))
                    .font(.title)
                    .fontWeight(.bold)

                Image("1")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
                    .padding(.bottom, 40)
                
                Text(String(localized: "Use SMS to make a post, send emails and messages with no internet connection."))
                    .multilineTextAlignment(.center)
                
            }
            
            Spacer()
            
            Button(action: onComplete) {
                Text(String(localized: "Learn how it works"))
                    .foregroundColor(.white)
                    .padding() // 1. Add inner padding first
                    .frame(maxWidth: .infinity) // 2. Stretch to full width
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom, 10)

            Button(String(localized: "Restore backup")) {
                
            }
            .padding(.bottom, 20)

            Button(String(localized: "Read our privacy policy")) {
                
            }
            .font(.caption)
        }
        .padding()
    }
}

struct OnboardingView: View {
    private let pages = OnboardingPage.allCases
    @State private var position: ScrollPosition = .init(idType: OnboardingPage.ID.self)
    
    @State var onboardingCompletedCallback: () -> Void

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                ForEach(pages) { page in
                    Group {
                        switch page {
                        case .welcome:
                            WelcomeView(onComplete: welcomeComplete)
                        case .saveAccess:
                            SaveAccessView(
                                onComplete: onboardingCompletedCallback,
                                onPreviousClick: {
                                    scrollToPage(.welcome)
                                }
                            )
                        }
                    }
                    .containerRelativeFrame([.horizontal])
                }
            }
            .scrollTargetLayout()
        }
        .scrollPosition($position)
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
        .scrollDisabled(true)
        .onAppear {
            // Ensure the onboarding starts at the first page.
            // If not set explicitly, position may be undefined.
            position.scrollTo(id: OnboardingPage.first.id)
        }
    }
    
    func welcomeComplete() {
        scrollToPage(.saveAccess)
    }

    private func scrollToPage(_ page: OnboardingPage) {
        withAnimation {
            position.scrollTo(id: page.id)
        }
    }

}

#Preview {
    WelcomeView(onComplete: {})
}

#Preview {
    SaveAccessView(onComplete: {}, onPreviousClick: {})
}
