//
//  EnterKeyModel.swift
//  Keyboard
//
//  Created by ensan on 2020/04/12.
//  Copyright © 2020 ensan. All rights reserved.
//

import CustardKit
import Foundation
import KeyboardThemes
import SwiftUI

struct FlickEnterKeyModel<Extension: ApplicationSpecificKeyboardViewExtension>: FlickKeyModelProtocol {
    static var shared: Self { FlickEnterKeyModel() }
    let needSuggestView = false

    func pressActions(variableStates: VariableStates) -> [ActionType] {
        switch variableStates.enterKeyState {
        case .complete:
            return [.enter]
        case .return:
            return [.input("\n")]
        }
    }

    func longPressActions(variableStates _: VariableStates) -> LongpressActionType { .none }

    func flickKeys(variableStates: VariableStates) -> [FlickDirection: FlickedKeyModel] {
        [:]
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

    func label<ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable>(width: CGFloat, theme: ThemeData<ThemeExtension>, states: VariableStates) -> KeyLabel<Extension> {
        let text = Design.language.getEnterKeyText(states.enterKeyState)

        return KeyLabel(.text(text), width: width, textColor: specialTextColor(states: states, theme: theme))
    }

    func backgroundStyleWhenUnpressed<ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable>(states: VariableStates, theme: ThemeData<ThemeExtension>) -> FlickKeyBackgroundStyleValue {
        switch states.enterKeyState {
        case .complete:
            theme.specialKeyFillColor.flickKeyBackgroundStyle
        case let .return(type):
            switch type {
            case .default:
                theme.specialKeyFillColor.flickKeyBackgroundStyle
            default:
                if theme == ThemeExtension.default(layout: .flick) {
                    (Design.colors.specialEnterKeyColor, .normal)
                } else if theme == ThemeExtension.native(layout: .flick) {
                    (.accentColor, .normal)
                } else {
                    theme.specialKeyFillColor.flickKeyBackgroundStyle
                }
            }
        }
    }

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
