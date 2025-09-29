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
    // Optional accessors for each variation kind (independent of variationSpace)
    @MainActor func getFlickVariationMap(variableStates: VariableStates) -> [FlickDirection: UnifiedVariation]
    @MainActor func getLinearVariations(variableStates: VariableStates) -> (arr: [QwertyVariationsModel.VariationElement], direction: VariationsViewDirection)

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

    // Capabilities for policy decisions
    @MainActor func hasFlickVariations(variableStates: VariableStates) -> Bool
    @MainActor func hasLinearVariations(variableStates: VariableStates) -> Bool
    @MainActor func hasLongPressAction(variableStates: VariableStates) -> Bool
}

public extension UnifiedKeyModelProtocol {
    @MainActor func doublePressActions(variableStates _: VariableStates) -> [ActionType] { [] }
    @MainActor func isFlickAble(to direction: FlickDirection, variableStates _: VariableStates) -> Bool { false }
    @MainActor func flickSensitivity(to direction: FlickDirection) -> CGFloat { 25 / Extension.SettingProvider.flickSensitivity }
    @MainActor func showsTapBubble(variableStates _: VariableStates) -> Bool { false }
    @MainActor func backgroundStyleWhenPressed<ThemeExtension>(theme: ThemeData<ThemeExtension>) -> UnifiedKeyBackgroundStyleValue where ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable {
        (theme.pushedKeyFillColor.color, theme.pushedKeyFillColor.blendMode)
    }

    // Default capabilities derived from variationSpace and longPressActions
    @MainActor func hasFlickVariations(variableStates: VariableStates) -> Bool {
        !getFlickVariationMap(variableStates: variableStates).isEmpty
    }

    @MainActor func hasLinearVariations(variableStates: VariableStates) -> Bool {
        !getLinearVariations(variableStates: variableStates).arr.isEmpty
    }

    @MainActor func hasLongPressAction(variableStates: VariableStates) -> Bool {
        !longPressActions(variableStates: variableStates).isEmpty
    }

    // Default accessors derive from variationSpace
    @MainActor func getFlickVariationMap(variableStates: VariableStates) -> [FlickDirection: UnifiedVariation] {
        if case let .fourWay(map) = variationSpace(variableStates: variableStates) { return map }
        return [:]
    }
    @MainActor func getLinearVariations(variableStates: VariableStates) -> (arr: [QwertyVariationsModel.VariationElement], direction: VariationsViewDirection) {
        if case let .linear(arr, direction) = variationSpace(variableStates: variableStates) { return (arr, direction) }
        return ([], .center)
    }
}
