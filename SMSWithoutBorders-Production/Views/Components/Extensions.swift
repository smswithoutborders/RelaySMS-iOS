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
