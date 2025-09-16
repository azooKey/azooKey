import CustardKit
import Foundation
import KeyboardThemes
import SwiftUI
import enum KanaKanjiConverterModule.KeyboardLanguage

struct QwertyDynamicChangeKeyModel<Extension: ApplicationSpecificKeyboardViewExtension>: UnifiedKeyModelProtocol {
    func pressActions(variableStates states: VariableStates) -> [ActionType] {
        if SemiStaticStates.shared.needsInputModeSwitchKey {
            switch states.tabManager.existentialTab() {
            case .qwerty_abc:
                if QwertyLayoutProvider<Extension>.shiftBehaviorPreference() != .leftbottom || states.boolStates.isShifted || states.boolStates.isCapsLocked {
                    [] // system globe
                } else {
                    [.moveTab(.system(.qwerty_numbers))]
                }
            default:
                [] // system globe
            }
        } else {
            switch states.tabManager.existentialTab() {
            case .qwerty_hira:
                [.moveTab(.system(.qwerty_symbols))]
            case .qwerty_abc:
                if QwertyLayoutProvider<Extension>.shiftBehaviorPreference() != .leftbottom || states.boolStates.isShifted || states.boolStates.isCapsLocked {
                    [.moveTab(.system(.qwerty_symbols))]
                } else {
                    [.moveTab(.system(.qwerty_numbers))]
                }
            case .qwerty_numbers, .qwerty_symbols:
                [.moveTab(.system(.user_english))]
            default:
                [.setCursorBar(.toggle)]
            }
        }
    }

    func longPressActions(variableStates: VariableStates) -> LongpressActionType {
        if QwertyLayoutProvider<Extension>.shiftBehaviorPreference() != .leftbottom || variableStates.boolStates.isShifted || variableStates.boolStates.isCapsLocked {
            .none
        } else {
            .init(start: [.setTabBar(.toggle)])
        }
    }
    func variationSpace(variableStates _: VariableStates) -> UnifiedVariationSpace { .none }

    func label<ThemeExtension>(width: CGFloat, theme _: ThemeData<ThemeExtension>, states: VariableStates, color: Color?) -> KeyLabel<Extension> where ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable {
        if SemiStaticStates.shared.needsInputModeSwitchKey {
            switch states.tabManager.existentialTab() {
            case .qwerty_abc:
                if QwertyLayoutProvider<Extension>.shiftBehaviorPreference() != .leftbottom || states.boolStates.isShifted || states.boolStates.isCapsLocked {
                    KeyLabel(.changeKeyboard, width: width, textColor: color)
                } else {
                    KeyLabel(.image("textformat.123"), width: width, textColor: color)
                }
            default:
                KeyLabel(.changeKeyboard, width: width, textColor: color)
            }
        } else {
            switch states.tabManager.existentialTab() {
            case .qwerty_hira:
                KeyLabel(.text("#+="), width: width, textColor: color)
            case .qwerty_abc:
                if QwertyLayoutProvider<Extension>.shiftBehaviorPreference() != .leftbottom || states.boolStates.isShifted || states.boolStates.isCapsLocked {
                    KeyLabel(.text("#+="), width: width, textColor: color)
                } else {
                    KeyLabel(.image("textformat.123"), width: width, textColor: color)
                }
            case .qwerty_numbers, .qwerty_symbols:
                KeyLabel(.text(KeyboardLanguage.en_US.symbol), width: width, textColor: color)
            default:
                KeyLabel(.image("arrowtriangle.left.and.line.vertical.and.arrowtriangle.right"), width: width, textColor: color)
            }
        }
    }
    func backgroundStyleWhenUnpressed<ThemeExtension>(states _: VariableStates, theme: ThemeData<ThemeExtension>) -> UnifiedKeyBackgroundStyleValue where ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable {
        (theme.specialKeyFillColor.color, theme.specialKeyFillColor.blendMode)
    }
    func feedback(variableStates _: VariableStates) {
        KeyboardFeedback<Extension>.tabOrOtherKey()
    }
}
