//
//  AppTypography.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 07/03/2025.
//

import SwiftUI

struct RelayTypography {

    // body
    static let body: Font = Font.system(size: 12)
    static let bodyMedium: Font = Font.system(size: 14)
    static let bodyLarge: Font = Font.system(size: 16)

    // title
    static let titleSmall: Font = Font.custom("unbounded", size: 14).weight(.medium)
    static let titleMedium: Font = Font.custom("unbounded", size: 16).weight(.medium)
    static let titleLarge: Font = Font.custom("unbounded", size: 20).weight(.medium)

    // headline
    static let headlineSmall: Font = Font.custom("unbounded", size: 24).weight(.medium)
    static let headlineMedium: Font = Font.custom("unbounded", size: 28).weight(.medium)
    static let headlineLarge: Font = Font.custom("unbounded", size: 32).weight(.medium)

    // display
    static let displaySmall: Font = Font.custom("unbounded", size: 36).weight(.medium)
    static let displayMedium: Font = Font.custom("unbounded", size: 45).weight(.medium)
    static let displayLarge: Font = Font.custom("unbounded", size: 57).weight(.medium)


}
