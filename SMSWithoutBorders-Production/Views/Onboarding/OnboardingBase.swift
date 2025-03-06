//
//  OnboardingBase.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 04/03/2025.
//

import SwiftUI

struct OnboardingBaseView: View {

    @State private var currentPage: Int = 0

    let pages = [
        OnboardingPageContent(title: String(localized:"Welcome to RelaySMS!"),imageName: "1", description: String(localized: "Use SMS to make a post, send emails and messages with no internet connection", comment: "Explains that you can use Relay to make posts, and send emails and messages without an internet conenction")),
        OnboardingPageContent(imageName: "2", description: String(localized:"RelaySMS Vaults securely stores your online accounts, so that you can access them without an internet connection", comment: "Explains that your online platforms are stored securely")),
        OnboardingPageContent(imageName: "3", description: String(localized: "You can add online accounts to your Vault", comment: "Explains that you can add online accounts to your Vault")),
        OnboardingPageContent(imageName: "4", description: String(localized:"You are ready to begin sending messages from RelaySMS!"))
        ]

    init() {
        UIPageControl.appearance().currentPageIndicatorTintColor = UIColor.gray
        UIPageControl.appearance().pageIndicatorTintColor = UIColor.lightGray.withAlphaComponent(0.5)
    }



    var body: some View {
        VStack {

            PreviousAndSkipButton(pageIndex: $currentPage)

                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        pages[index].tag(index).padding(.bottom, 24)
                    }
                }.tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .padding(.bottom, 24)

            // Button
            OnboardingButton(
                currentIndex: currentPage,
                action: {
                    if (currentPage < pages.count - 1) {
                        currentPage += 1
                    }

                    if(currentPage == pages.count-1){
                        // If on the last page, then go home
                        UserDefaults.standard.set(true, forKey: OnboardingView.ONBOARDING_COMPLETED)
                    }
                }
            ).padding(.bottom, 48)

        }

    }
}


struct OnboardingPageContent: View {
    var title: String?
    let imageName: String
    let description: String
    var subDescription: String?


    var body: some View {
        VStack {
            Spacer()

            if(title != nil){
                Text(title!)
                    .font(Font.custom("unbounded", size: 18)).fontWeight(.medium)
                    .padding(.bottom, 30)
                    .multilineTextAlignment(.center)
            }

            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 300, height: 300)
                .padding()

            Text(description)
                .font(Font.custom("unbounded", size: 18)).fontWeight(.medium)
                .padding(.bottom, 30)
                .multilineTextAlignment(.center)

            if(subDescription != nil){
                Text(subDescription!)
                    .padding(.bottom, 30)
                    .multilineTextAlignment(.center)
            }


        }.padding([.leading, .trailing], 16)
    }
}


#Preview {
    OnboardingBaseView()
}



struct OnboardingButton: View {
    @State var currentIndex: Int
    @State private var isTextLabel = true
    let action: () -> Void


    var body: some View {
        Button(
            action: {
                print("current index on botton is \(currentIndex)")

                if(currentIndex == 0){
                    withAnimation(.bouncy(duration: 0.3)) {
                        isTextLabel.toggle()
                    }
                }

                action()
            }
        ) {
            Group{
                if isTextLabel {
                    if currentIndex == 3 {
                        Text("Great!").frame(maxWidth: .infinity)

                    } else {
                        Text("Learn how it works").frame(maxWidth: .infinity)

                    }

                } else {
                    Image(systemName: "arrow.right")
                        .frame(width: 24, height: 24)
                }
            }
            .padding()
            .frame(
                width: isTextLabel ? .infinity : 72,
                height: isTextLabel ? 52 : 80
            )


        }.buttonStyle(.borderedProminent).frame(
            height: isTextLabel ? 56 : nil
        )
            .clipShape(
                RoundedRectangle(cornerRadius: isTextLabel ? 32 : 120)
            )
            .padding([.leading, .trailing], 16)
    }
}


struct OnboardingButtonPreview: PreviewProvider {
    static var previews: some View {
        OnboardingButton(
            currentIndex: 0,
            action: {}
        )
    }
}
