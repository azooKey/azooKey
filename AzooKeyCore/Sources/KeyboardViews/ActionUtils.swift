//
//  Action.swift
//  Keyboard
//
//  Created by ensan on 2020/04/11.
//  Copyright © 2020 ensan. All rights reserved.
//

import CustardKit
import Foundation

extension CodableActionData {
    var actionType: ActionType {
        switch self {
        case let .input(value):
            return .input(value)
        case let .directInput(value):
            return .input(value, simplyInsert: true)
        case let .replaceDefault(value):
            return .changeCharacterType(value)
        case let .replaceLastCharacters(value):
            return .replaceLastCharacters(value)
        case let .delete(value):
            return .delete(value)
        case .smartDeleteDefault:
            return .smoothDelete
        case let .smartDelete(value):
            return .smartDelete(value)
        case .selectCandidate(let selection):
            return .selectCandidate(selection)
        case .complete:
            return .enter
        case .completeCharacterForm(let forms):
            return .completeCharacterForm(forms)
        case let .moveCursor(value):
            return .moveCursor(value)
        case let .smartMoveCursor(value):
            return .smartMoveCursor(value)
        case let .moveTab(value):
            return .moveTab(value)
        case .enableResizingMode:
            return .enableResizingMode
        case .toggleCursorBar:
            return .setCursorBar(.toggle)
        case .toggleCapsLockState:
            return .setBoolState(VariableStates.BoolStates.isCapsLockedKey, .toggle)
        case .toggleTabBar:
            return .setTabBar(.toggle)
        case let .launchApplication(value):
            switch value.scheme {
            case .azooKey:
                return .openApp("azooKey://" + value.target)
            case .shortcuts:
                return .openApp("shortcuts://" + value.target)
            }
        case .dismissKeyboard:
            return .dismissKeyboard
        case .paste:
            return .paste
        }
    }
}

extension CodableLongpressActionData {
    var longpressActionType: LongpressActionType {
        let duration: LongpressActionType.Duration = switch self.duration {
        case .normal: .normal
        case .light: .light
        }
        return .init(
            duration: duration,
            start: self.start.map {$0.actionType},
            repeat: self.repeat.map {$0.actionType}
        )
    }
}

public extension ActionType {
    @MainActor func feedback<Extension: ApplicationSpecificKeyboardViewExtension>(variableStates: VariableStates, extension _: Extension.Type) {
        switch self {
        case .input, .paste, .insertMainDisplay:
            KeyboardFeedback<Extension>.click()
        case .delete:
            KeyboardFeedback<Extension>.delete()
        case .smoothDelete, .smartDelete, .smartMoveCursor:
            KeyboardFeedback<Extension>.smoothDelete()
        case .moveTab, .enter, .changeCharacterType, .completeCharacterForm, .setCursorBar, .moveCursor, .enableResizingMode, .replaceLastCharacters, .setTabBar, .setBoolState, .setUpsideComponent, .setSearchQuery, .selectCandidate:
            KeyboardFeedback<Extension>.tabOrOtherKey()
        case .openApp, .dismissKeyboard, .hideLearningMemory:
            return
        case let .boolSwitch(compiledExpression, trueAction, falseAction):
            if let condition = variableStates.boolStates.evaluateExpression(compiledExpression) {
                if condition {
                    trueAction.first?.feedback(variableStates: variableStates, extension: Extension.self)
                } else {
                    falseAction.first?.feedback(variableStates: variableStates, extension: Extension.self)
                }
            }
        }
    }
}
