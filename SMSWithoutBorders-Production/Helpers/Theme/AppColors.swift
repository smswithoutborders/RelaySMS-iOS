//
//  AppColors.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 07/03/2025.
//

import SwiftUI

struct ColorScheme {
    // Primary Colors
    let primary: Color
    let onPrimary: Color
    let primaryContainer: Color
    let onPrimaryContainer: Color

    // Secondary Colors
    let secondary: Color
    let onSecondary: Color
    let secondaryContainer: Color
    let onSecondaryContainer: Color

    // Tertiary Colors
    let tertiary: Color
    let onTertiary: Color
    let tertiaryContainer: Color
    let onTertiaryContainer: Color

    // Surface Colors
    let surface: Color
    let onSurface: Color
    let surfaceContainer: Color
    let onSurfaceContainer: Color

    // Background Colors
    let background: Color
    let onBackground: Color
}


struct RelayColors{
    // RelayColorScheme
    static let colorScheme: ColorScheme = ColorScheme(
        primary: Color("primary"),
        onPrimary: Color("onPrimary"),
        primaryContainer: Color("primaryContainer"),
        onPrimaryContainer: Color("onPrimaryContainer"),
        secondary: Color("secondary"),
        onSecondary: Color("onSecondary"),
        secondaryContainer: Color("secondaryContainer"),
        onSecondaryContainer: Color("onSecondaryContainer"),
        tertiary: Color("tertiary"),
        onTertiary: Color("onTertiary"),
        tertiaryContainer: Color("tertiaryContainer"),
        onTertiaryContainer: Color("onTertiaryContainer"),
        surface: Color("surface"),
        onSurface: Color("onSurface"),
        surfaceContainer: Color("surfaceContainer"),
        onSurfaceContainer: Color("onSurfaceContainer"),
        background: Color("surface"),
        onBackground: Color("onSurface")
    )

    // Indigo
    static let indigo25 = Color("indigo25")
    static let indigo50 = Color("indigo50")
    static let indigo100 = Color("indigo100")
    static let indigo200 = Color("indigo200")
    static let indigo300 = Color("indigo300")
    static let indigo400 = Color("indigo400")
    static let indigo500 = Color("indigo500")
    static let indigo600 = Color("indigo600")
    static let indigo700 = Color("indigo700")
    static let indigo800 = Color("indigo800")
    static let indigo900 = Color("indigo900")
    static let indigo950 = Color("indigo950")

    // Orange
    static let orange25 = Color("orange25")
    static let orange50 = Color("orange50")
    static let orange100 = Color("orange100")
    static let orange200 = Color("orange200")
    static let orange300 = Color("orange300")
    static let orange400 = Color("orange400")
    static let orange500 = Color("orange500")
    static let orange600 = Color("orange600")
    static let orange700 = Color("orange700")
    static let orange800 = Color("orange800")
    static let orange900 = Color("orange900")
    static let orange950 = Color("orange950")

    // Teal
    static let teal25 = Color("teal25")
    static let teal50 = Color("teal50")
    static let teal100 = Color("teal100")
    static let teal200 = Color("teal200")
    static let teal300 = Color("teal300")
    static let teal400 = Color("teal400")
    static let teal500 = Color("teal500")
    static let teal600 = Color("teal600")
    static let teal700 = Color("teal700")
    static let teal800 = Color("teal800")
    static let teal900 = Color("teal900")
    static let teal950 = Color("teal950")

    // Gray
    static let gray25 = Color("gray25")
    static let gray50 = Color("gray50")
    static let gray100 = Color("gray100")
    static let gray200 = Color("gray200")
    static let gray300 = Color("gray300")
    static let gray400 = Color("gray400")
    static let gray500 = Color("gray500")
    static let gray600 = Color("gray600")
    static let gray700 = Color("gray700")
    static let gray800 = Color("gray800")
    static let gray900 = Color("gray900")
    static let gray950 = Color("gray950")
}
