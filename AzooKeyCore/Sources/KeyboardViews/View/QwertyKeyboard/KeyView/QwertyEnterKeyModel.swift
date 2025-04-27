//
//  QwertyEnterKeyView.swift
//  Keyboard
//
//  Created by ensan on 2020/09/18.
//  Copyright © 2020 ensan. All rights reserved.
//

import Foundation
import SwiftUI
import KeyboardThemes

struct QwertyEnterKeyModel<Extension: ApplicationSpecificKeyboardViewExtension>: QwertyKeyModelProtocol {
    let keySizeType: QwertyKeySizeType
    init(keySizeType: QwertyKeySizeType) {
        self.keySizeType = keySizeType
    }

    static var shared: Self { QwertyEnterKeyModel(keySizeType: .enter) }

    var variationsModel = VariationsModel([])

    let needSuggestView: Bool = false

    func pressActions(variableStates: VariableStates) -> [ActionType] {
        switch variableStates.enterKeyState {
        case .complete:
            return [.enter]
        case .return:
            return [.input("\n")]
        }
    }

    func longPressActions(variableStates _: VariableStates) -> LongpressActionType {
        .none
    }

    func specialTextColor<ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable>(states: VariableStates, theme: ThemeData<ThemeExtension>) -> Color? {
        switch states.enterKeyState {
        case .complete:
            nil
        case let .return(type):
            switch type {
            case .default:
                nil
            default:
                if theme == ThemeExtension.native(layout: .flick) {
                    .white
                } else {
                    nil
                }
            }
        }
    }

    func label<ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable>(width: CGFloat, theme: ThemeData<ThemeExtension>, states: VariableStates, color: Color?) -> KeyLabel<Extension> {
        let text = Design.language.getEnterKeyText(states.enterKeyState)
        return KeyLabel(.text(text), width: width, textSize: .small, textColor: color ?? specialTextColor(states: states, theme: theme))
    }

    let unpressedKeyBackground: QwertyUnpressedKeyBackground = .enter

    func feedback(variableStates: VariableStates) {
        switch variableStates.enterKeyState {
        case .complete:
            KeyboardFeedback<Extension>.tabOrOtherKey()
        case let .return(type):
            switch type {
            case .default:
                KeyboardFeedback<Extension>.click()
            default:
                KeyboardFeedback<Extension>.tabOrOtherKey()
            }
        }
    }
}
