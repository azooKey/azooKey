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

public enum AzooKeySpecificTheme: ApplicationSpecificTheme {
    public enum ApplicationColor: ApplicationSpecificColor {
        case normalKeyColor
        case qwertyNormalKeyColor
        case highlightedKeyColor
        case qwertyHighlightedKeyColor
        case specialKeyColor
        case backgroundColor
        case nativeSpecialKeyColor

        public var color: Color {
            switch self {
            case .backgroundColor:
                Design.colors.backGroundColor
            case .normalKeyColor:
                Design.colors.normalKeyColor(layout: .flick)
            case .qwertyNormalKeyColor:
                Design.colors.normalKeyColor(layout: .qwerty)
            case .specialKeyColor:
                Design.colors.specialKeyColor
            case .highlightedKeyColor:
                Design.colors.highlightedKeyColor(layout: .flick)
            case .qwertyHighlightedKeyColor:
                Design.colors.highlightedKeyColor(layout: .qwerty)
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
}

extension AzooKeySpecificTheme: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable {
    public static func native(layout: KeyboardLayout) -> AzooKeyTheme {
        .init(
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
            suggestLabelTextColor: .dynamic(.black),
            keyShadow: .init(color: .color(.black), radius: 0.5, x: 0, y: 0.75)
        )
    }

    public static func `default`(layout: KeyboardLayout) -> AzooKeyTheme {
        .init(
            backgroundColor: .system(.backgroundColor),
            picture: .none,
            textColor: .dynamic(.primary),
            textFont: .regular,
            resultTextColor: .dynamic(.primary),
            resultBackgroundColor: .system(.backgroundColor),
            borderColor: .color(.init(white: 0, opacity: 0)),
            borderWidth: 1,
            normalKeyFillColor: .system(layout == .qwerty ? .qwertyNormalKeyColor : .normalKeyColor),
            specialKeyFillColor: .system(.specialKeyColor),
            pushedKeyFillColor: .system(layout == .qwerty ? .qwertyHighlightedKeyColor : .highlightedKeyColor),
            suggestKeyFillColor: nil,
            suggestLabelTextColor: nil,
            keyShadow: nil
        )
    }
}
