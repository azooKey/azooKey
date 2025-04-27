//
//  KogakiKeyModel.swift
//  Keyboard
//
//  Created by ensan on 2020/10/04.
//  Copyright © 2020 ensan. All rights reserved.
//

import CustardKit
import Foundation
import SwiftUI
import KeyboardThemes

struct FlickKogakiKeyModel<Extension: ApplicationSpecificKeyboardViewExtension>: FlickKeyModelProtocol {
    let needSuggestView: Bool = true

    static var shared: Self { FlickKogakiKeyModel() }

    let labelType: KeyLabelType = .text("小ﾞﾟ")

    @MainActor private var customKey: KeyFlickSetting {
        Extension.SettingProvider.koganaFlickCustomKey
    }

    func flickKeys(variableStates: VariableStates) -> [CustardKit.FlickDirection: FlickedKeyModel] {
        customKey.compiled().flick
    }

    private init() {}

    func pressActions(variableStates: VariableStates) -> [ActionType] {
        [.changeCharacterType]
    }

    func longPressActions(variableStates _: VariableStates) -> LongpressActionType {
        .none
    }

    func label<ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable>(width: CGFloat, theme: ThemeData<ThemeExtension>, states: VariableStates) -> KeyLabel<Extension> {
        KeyLabel(self.labelType, width: width)
    }

    func flickSensitivity(to direction: FlickDirection) -> CGFloat {
        let flickSensitivity = Extension.SettingProvider.flickSensitivity
        switch direction {
        case .left, .bottom:
            return 25 / flickSensitivity
        case .top:
            return 50 / flickSensitivity
        case .right:
            return 70 / flickSensitivity
        }
    }

    func feedback(variableStates: VariableStates) {
        KeyboardFeedback<Extension>.tabOrOtherKey()
    }
}
