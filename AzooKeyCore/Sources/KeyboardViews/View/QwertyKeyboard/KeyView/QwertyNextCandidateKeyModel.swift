//
//  QwertyNextCandidateKeyModel.swift
//  azooKey
//
//  Created by ensan on 2021/02/07.
//  Copyright © 2021 ensan. All rights reserved.
//

import CustardKit
import Foundation
import KeyboardThemes
import SwiftUI

struct QwertyNextCandidateKeyModel<Extension: ApplicationSpecificKeyboardViewExtension>: QwertyKeyModelProtocol {
    let keySizeType: QwertyKeySizeType = .space

    let needSuggestView: Bool = false

    let variationsModel: VariationsModel = .init([])

    let unpressedKeyBackground: QwertyUnpressedKeyBackground = .normal

    static var shared: Self { QwertyNextCandidateKeyModel<Extension>() }

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

    func label<ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable>(width: CGFloat, theme: ThemeData<ThemeExtension>, states: VariableStates, color: Color?) -> KeyLabel<Extension> {
        if states.resultModel.results.isEmpty {
            switch states.keyboardLanguage {
            case .el_GR:
                KeyLabel(.text("διάστημα"), width: width, textSize: .small, textColor: color)
            case .en_US:
                KeyLabel(.text("space"), width: width, textSize: .small, textColor: color)
            case .ja_JP, .none:
                KeyLabel(.text("空白"), width: width, textSize: .small, textColor: color)
            }
        } else {
            KeyLabel(.text("次候補"), width: width, textSize: .small, textColor: color)
        }
    }

    func backGroundColorWhenUnpressed(states: VariableStates, theme: ThemeData<some ApplicationSpecificTheme>) -> QwertyKeyBackgroundStyleValue {
        theme.specialKeyFillColor.qwertyKeyBackgroundStyle
    }

    func feedback(variableStates: VariableStates) {
        if variableStates.resultModel.results.isEmpty {
            KeyboardFeedback<Extension>.click()
        } else {
            KeyboardFeedback<Extension>.tabOrOtherKey()
        }
    }
}
