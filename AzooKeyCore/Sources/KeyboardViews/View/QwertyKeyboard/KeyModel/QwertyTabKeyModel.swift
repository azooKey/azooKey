//
//  QwertyChangeTabKeyModel.swift
//  Keyboard
//
//  Created by ensan on 2020/12/14.
//  Copyright © 2020 ensan. All rights reserved.
//

import Foundation
import KeyboardThemes
import SwiftUI

// symbolタブ、123タブで表示される切り替えボタン
struct QwertyTabKeyModel<Extension: ApplicationSpecificKeyboardViewExtension>: QwertyKeyModelProtocol {

    func pressActions(variableStates: VariableStates) -> [ActionType] {
        switch SemiStaticStates.shared.needsInputModeSwitchKey {
        case true:
            switch variableStates.keyboardLanguage {
            case .ja_JP, .none, .el_GR:
                return [.moveTab(.system(.user_japanese))]
            case .en_US:
                return [.moveTab(.system(.user_english))]
            }
        case false:
            return [.moveTab(.system(.user_japanese))]
        }

    }
    func longPressActions(variableStates _: VariableStates) -> LongpressActionType {
        .none
    }

    let variationsModel = QwertyVariationsModel([])

    let needSuggestView: Bool = false

    let unpressedKeyBackground: QwertyUnpressedKeyBackground = .special

    func label<ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable>(width: CGFloat, theme: ThemeData<ThemeExtension>, states: VariableStates, color: Color?) -> KeyLabel<Extension> {
        switch SemiStaticStates.shared.needsInputModeSwitchKey {
        case true:
            switch states.keyboardLanguage {
            case .ja_JP, .none, .el_GR:
                return KeyLabel(.text("あいう"), width: width, textColor: color)
            case .en_US:
                return KeyLabel(.text("ABC"), width: width, textColor: color)
            }
        case false:
            return KeyLabel(.text("あいう"), width: width, textColor: color)
        }
    }

    func feedback(variableStates: VariableStates) {
        KeyboardFeedback<Extension>.tabOrOtherKey()
    }
}
