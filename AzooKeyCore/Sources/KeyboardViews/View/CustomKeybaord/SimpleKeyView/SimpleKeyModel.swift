//
//  SimpleKeyModel.swift
//  azooKey
//
//  Created by ensan on 2021/02/19.
//  Copyright © 2021 ensan. All rights reserved.
//

import Foundation
import KeyboardThemes
import SwiftUI

public typealias SimpleKeyBackgroundStyleValue = (color: Color, blendMode: BlendMode)

extension ThemeColor {
    var simpleKeyBackgroundStyle: SimpleKeyBackgroundStyleValue {
        (self.color, self.blendMode)
    }
}

enum SimpleUnpressedKeyColorType: UInt8 {
    case normal
    case special
    case enter
    case selected
    case unimportant

    @MainActor func color<ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable>(states: VariableStates, theme: ThemeData<ThemeExtension>) -> SimpleKeyBackgroundStyleValue {
        switch self {
        case .normal:
            theme.normalKeyFillColor.simpleKeyBackgroundStyle
        case .special:
            theme.specialKeyFillColor.simpleKeyBackgroundStyle
        case .selected:
            theme.pushedKeyFillColor.simpleKeyBackgroundStyle
        case .unimportant:
            (Color(white: 0, opacity: 0.001), .normal)
        case .enter:
            switch states.enterKeyState {
            case .complete:
                theme.specialKeyFillColor.simpleKeyBackgroundStyle
            case let .return(type):
                switch type {
                case .default:
                    theme.specialKeyFillColor.simpleKeyBackgroundStyle
                default:
                    if theme == ThemeExtension.default(layout: states.tabManager.existentialTab().layout) {
                        (Design.colors.specialEnterKeyColor, .normal)
                    } else if theme == ThemeExtension.default(layout: states.tabManager.existentialTab().layout) {
                        (.accentColor, .normal)
                    } else {
                        theme.specialKeyFillColor.simpleKeyBackgroundStyle
                    }
                }
            }
        }
    }
}

protocol SimpleKeyModelProtocol<Extension> {
    associatedtype Extension: ApplicationSpecificKeyboardViewExtension

    var unpressedKeyColorType: SimpleUnpressedKeyColorType {get}
    @MainActor func pressActions(variableStates: VariableStates) -> [ActionType]
    @MainActor func longPressActions(variableStates: VariableStates) -> LongpressActionType
    @MainActor func feedback(variableStates: VariableStates)
    @MainActor func label(width: CGFloat, states: VariableStates) -> KeyLabel<Extension>
    @MainActor func backgroundStyleWhenPressed(theme: Extension.Theme) -> SimpleKeyBackgroundStyleValue
    /// `pressActions`とは別に、押された際に発火する操作
    /// - note: タブ固有の事情で実行しなければならないような処理に利用すること
    @MainActor func additionalOnPress(variableStates: VariableStates)
}

extension SimpleKeyModelProtocol {
    func backgroundStyleWhenPressed(theme: ThemeData<some ApplicationSpecificTheme>) -> SimpleKeyBackgroundStyleValue {
        theme.pushedKeyFillColor.simpleKeyBackgroundStyle
    }

    func additionalOnPress(variableStates: VariableStates) {}
}

struct SimpleKeyModel<Extension: ApplicationSpecificKeyboardViewExtension>: SimpleKeyModelProtocol {
    init(keyLabelType: KeyLabelType, unpressedKeyColorType: SimpleUnpressedKeyColorType, pressActions: [ActionType], longPressActions: LongpressActionType = .none) {
        self.keyLabelType = keyLabelType
        self.unpressedKeyColorType = unpressedKeyColorType
        self.pressActions = pressActions
        self.longPressActions = longPressActions
    }

    let unpressedKeyColorType: SimpleUnpressedKeyColorType
    let keyLabelType: KeyLabelType
    private let pressActions: [ActionType]
    let longPressActions: LongpressActionType

    func label(width: CGFloat, states: VariableStates) -> KeyLabel<Extension> {
        KeyLabel(self.keyLabelType, width: width)
    }

    func pressActions(variableStates: VariableStates) -> [ActionType] {
        pressActions
    }

    func longPressActions(variableStates: VariableStates) -> LongpressActionType {
        longPressActions
    }

    func feedback(variableStates: VariableStates) {
        self.pressActions.first?.feedback(variableStates: variableStates, extension: Extension.self)
    }

}

struct SimpleEnterKeyModel<Extension: ApplicationSpecificKeyboardViewExtension>: SimpleKeyModelProtocol {
    func pressActions(variableStates: VariableStates) -> [ActionType] {
        switch variableStates.enterKeyState {
        case .complete:
            return [.enter]
        case .return:
            return [.input("\n")]
        }
    }

    func longPressActions(variableStates: VariableStates) -> LongpressActionType {
        .none
    }

    let unpressedKeyColorType: SimpleUnpressedKeyColorType = .enter
    func label(width: CGFloat, states: VariableStates) -> KeyLabel<Extension> {
        let text = Design.language.getEnterKeyText(states.enterKeyState)
        return KeyLabel(.text(text), width: width)
    }

    func feedback(variableStates: VariableStates) {
        switch variableStates.enterKeyState {
        case .complete:
            KeyboardFeedback<Extension>.tabOrOtherKey()
        case .return:
            KeyboardFeedback<Extension>.click()
        }
    }
}

struct SimpleNextCandidateKeyModel<Extension: ApplicationSpecificKeyboardViewExtension>: SimpleKeyModelProtocol {
    var unpressedKeyColorType: SimpleUnpressedKeyColorType = .normal

    func pressActions(variableStates: VariableStates) -> [ActionType] {
        if variableStates.resultModel.results.isEmpty {
            [.input(" ")]
        } else {
            [.selectCandidate(.offset(1))]
        }
    }
    @MainActor func longPressActions(variableStates: VariableStates) -> LongpressActionType {
        if variableStates.resultModel.results.isEmpty {
            .init(start: [.setCursorBar(.toggle)])
        } else {
            .init(start: [.input(" ")])
        }
    }

    func label(width: CGFloat, states: VariableStates) -> KeyLabel<Extension> {
        if states.resultModel.results.isEmpty {
            KeyLabel(.text("空白"), width: width)
        } else {
            KeyLabel(.text("次候補"), width: width)
        }
    }

    func feedback(variableStates: VariableStates) {
        if variableStates.resultModel.results.isEmpty {
            KeyboardFeedback<Extension>.click()
        } else {
            KeyboardFeedback<Extension>.tabOrOtherKey()
        }
    }
    func backgroundStyleWhenPressed<ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable>(states: VariableStates, theme: ThemeData<ThemeExtension>) -> SimpleKeyBackgroundStyleValue {
        theme.specialKeyFillColor.simpleKeyBackgroundStyle
    }
}

struct SimpleChangeKeyboardKeyModel<Extension: ApplicationSpecificKeyboardViewExtension>: SimpleKeyModelProtocol {
    func pressActions(variableStates: VariableStates) -> [ActionType] {
        if SemiStaticStates.shared.needsInputModeSwitchKey {
            return []
        } else {
            return [.setCursorBar(.toggle)]
        }
    }
    let unpressedKeyColorType: SimpleUnpressedKeyColorType = .special
    func longPressActions(variableStates: VariableStates) -> LongpressActionType {
        .none
    }

    func label(width: CGFloat, states: VariableStates) -> KeyLabel<Extension> {
        if SemiStaticStates.shared.needsInputModeSwitchKey {
            return KeyLabel(.changeKeyboard, width: width)
        } else {
            return KeyLabel(.image("arrowtriangle.left.and.line.vertical.and.arrowtriangle.right"), width: width)
        }
    }

    func feedback(variableStates: VariableStates) {
        KeyboardFeedback<Extension>.tabOrOtherKey()
    }
}
