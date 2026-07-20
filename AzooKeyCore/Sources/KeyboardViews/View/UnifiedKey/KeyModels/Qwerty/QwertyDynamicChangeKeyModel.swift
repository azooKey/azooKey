import CustardKit
import Foundation
import enum KanaKanjiConverterModule.KeyboardLanguage
import KeyboardThemes
import SwiftUI

struct QwertyDynamicChangeKeyModel<Extension: ApplicationSpecificKeyboardViewExtension>: UnifiedKeyModelProtocol {
    private enum TabRole {
        case hiragana
        case english
        case numberOrSymbol
        case other
    }

    @MainActor
    private func tabRole(states: VariableStates) -> TabRole {
        switch states.tabManager.resolvedTab() {
        case .standard(.flick_japanese), .standard(.qwerty_japanese):
            .hiragana
        case .standard(.flick_english), .standard(.qwerty_english):
            .english
        case .standard(.flick_numbersymbols),
             .standard(.qwerty_numbers),
             .standard(.qwerty_symbols):
            .numberOrSymbol
        case let .custard(custard):
            switch custard.language {
            case .ja_JP:
                .hiragana
            case .en_US:
                .english
            case .none:
                .numberOrSymbol
            case .el_GR, .undefined:
                .other
            }
        case .standard, .clipboardHistory, .emoji:
            .other
        }
    }

    func pressActions(variableStates states: VariableStates) -> [ActionType] {
        if SemiStaticStates.shared.needsInputModeSwitchKey {
            switch tabRole(states: states) {
            case .english:
                if Extension.SettingProvider.qwertyShiftBehaviorPreference != .leftBottom || states.boolStates.isShifted || states.boolStates.isCapsLocked {
                    [] // system globe
                } else {
                    [.moveTab(.system(.qwerty_numbers))]
                }
            case .hiragana, .numberOrSymbol, .other:
                [] // system globe
            }
        } else {
            switch tabRole(states: states) {
            case .hiragana:
                [.moveTab(.system(.qwerty_symbols))]
            case .english:
                if Extension.SettingProvider.qwertyShiftBehaviorPreference != .leftBottom || states.boolStates.isShifted || states.boolStates.isCapsLocked {
                    [.moveTab(.system(.qwerty_symbols))]
                } else {
                    [.moveTab(.system(.qwerty_numbers))]
                }
            case .numberOrSymbol:
                [.moveTab(.system(.user_english))]
            case .other:
                [.setCursorBar(.toggle)]
            }
        }
    }

    func longPressActions(variableStates: VariableStates) -> LongpressActionType {
        if Extension.SettingProvider.qwertyShiftBehaviorPreference != .leftBottom || variableStates.boolStates.isShifted || variableStates.boolStates.isCapsLocked {
            .none
        } else {
            .init(start: [.setTabBar(.toggle)])
        }
    }
    func variationSpace(variableStates _: VariableStates) -> UnifiedVariationSpace { .none }

    func label<ThemeExtension>(width: CGFloat, theme _: ThemeData<ThemeExtension>, states: VariableStates, color: Color?) -> KeyLabel<Extension> where ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable {
        if SemiStaticStates.shared.needsInputModeSwitchKey {
            switch tabRole(states: states) {
            case .english:
                if Extension.SettingProvider.qwertyShiftBehaviorPreference != .leftBottom || states.boolStates.isShifted || states.boolStates.isCapsLocked {
                    KeyLabel(.changeKeyboard, width: width, textColor: color)
                } else {
                    KeyLabel(.image("textformat.123"), width: width, textColor: color)
                }
            case .hiragana, .numberOrSymbol, .other:
                KeyLabel(.changeKeyboard, width: width, textColor: color)
            }
        } else {
            switch tabRole(states: states) {
            case .hiragana:
                KeyLabel(.text("#+="), width: width, textColor: color)
            case .english:
                if Extension.SettingProvider.qwertyShiftBehaviorPreference != .leftBottom || states.boolStates.isShifted || states.boolStates.isCapsLocked {
                    KeyLabel(.text("#+="), width: width, textColor: color)
                } else {
                    KeyLabel(.image("textformat.123"), width: width, textColor: color)
                }
            case .numberOrSymbol:
                KeyLabel(.text(KeyboardLanguage.en_US.symbol), width: width, textColor: color)
            case .other:
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
