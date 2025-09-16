import CustardKit
import Foundation
import KeyboardThemes
import SwiftUI

public typealias UnifiedKeyBackgroundStyleValue = (color: Color, blendMode: BlendMode)

public protocol UnifiedKeyModelProtocol<Extension> {
    associatedtype Extension: ApplicationSpecificKeyboardViewExtension

    // Unified actions
    @MainActor func pressActions(variableStates: VariableStates) -> [ActionType]
    @MainActor func longPressActions(variableStates: VariableStates) -> LongpressActionType
    @MainActor func doublePressActions(variableStates: VariableStates) -> [ActionType]

    // Unified variations
    @MainActor func variationSpace(variableStates: VariableStates) -> UnifiedVariationSpace

    // Tap bubble (small suggest) control independent of gesture kind
    @MainActor func showsTapBubble(variableStates: VariableStates) -> Bool

    // Optional Flick-specific capabilities (for 4-way interactions)
    @MainActor func isFlickAble(to direction: FlickDirection, variableStates: VariableStates) -> Bool
    @MainActor func flickSensitivity(to direction: FlickDirection) -> CGFloat

    // Label
    @MainActor func label<ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable>(width: CGFloat, theme: ThemeData<ThemeExtension>, states: VariableStates, color: Color?) -> KeyLabel<Extension>

    // Background styles
    @MainActor func backgroundStyleWhenPressed<ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable>(theme: ThemeData<ThemeExtension>) -> UnifiedKeyBackgroundStyleValue
    @MainActor func backgroundStyleWhenUnpressed<ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable>(states: VariableStates, theme: ThemeData<ThemeExtension>) -> UnifiedKeyBackgroundStyleValue

    // Feedback
    @MainActor func feedback(variableStates: VariableStates)
}

public extension UnifiedKeyModelProtocol {
    @MainActor func doublePressActions(variableStates _: VariableStates) -> [ActionType] { [] }
    @MainActor func isFlickAble(to direction: FlickDirection, variableStates _: VariableStates) -> Bool { false }
    @MainActor func flickSensitivity(to direction: FlickDirection) -> CGFloat { 25 / Extension.SettingProvider.flickSensitivity }
    @MainActor func showsTapBubble(variableStates _: VariableStates) -> Bool { false }
    @MainActor func backgroundStyleWhenPressed<ThemeExtension>(theme: ThemeData<ThemeExtension>) -> UnifiedKeyBackgroundStyleValue where ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable {
        (theme.pushedKeyFillColor.color, theme.pushedKeyFillColor.blendMode)
    }
}
