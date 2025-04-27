//
//  QwertyConditionalKeyModel.swift
//
//
//  Created by miwa on 2024/01/20.
//

import Foundation
import SwiftUI
import enum CustardKit.TabData
import enum KanaKanjiConverterModule.KeyboardLanguage
import KeyboardThemes

struct QwertyConditionalKeyModel<Extension: ApplicationSpecificKeyboardViewExtension>: QwertyKeyModelProtocol {
    var keySizeType: QwertyKeySizeType

    var needSuggestView: Bool

    var variationsModel: VariationsModel = .init([])

    var unpressedKeyBackground: QwertyUnpressedKeyBackground

    /// 条件に基づいてモデルを返すclosure
    var key: (VariableStates) -> (any QwertyKeyModelProtocol<Extension>)

    func pressActions(variableStates: VariableStates) -> [ActionType] {
        key(variableStates).pressActions(variableStates: variableStates)
    }

    func longPressActions(variableStates: VariableStates) -> LongpressActionType {
        key(variableStates).longPressActions(variableStates: variableStates)
    }

    func label<ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable>(width: CGFloat, theme: ThemeData<ThemeExtension>, states: VariableStates, color: Color?) -> KeyLabel<Extension> {
        key(states).label(width: width, theme: theme, states: states, color: color)
    }

    func feedback(variableStates: VariableStates) {
        key(variableStates).feedback(variableStates: variableStates)
    }
}
