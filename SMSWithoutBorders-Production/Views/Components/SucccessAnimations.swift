//
//  SucccessAnimations.swift
//  SMSWithoutBorders-Production
//
//  Created by MAC on 17/02/2025.
//

import SwiftUI

struct SuccessAnimations: View {
    @State var isAnimating = false
    @State var continueBtnVisible = false
    @State var rotationAngle = 0.0

    @Binding var callbackText: String

    let processCallback: () throws -> Void
    let callback: () -> Void

    var body: some View {
        VStack {
            Spacer()
            VStack {
                if(!isAnimating && continueBtnVisible) {
                    Image(systemName: "checkmark.seal.fill")
                        .symbolRenderingMode(.hierarchical)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 75, height: 75)
                        .foregroundStyle(Color.green)
                        .scaleEffect(isAnimating ? 1.0 : 1.5)
                        .padding(.bottom, 24)
                        .onAppear() {
                            withAnimation(
                                .spring(duration: 1.0)
                            ) {
                            }
                        }
                        //.rotationEffect(Angle(degrees: rotationAngle))

                    Text(callbackText)
                        .font(RelayTypography.titleLarge)
                        .padding()
                } else {
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 75, height: 75)
                        .onAppear() {
                            withAnimation(
                                .default
                                .repeatForever(autoreverses: false)
                                
                            ) {
                                isAnimating = true
                                rotationAngle += 360.0
                            }
                        }
                        .rotationEffect(Angle(degrees: rotationAngle))
                }
            }
            Spacer()
            if(continueBtnVisible) {
                Button {
                    callback()
                } label: {
                    Text("Continue")
                }
                .padding(.bottom, 32)
                .buttonStyle(.relayButton(variant: .primary))
                .opacity(continueBtnVisible ? 1 : 0)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                withAnimation(.easeInOut(duration: 1)) {
                    do {
                        try self.processCallback()
                        continueBtnVisible = true
                        isAnimating = false
                    } catch {
                        print(error)
                    }
                }
            }
        }
    }
}

struct SuccessAnimation_Preview: PreviewProvider {
    static var previews: some View {
        @State var callbackText = "Welcome back!"
        SuccessAnimations(
            callbackText: $callbackText,
            processCallback: {}, callback: { print("Callback happening") }
        )
    }

}
