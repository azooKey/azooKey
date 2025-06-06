//
//  QwertyAaKeyModel.swift
//  Keyboard
//
//  Created by ensan on 2020/12/11.
//  Copyright © 2020 ensan. All rights reserved.
//
import Foundation
import KeyboardThemes
import SwiftUI

struct QwertyAaKeyModel<Extension: ApplicationSpecificKeyboardViewExtension>: QwertyKeyModelProtocol {
    static var shared: Self { QwertyAaKeyModel() }

    var variationsModel = QwertyVariationsModel([])

    let needSuggestView: Bool = false

    func pressActions(variableStates: VariableStates) -> [ActionType] {
        if variableStates.boolStates.isCapsLocked {
            return [.setBoolState(VariableStates.BoolStates.isCapsLockedKey, .off)]
        } else {
            return [.changeCharacterType(.default)]
        }
    }

    func longPressActions(variableStates _: VariableStates) -> LongpressActionType {
        .init(start: [.setBoolState(VariableStates.BoolStates.isCapsLockedKey, .toggle)])
    }

    func label<ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable>(width: CGFloat, theme: ThemeData<ThemeExtension>, states: VariableStates, color: Color?) -> KeyLabel<Extension> {
        if states.boolStates.isCapsLocked {
            return KeyLabel(.image("capslock.fill"), width: width, textColor: color)
        } else {
            return KeyLabel(.text("Aa"), width: width, textColor: color)
        }
    }

    let unpressedKeyBackground: QwertyUnpressedKeyBackground = .special

    func feedback(variableStates: VariableStates) {
        KeyboardFeedback<Extension>.tabOrOtherKey()
    }

}
