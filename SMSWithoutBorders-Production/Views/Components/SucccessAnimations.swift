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

    let callback: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            VStack {
                Image(systemName: "checkmark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 75, height: 75)
                    .scaleEffect(isAnimating ? 1.0 : 1.5)
                    .onAppear() {
                        withAnimation(
                            .spring(duration: 1.0)
        //                    .repeatForever(autoreverses: false)
                        ) {
                            isAnimating = true
                            rotationAngle += 360.0
                        }
                    }
                    .rotationEffect(Angle(degrees: rotationAngle))
                
                if(!isAnimating) {
                    Text(callbackText)
                        .font(.title)
                        .padding()
                }
            }
            
            Spacer()
            
            if(continueBtnVisible) {
                Button {
                    callback()
                } label: {
                    Text("Continue")
                        .frame(maxWidth: .infinity, maxHeight: 35)
                }
                .padding(.bottom, 32)
                .buttonStyle(.borderedProminent)
                .opacity(continueBtnVisible ? 1 : 0)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                withAnimation(.easeInOut(duration: 1)) {
                    continueBtnVisible = true
                    isAnimating = false
                }
            }
        }
        .padding()
    }
}

struct SuccessAnimation_Preview: PreviewProvider {
    static var previews: some View {
        @State var callbackText = "Welcome back!"
        SuccessAnimations(
            callbackText: $callbackText,
            callback: { print("Callback happening") }
        )
    }
    
}
