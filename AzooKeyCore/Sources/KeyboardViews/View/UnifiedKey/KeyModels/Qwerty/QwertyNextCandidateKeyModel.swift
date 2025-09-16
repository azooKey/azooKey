import Foundation
import KeyboardThemes
import SwiftUI

struct QwertyNextCandidateKeyModel<Extension: ApplicationSpecificKeyboardViewExtension>: UnifiedKeyModelProtocol {
    func pressActions(variableStates: VariableStates) -> [ActionType] {
        if variableStates.resultModel.results.isEmpty {
            [.input(" ")]
        } else {
            [.selectCandidate(.offset(1))]
        }
    }
    func longPressActions(variableStates: VariableStates) -> LongpressActionType {
        if variableStates.resultModel.results.isEmpty {
            .init(start: [.setCursorBar(.toggle)])
        } else {
            .init(start: [.input(" ")])
        }
    }
    func variationSpace(variableStates _: VariableStates) -> UnifiedVariationSpace {
        .none
    }

    func label<ThemeExtension>(width: CGFloat, theme _: ThemeData<ThemeExtension>, states: VariableStates, color: Color?) -> KeyLabel<Extension> where ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable {
        if states.resultModel.results.isEmpty {
            switch states.keyboardLanguage {
            case .el_GR:
                return KeyLabel(.text("διάστημα"), width: width, textSize: .small, textColor: color)
            case .en_US:
                return KeyLabel(.text("space"), width: width, textSize: .small, textColor: color)
            case .ja_JP, .none:
                return KeyLabel(.text("空白"), width: width, textSize: .small, textColor: color)
            }
        } else {
            return KeyLabel(.text("次候補"), width: width, textSize: .small, textColor: color)
        }
    }

    func backgroundStyleWhenUnpressed<ThemeExtension>(states _: VariableStates, theme: ThemeData<ThemeExtension>) -> UnifiedKeyBackgroundStyleValue where ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable {
        // QwertyNextCandidateKeyModel uses normal background by default
        (theme.normalKeyFillColor.color, theme.normalKeyFillColor.blendMode)
    }

    func feedback(variableStates: VariableStates) {
        if variableStates.resultModel.results.isEmpty { KeyboardFeedback<Extension>.click() } else { KeyboardFeedback<Extension>.tabOrOtherKey() }
    }
}
