//
//  KeyModelProtocol.swift
//  Keyboard
//
//  Created by ensan on 2020/04/12.
//  Copyright © 2020 ensan. All rights reserved.
//

import CustardKit
import Foundation
import KeyboardThemes
import SwiftUI

public typealias FlickKeyBackgroundStyleValue = (color: Color, blendMode: BlendMode)

extension ThemeColor {
    var flickKeyBackgroundStyle: FlickKeyBackgroundStyleValue {
        (self.color, self.blendMode)
    }
}

enum FlickKeyBackgroundStyle {
    case normal
    case tabkey
    case selected
    case unimportant

    func backgroundStyle(theme: ThemeData<some ApplicationSpecificTheme>) -> FlickKeyBackgroundStyleValue {
        switch self {
        case .normal:
            return (theme.normalKeyFillColor.color, theme.normalKeyFillColor.blendMode)
        case .tabkey:
            return (theme.specialKeyFillColor.color, theme.specialKeyFillColor.blendMode)
        case .selected:
            return (theme.pushedKeyFillColor.color, theme.pushedKeyFillColor.blendMode)
        case .unimportant:
            return (Color(white: 0, opacity: 0.001), .normal)
        }
    }
}

public protocol FlickKeyModelProtocol<Extension> {
    associatedtype Extension: ApplicationSpecificKeyboardViewExtension

    @MainActor var needSuggestView: Bool {get}

    @MainActor func pressActions(variableStates: VariableStates) -> [ActionType]
    @MainActor func longPressActions(variableStates: VariableStates) -> LongpressActionType
    @MainActor func backgroundStyleWhenPressed<ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable>(theme: ThemeData<ThemeExtension>) -> FlickKeyBackgroundStyleValue
    @MainActor func backgroundStyleWhenUnpressed<ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable>(states: VariableStates, theme: ThemeData<ThemeExtension>) -> FlickKeyBackgroundStyleValue

    @MainActor func flickKeys(variableStates: VariableStates) -> [FlickDirection: FlickedKeyModel]
    @MainActor func isFlickAble(to direction: FlickDirection, variableStates: VariableStates) -> Bool

    @MainActor func label<ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable>(width: CGFloat, theme: ThemeData<ThemeExtension>, states: VariableStates) -> KeyLabel<Extension>

    @MainActor func flickSensitivity(to direction: FlickDirection) -> CGFloat
    @MainActor func feedback(variableStates: VariableStates)

}

extension FlickKeyModelProtocol {
    @MainActor func isFlickAble(to direction: FlickDirection, variableStates: VariableStates) -> Bool {
        (flickKeys(variableStates: variableStates) as [FlickDirection: FlickedKeyModel]).keys.contains(direction)
    }

    func backgroundStyleWhenPressed(theme: ThemeData<some ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable>) -> FlickKeyBackgroundStyleValue {
        (theme.pushedKeyFillColor.color, theme.pushedKeyFillColor.blendMode)
    }

    func backgroundStyleWhenUnpressed(states: VariableStates, theme: ThemeData<some ApplicationSpecificTheme>) -> FlickKeyBackgroundStyleValue {
        (theme.normalKeyFillColor.color, theme.normalKeyFillColor.blendMode)
    }

    @MainActor func flickSensitivity(to direction: FlickDirection) -> CGFloat {
        25 / Extension.SettingProvider.flickSensitivity
    }
}
