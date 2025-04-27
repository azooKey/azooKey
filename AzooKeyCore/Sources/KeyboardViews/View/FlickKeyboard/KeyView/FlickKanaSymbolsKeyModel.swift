//
//  KanaSymbolsKeyModel.swift
//  Keyboard
//
//  Created by ensan on 2020/12/27.
//  Copyright © 2020 ensan. All rights reserved.
//

import CustardKit
import Foundation
import SwiftUI
import KeyboardThemes

struct FlickKanaSymbolsKeyModel<Extension: ApplicationSpecificKeyboardViewExtension>: FlickKeyModelProtocol {
    let needSuggestView: Bool = true

    static var shared: Self { FlickKanaSymbolsKeyModel() }
    @MainActor private var customKey: KeyFlickSetting {
        Extension.SettingProvider.kanaSymbolsFlickCustomKey
    }

    func pressActions(variableStates: VariableStates) -> [ActionType] {
        customKey.compiled().actions
    }
    func longPressActions(variableStates _: VariableStates) -> LongpressActionType {
        customKey.compiled().longpressActions
    }
    @MainActor var labelType: KeyLabelType {
        customKey.compiled().labelType
    }
    func flickKeys(variableStates: VariableStates) -> [CustardKit.FlickDirection: FlickedKeyModel] {
        customKey.compiled().flick
    }

    private init() {}

    func label<ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable>(width: CGFloat, theme: ThemeData<ThemeExtension>, states: VariableStates) -> KeyLabel<Extension> {
        KeyLabel(self.labelType, width: width)
    }

    func feedback(variableStates: VariableStates) {
        KeyboardFeedback<Extension>.click()
    }
}
