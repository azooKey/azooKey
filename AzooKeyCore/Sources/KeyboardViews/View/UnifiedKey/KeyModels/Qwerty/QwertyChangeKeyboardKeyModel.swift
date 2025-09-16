import Foundation
import KeyboardThemes
import SwiftUI

struct QwertyChangeKeyboardKeyModel<Extension: ApplicationSpecificKeyboardViewExtension>: UnifiedKeyModelProtocol {
    func pressActions(variableStates _: VariableStates) -> [ActionType] {
        // When the system requires the input mode switch key, do nothing here (system handles it).
        // Otherwise, reuse this key as a cursor bar toggle like legacy behavior.
        SemiStaticStates.shared.needsInputModeSwitchKey ? [] : [.setCursorBar(.toggle)]
    }
    func longPressActions(variableStates _: VariableStates) -> LongpressActionType {
        .none
    }
    func variationSpace(variableStates _: VariableStates) -> UnifiedVariationSpace {
        .none
    }

    func label<ThemeExtension>(width: CGFloat, theme _: ThemeData<ThemeExtension>, states _: VariableStates, color: Color?) -> KeyLabel<Extension> where ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable {
        // Globe when required by system; otherwise show cursor toggle icon
        let label: KeyLabelType = SemiStaticStates.shared.needsInputModeSwitchKey ? .changeKeyboard : .image("arrowtriangle.left.and.line.vertical.and.arrowtriangle.right")
        return KeyLabel(label, width: width, textColor: color)
    }

    func backgroundStyleWhenUnpressed<ThemeExtension>(states _: VariableStates, theme: ThemeData<ThemeExtension>) -> UnifiedKeyBackgroundStyleValue where ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable {
        (theme.specialKeyFillColor.color, theme.specialKeyFillColor.blendMode)
    }
    func feedback(variableStates _: VariableStates) {
        KeyboardFeedback<Extension>.tabOrOtherKey()
    }
}
