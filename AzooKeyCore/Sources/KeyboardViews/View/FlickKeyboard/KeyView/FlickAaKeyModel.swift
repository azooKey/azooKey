//
//  FlickAaKeyModel.swift
//  Keyboard
//
//  Created by ensan on 2020/12/11.
//  Copyright © 2020 ensan. All rights reserved.
//

import CustardKit
import KeyboardThemes
import SwiftUI

struct FlickAaKeyModel<Extension: ApplicationSpecificKeyboardViewExtension>: FlickKeyModelProtocol {
    let needSuggestView: Bool = true

    static var shared: Self { FlickAaKeyModel() }

    func pressActions(variableStates: VariableStates) -> [ActionType] {
        if variableStates.boolStates.isCapsLocked {
            return [.setBoolState(VariableStates.BoolStates.isCapsLockedKey, .off)]
        } else {
            return [.changeCharacterType]
        }
    }

    func longPressActions(variableStates _: VariableStates) -> LongpressActionType {
        .none
    }

    func flickKeys(variableStates: VariableStates) -> [CustardKit.FlickDirection: FlickedKeyModel] {
        if variableStates.boolStates.isCapsLocked {
            return [:]
        } else {
            return [
                .top: FlickedKeyModel(
                    labelType: .image("capslock"),
                    pressActions: [.setBoolState(VariableStates.BoolStates.isCapsLockedKey, .on)]
                )
            ]
        }
    }

    @MainActor func label<ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable>(width: CGFloat, theme: ThemeData<ThemeExtension>, states: VariableStates) -> KeyLabel<Extension> {
        if states.boolStates.isCapsLocked {
            KeyLabel(.image("capslock.fill"), width: width)
        } else {
            KeyLabel(.text("a/A"), width: width)
        }
    }

    func feedback(variableStates: VariableStates) {
        KeyboardFeedback<Extension>.tabOrOtherKey()
    }

    func backgroundStyleWhenUnpressed(states: VariableStates, theme: ThemeData<some ApplicationSpecificTheme>) -> FlickKeyBackgroundStyleValue {
        if states.boolStates.isCapsLocked {
            theme.specialKeyFillColor.flickKeyBackgroundStyle
        } else {
            theme.normalKeyFillColor.flickKeyBackgroundStyle
        }
    }
}
