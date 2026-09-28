//
//  AzooKeySpecificTheme.swift
//  azooKey
//
//  Created by β α on 2023/07/20.
//  Copyright © 2023 DevEn3. All rights reserved.
//

import Foundation
import KeyboardThemes
import KeyboardViews
import SwiftUI
import UIKit

private enum SystemThemeColors {
    typealias Components = (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)

    static let minimumNormal = color(light: (0, 0, 0, 0.22), dark: (1, 1, 1, 0.26))
    static let minimumSpecial = color(light: (0, 0, 0, 0.52), dark: (1, 1, 1, 0.56))
    static let minimumPushed = color(light: (0.86, 0.87, 0.89, 1), dark: (0.16, 0.16, 0.18, 0.98))
    static let minimumSuggest = color(light: (0.93, 0.93, 0.95, 1), dark: (0.16, 0.16, 0.18, 0.98))
    static let minimumSuggestText = color(light: (0.08, 0.08, 0.09, 1), dark: (1, 1, 1, 1))
    static let technoAccent = color(light: (0.95, 0.34, 0.06, 0.95), dark: (0.96, 0.76, 0.36, 0.92))
    static let technoNormal = color(light: (1, 1, 1, 1), dark: (0.025, 0.03, 0.04, 0.9))
    static let technoPushed = color(light: (0.929, 0.933, 0.949, 1), dark: (0.76, 0.52, 0.22, 0.96))
    static let technoSpecial = color(light: (0.87, 0.88, 0.9, 1), dark: (0.045, 0.055, 0.075, 0.92))
    static let technoText = color(light: (0.055, 0.07, 0.09, 1), dark: (0.96, 0.76, 0.36, 1))
    static let technoShadow = color(light: (0, 0, 0, 0.14), dark: (0, 0, 0, 0.35))

    private static func color(light: Components, dark: Components) -> Color {
        Color(uiColor: UIColor { traits in
            let value = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: value.red, green: value.green, blue: value.blue, alpha: value.alpha)
        })
    }
}

public enum AzooKeySpecificTheme: ApplicationSpecificTheme {
    public enum ApplicationColor: ApplicationSpecificColor {
        case normalKeyColor
        case highlightedKeyColor
        case specialKeyColor
        case backgroundColor
        case nativeSpecialKeyColor

        public var color: Color {
            switch self {
            case .backgroundColor:
                Design.colors.backGroundColor
            case .normalKeyColor:
                Design.colors.normalKeyColor
            case .specialKeyColor:
                Design.colors.specialKeyColor
            case .highlightedKeyColor:
                Design.colors.highlightedKeyColor
            case .nativeSpecialKeyColor:
                Design.colors.nativeSpecialKeyColor
            }
        }
    }

}

public typealias AzooKeyTheme = ThemeData<AzooKeySpecificTheme>

public extension AzooKeyTheme {
    static let base: Self = Self(
        backgroundColor: .color(Color(.displayP3, red: 0.839, green: 0.843, blue: 0.862)),
        picture: .none,
        textColor: .color(Color(.displayP3, white: 0, opacity: 1)),
        textFont: .regular,
        resultTextColor: .color(Color(.displayP3, white: 0, opacity: 1)),
        resultBackgroundColor: .color(Color(.displayP3, red: 0.839, green: 0.843, blue: 0.862)),
        borderColor: .color(Color(white: 0, opacity: 1)),
        borderWidth: 0,
        normalKeyFillColor: .color(Color(.displayP3, white: 1, opacity: 1)),
        specialKeyFillColor: .color(Color(.displayP3, red: 0.804, green: 0.808, blue: 0.835)),
        pushedKeyFillColor: .color(Color(.displayP3, red: 0.929, green: 0.929, blue: 0.945)),
        suggestKeyFillColor: nil,
        suggestLabelTextColor: .color(Color(.displayP3, white: 0, opacity: 1)),
        keyShadow: nil
    )

    /// A keyless typographic theme: labels float over a small orientation mark.
    static let minimum: Self = {
        var theme = AzooKeySpecificTheme.native
        theme.textFont = .light
        theme.style = .minimal
        theme.borderWidth = 1.5
        theme.normalKeyFillColor = .color(SystemThemeColors.minimumNormal)
        theme.specialKeyFillColor = .color(SystemThemeColors.minimumSpecial)
        theme.pushedKeyFillColor = .color(SystemThemeColors.minimumPushed)
        theme.suggestKeyFillColor = .color(SystemThemeColors.minimumSuggest)
        theme.suggestLabelTextColor = .color(SystemThemeColors.minimumSuggestText)
        theme.keyShadow = nil
        return theme
    }()

    /// Chamfered instrument panels with a technical light/dark interpretation.
    static let techno: Self = {
        var theme = AzooKeySpecificTheme.native
        theme.textColor = .color(SystemThemeColors.technoText)
        theme.textFont = .semibold
        theme.style = .faceted
        theme.borderColor = .color(SystemThemeColors.technoAccent)
        theme.borderWidth = 0.8
        theme.normalKeyFillColor = .color(SystemThemeColors.technoNormal)
        theme.specialKeyFillColor = .color(SystemThemeColors.technoSpecial)
        theme.pushedKeyFillColor = .color(SystemThemeColors.technoPushed)
        theme.suggestKeyFillColor = theme.specialKeyFillColor
        theme.suggestLabelTextColor = theme.textColor
        theme.keyShadow = .init(
            color: .color(SystemThemeColors.technoShadow),
            radius: 2,
            x: 0,
            y: 2
        )
        return theme
    }()

}

extension AzooKeySpecificTheme: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable {
    public static let native = AzooKeyTheme(
        backgroundColor: .dynamic(.clear),
        picture: .none,
        textColor: .dynamic(.primary),
        textFont: .regular,
        resultTextColor: .dynamic(.primary),
        resultBackgroundColor: .dynamic(.clear),
        borderColor: .dynamic(.clear),
        borderWidth: 1,
        normalKeyFillColor: .color(.white, blendMode: .softLight),
        specialKeyFillColor: .system(.nativeSpecialKeyColor, blendMode: .softLight),
        pushedKeyFillColor: .color(.systemGray4, blendMode: .softLight),
        suggestKeyFillColor: nil,
        suggestLabelTextColor: nil,
        keyShadow: .init(color: .color(.black), radius: 0.5, x: 0, y: 0.75)
    )

    public static let `default` = AzooKeyTheme(
        backgroundColor: .system(.backgroundColor),
        picture: .none,
        textColor: .dynamic(.primary),
        textFont: .regular,
        resultTextColor: .dynamic(.primary),
        resultBackgroundColor: .system(.backgroundColor),
        borderColor: .color(.init(white: 0, opacity: 0)),
        borderWidth: 1,
        normalKeyFillColor: .system(.normalKeyColor),
        specialKeyFillColor: .system(.specialKeyColor),
        pushedKeyFillColor: .system(.highlightedKeyColor),
        suggestKeyFillColor: nil,
        suggestLabelTextColor: nil,
        keyShadow: nil
    )
}
