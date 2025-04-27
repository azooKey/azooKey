//
//  QwertySpaceKeyModel.swift
//  Keyboard
//
//  Created by ensan on 2020/09/18.
//  Copyright © 2020 ensan. All rights reserved.
//

import Foundation
import SwiftUI
import KeyboardThemes

struct QwertySpaceKeyModel<Extension: ApplicationSpecificKeyboardViewExtension>: QwertyKeyModelProtocol {

    let needSuggestView: Bool = false
    let variationsModel = VariationsModel([])
    let keySizeType: QwertyKeySizeType = .space
    let unpressedKeyBackground: QwertyUnpressedKeyBackground = .normal

    init() {}

    func label<ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable>(width: CGFloat, theme: ThemeData<ThemeExtension>, states: VariableStates, color: Color?) -> KeyLabel<Extension> {
        switch states.keyboardLanguage {
        case .el_GR:
            return KeyLabel(.text("διάστημα"), width: width, textSize: .small, textColor: color)
        case .en_US:
            return KeyLabel(.text("space"), width: width, textSize: .small, textColor: color)
        case .ja_JP, .none:
            return KeyLabel(.text("空白"), width: width, textSize: .small, textColor: color)
        }
    }

    func pressActions(variableStates: VariableStates) -> [ActionType] {
        [.input(" ")]
    }

    func longPressActions(variableStates _: VariableStates) -> LongpressActionType {
        .init(start: [.setCursorBar(.toggle)])
    }

    func feedback(variableStates: VariableStates) {
        KeyboardFeedback<Extension>.click()
    }
}
