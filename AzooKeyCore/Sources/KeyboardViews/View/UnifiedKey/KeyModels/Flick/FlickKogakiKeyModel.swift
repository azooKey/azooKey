import CustardKit
import Foundation
import KeyboardThemes
import SwiftUI

struct FlickKogakiKeyModel<Extension: ApplicationSpecificKeyboardViewExtension>: UnifiedKeyModelProtocol {
    func pressActions(variableStates _: VariableStates) -> [ActionType] {
        [.changeCharacterType(.default)]
    }
    func longPressActions(variableStates _: VariableStates) -> LongpressActionType {
        .none
    }
    func variationSpace(variableStates _: VariableStates) -> UnifiedVariationSpace {
        let data = Extension.SettingProvider.koganaFlickCustomKey.compiled()
        let map = data.flick.mapValues { UnifiedVariation(label: $0.labelType, pressActions: $0.pressActions, longPressActions: $0.longPressActions) }
        return .fourWay(map)
    }
    func isFlickAble(to direction: FlickDirection, variableStates: VariableStates) -> Bool {
        let data = Extension.SettingProvider.koganaFlickCustomKey.compiled()
        return data.flick.keys.contains(direction)
    }
    func flickSensitivity(to direction: FlickDirection) -> CGFloat {
        let s = Extension.SettingProvider.flickSensitivity
        switch direction {
        case .left, .bottom:
            return 25 / s
        case .top:
            return 50 / s
        case .right:
            return 70 / s
        }
    }
    func label<ThemeExtension>(width: CGFloat, theme _: ThemeData<ThemeExtension>, states _: VariableStates, color _: Color?) -> KeyLabel<Extension> where ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable {
        KeyLabel(.text("小ﾞﾟ"), width: width)
    }
    func backgroundStyleWhenUnpressed<ThemeExtension>(states _: VariableStates, theme: ThemeData<ThemeExtension>) -> UnifiedKeyBackgroundStyleValue where ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable {
        (theme.normalKeyFillColor.color, theme.normalKeyFillColor.blendMode)
    }
    func feedback(variableStates _: VariableStates) {
        KeyboardFeedback<Extension>.tabOrOtherKey()
    }
}
