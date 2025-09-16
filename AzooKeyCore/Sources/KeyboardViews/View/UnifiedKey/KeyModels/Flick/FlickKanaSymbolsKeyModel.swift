import CustardKit
import Foundation
import KeyboardThemes
import SwiftUI

struct FlickKanaSymbolsKeyModel<Extension: ApplicationSpecificKeyboardViewExtension>: UnifiedKeyModelProtocol {
    func pressActions(variableStates _: VariableStates) -> [ActionType] {
        Extension.SettingProvider.kanaSymbolsFlickCustomKey.compiled().actions
    }
    func longPressActions(variableStates _: VariableStates) -> LongpressActionType {
        Extension.SettingProvider.kanaSymbolsFlickCustomKey.compiled().longpressActions
    }
    func variationSpace(variableStates _: VariableStates) -> UnifiedVariationSpace {
        let data = Extension.SettingProvider.kanaSymbolsFlickCustomKey.compiled()
        let map = data.flick.mapValues { UnifiedVariation(label: $0.labelType, pressActions: $0.pressActions, longPressActions: $0.longPressActions) }
        return .fourWay(map)
    }
    func isFlickAble(to direction: FlickDirection, variableStates _: VariableStates) -> Bool {
        let data = Extension.SettingProvider.kanaSymbolsFlickCustomKey.compiled()
        return data.flick.keys.contains(direction)
    }

    func label<ThemeExtension>(width: CGFloat, theme _: ThemeData<ThemeExtension>, states _: VariableStates, color _: Color?) -> KeyLabel<Extension> where ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable {
        KeyLabel(Extension.SettingProvider.kanaSymbolsFlickCustomKey.compiled().labelType, width: width)
    }
    func backgroundStyleWhenUnpressed<ThemeExtension>(states _: VariableStates, theme: ThemeData<ThemeExtension>) -> UnifiedKeyBackgroundStyleValue where ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable {
        (theme.normalKeyFillColor.color, theme.normalKeyFillColor.blendMode)
    }
    func feedback(variableStates _: VariableStates) {
        KeyboardFeedback<Extension>.click()
    }
}
