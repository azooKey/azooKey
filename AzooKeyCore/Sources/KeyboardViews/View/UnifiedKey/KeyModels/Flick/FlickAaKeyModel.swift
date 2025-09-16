import CustardKit
import Foundation
import KeyboardThemes
import SwiftUI

struct FlickAaKeyModel<Extension: ApplicationSpecificKeyboardViewExtension>: UnifiedKeyModelProtocol {
    func pressActions(variableStates: VariableStates) -> [ActionType] {
        if variableStates.boolStates.isCapsLocked {
            [.setBoolState(VariableStates.BoolStates.isCapsLockedKey, .off)]
        } else {
            [.changeCharacterType(.default)]
        }
    }

    func longPressActions(variableStates _: VariableStates) -> LongpressActionType {
        .none
    }

    func variationSpace(variableStates: VariableStates) -> UnifiedVariationSpace {
        if variableStates.boolStates.isCapsLocked {
            .none
        } else {
            .fourWay([
                .top: UnifiedVariation(label: .image("capslock"), pressActions: [.setBoolState(VariableStates.BoolStates.isCapsLockedKey, .on)])
            ])
        }
    }

    func isFlickAble(to direction: FlickDirection, variableStates: VariableStates) -> Bool {
        !variableStates.boolStates.isCapsLocked && direction == .top
    }

    func label<ThemeExtension>(width: CGFloat, theme _: ThemeData<ThemeExtension>, states: VariableStates, color _: Color?) -> KeyLabel<Extension> where ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable {
        if states.boolStates.isCapsLocked {
            KeyLabel(.image("capslock.fill"), width: width)
        } else {
            KeyLabel(.text("a/A"), width: width)
        }
    }
    func feedback(variableStates _: VariableStates) {
        KeyboardFeedback<Extension>.tabOrOtherKey()
    }
    func backgroundStyleWhenUnpressed<ThemeExtension>(states: VariableStates, theme: ThemeData<ThemeExtension>) -> UnifiedKeyBackgroundStyleValue where ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable {
        if states.boolStates.isCapsLocked {
            (theme.specialKeyFillColor.color, theme.specialKeyFillColor.blendMode)
        } else {
            (theme.normalKeyFillColor.color, theme.normalKeyFillColor.blendMode)
        }
    }
}
