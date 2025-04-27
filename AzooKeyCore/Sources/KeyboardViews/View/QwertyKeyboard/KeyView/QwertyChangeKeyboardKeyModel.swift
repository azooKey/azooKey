//
//  QwertyFunctionalKeyModel.swift
//  Keyboard
//
//  Created by ensan on 2020/09/18.
//  Copyright © 2020 ensan. All rights reserved.
//

import Foundation
import SwiftUI
import enum CustardKit.TabData
import enum KanaKanjiConverterModule.KeyboardLanguage
import KeyboardThemes

struct QwertyChangeKeyboardKeyModel<Extension: ApplicationSpecificKeyboardViewExtension>: QwertyKeyModelProtocol {
    func pressActions(variableStates: VariableStates) -> [ActionType] {
        [] 
    }

    func longPressActions(variableStates _: VariableStates) -> LongpressActionType {
        .none
    }

    let variationsModel = VariationsModel([])

    let needSuggestView: Bool = false

    let keySizeType: QwertyKeySizeType
    let unpressedKeyBackground: QwertyUnpressedKeyBackground = .special

    init(keySizeType: QwertyKeySizeType) {
        self.keySizeType = keySizeType
    }

    func label<ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable>(width: CGFloat, theme: ThemeData<ThemeExtension>, states: VariableStates, color: Color?) -> KeyLabel<Extension> {
        KeyLabel(.changeKeyboard, width: width, textColor: color)
    }

    func feedback(variableStates: VariableStates) {
        KeyboardFeedback<Extension>.tabOrOtherKey()
    }
}
