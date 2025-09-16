import CustardKit
import Foundation
import KeyboardThemes
import SwiftUI

struct FlickSpaceKeyModel<Extension: ApplicationSpecificKeyboardViewExtension>: UnifiedKeyModelProtocol {
    func pressActions(variableStates _: VariableStates) -> [ActionType] {
        [.input(" ")]
    }
    func longPressActions(variableStates _: VariableStates) -> LongpressActionType {
        .init(start: [.setCursorBar(.toggle)])
    }
    func variationSpace(variableStates: VariableStates) -> UnifiedVariationSpace {
        .fourWay([
            .left: UnifiedVariation(label: .text("←"), pressActions: [.moveCursor(-1)], longPressActions: .init(repeat: [.moveCursor(-1)])),
            .top: UnifiedVariation(label: .text("全角"), pressActions: [.input("　")]),
            .bottom: UnifiedVariation(label: .text("Tab"), pressActions: [.input("\u{0009}")]),
        ])
    }
    func isFlickAble(to direction: FlickDirection, variableStates _: VariableStates) -> Bool {
        switch direction {
        case .left, .top, .bottom: true
        case .right: false
        }
    }

    func label<ThemeExtension>(width: CGFloat, theme _: ThemeData<ThemeExtension>, states: VariableStates, color _: Color?) -> KeyLabel<Extension> where ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable {
        switch states.keyboardLanguage {
        case .el_GR: return KeyLabel(.text("διάστημα"), width: width, textSize: .small)
        case .en_US: return KeyLabel(.text("space"), width: width, textSize: .small)
        case .ja_JP, .none: return KeyLabel(.text("空白"), width: width, textSize: .small)
        }
    }
    func backgroundStyleWhenUnpressed<ThemeExtension>(states _: VariableStates, theme: ThemeData<ThemeExtension>) -> UnifiedKeyBackgroundStyleValue where ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable {
        (theme.normalKeyFillColor.color, theme.normalKeyFillColor.blendMode)
    }
    func feedback(variableStates _: VariableStates) {
        KeyboardFeedback<Extension>.click()
    }
}
