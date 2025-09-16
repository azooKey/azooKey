import Foundation
import KanaKanjiConverterModule
import KeyboardThemes
import SwiftUI

struct QwertyLanguageSwitchKeyModel<Extension: ApplicationSpecificKeyboardViewExtension>: UnifiedKeyModelProtocol {
    let languages: (KeyboardLanguage, KeyboardLanguage)

    @MainActor func currentTabLanguage(variableStates: VariableStates) -> KeyboardLanguage? {
        variableStates.tabManager.existentialTab().language
    }

    func pressActions(variableStates: VariableStates) -> [ActionType] {
        let target: KeyboardLanguage
        let current = currentTabLanguage(variableStates: variableStates)
        if languages.0 == current {
            target = languages.1
        } else if languages.1 == current {
            target = languages.0
        } else if SemiStaticStates.shared.needsInputModeSwitchKey && [.ja_JP, .en_US, .el_GR].contains(variableStates.keyboardLanguage) {
            target = variableStates.keyboardLanguage
        } else {
            target = .ja_JP
        }
        switch target {
        case .ja_JP:
            return [.moveTab(.system(.user_japanese))]
        case .en_US:
            return [.moveTab(.system(.user_english))]
        case .none, .el_GR:
            return []
        }
    }

    func longPressActions(variableStates _: VariableStates) -> LongpressActionType {
        .none
    }
    func variationSpace(variableStates _: VariableStates) -> UnifiedVariationSpace {
        .none
    }

    func label<ThemeExtension>(width: CGFloat, theme _: ThemeData<ThemeExtension>, states: VariableStates, color: Color?) -> KeyLabel<Extension> where ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable {
        let current = currentTabLanguage(variableStates: states)
        if languages.0 == current {
            return KeyLabel(.selectable(languages.0.shortSymbol, languages.1.shortSymbol), width: width, textColor: color)
        } else if languages.1 == current {
            return KeyLabel(.selectable(languages.1.shortSymbol, languages.0.shortSymbol), width: width, textColor: color)
        } else if SemiStaticStates.shared.needsInputModeSwitchKey && [.ja_JP, .en_US, .el_GR].contains(states.keyboardLanguage) {
            return KeyLabel(.text(states.keyboardLanguage.symbol), width: width, textColor: color)
        } else {
            return KeyLabel(.text(KeyboardLanguage.ja_JP.symbol), width: width, textColor: color)
        }
    }

    func backgroundStyleWhenUnpressed<ThemeExtension>(states _: VariableStates, theme: ThemeData<ThemeExtension>) -> UnifiedKeyBackgroundStyleValue where ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable {
        (theme.specialKeyFillColor.color, theme.specialKeyFillColor.blendMode)
    }
    func feedback(variableStates _: VariableStates) {
        KeyboardFeedback<Extension>.tabOrOtherKey()
    }
}
