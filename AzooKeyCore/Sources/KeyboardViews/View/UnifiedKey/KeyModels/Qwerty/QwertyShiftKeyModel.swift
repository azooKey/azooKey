import Foundation
import KeyboardThemes
import SwiftUI

struct QwertyShiftKeyModel<Extension: ApplicationSpecificKeyboardViewExtension>: UnifiedKeyModelProtocol {
    func pressActions(variableStates: VariableStates) -> [ActionType] {
        if variableStates.boolStates.isCapsLocked {
            return [.setBoolState(VariableStates.BoolStates.isCapsLockedKey, .off)]
        } else if variableStates.boolStates.isShifted {
            return [.setBoolState(VariableStates.BoolStates.isShiftedKey, .off)]
        } else {
            return [.setBoolState(VariableStates.BoolStates.isShiftedKey, .on)]
        }
    }

    func longPressActions(variableStates _: VariableStates) -> LongpressActionType {
        .init(start: [.setBoolState(VariableStates.BoolStates.isCapsLockedKey, .toggle)])
    }

    func doublePressActions(variableStates: VariableStates) -> [ActionType] {
        if variableStates.boolStates.isCapsLocked {
            return []
        } else {
            return [.setBoolState(VariableStates.BoolStates.isCapsLockedKey, .on)]
        }
    }

    func variationSpace(variableStates _: VariableStates) -> UnifiedVariationSpace {
        .none
    }

    func label<ThemeExtension>(width: CGFloat, theme _: ThemeData<ThemeExtension>, states: VariableStates, color: Color?) -> KeyLabel<Extension> where ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable {
        if states.boolStates.isCapsLocked {
            return KeyLabel(.image("capslock.fill"), width: width, textColor: color)
        } else if states.boolStates.isShifted {
            return KeyLabel(.image("shift.fill"), width: width, textColor: color)
        } else {
            return KeyLabel(.image("shift"), width: width, textColor: color)
        }
    }

    func backgroundStyleWhenUnpressed<ThemeExtension>(states _: VariableStates, theme: ThemeData<ThemeExtension>) -> UnifiedKeyBackgroundStyleValue where ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable {
        (theme.specialKeyFillColor.color, theme.specialKeyFillColor.blendMode)
    }

    func feedback(variableStates _: VariableStates) {
        KeyboardFeedback<Extension>.tabOrOtherKey()
    }
}
