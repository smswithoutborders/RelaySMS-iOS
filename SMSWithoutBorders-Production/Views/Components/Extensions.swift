//
//  Extensions.swift
//  SMSWithoutBorders-Production
//
//  Created by MAC on 22/01/2025.
//

import SwiftUI

extension View {
    @ViewBuilder
    func applyPresentationDetentsIfAvailable(canLarge: Bool = false) -> some View {
        if #available(iOS 16.0, *) {
            self.presentationDetents(canLarge ? [.medium, .large] : [.medium])
        } else {
            self // No presentation detents on unsupported devices
        }
    }
}

extension DispatchQueue {
    static func background(delay: Double = 0.0, background: (()->Void)? = nil, completion: (() -> Void)? = nil) {
        DispatchQueue.global(qos: .background).async {
            background?()
            if let completion = completion {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
                    completion()
                })
            }
        }
    }

}
