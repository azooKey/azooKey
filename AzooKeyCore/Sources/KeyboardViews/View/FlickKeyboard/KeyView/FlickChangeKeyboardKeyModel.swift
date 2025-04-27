//
//  ChangeKeyboardFlickKey.swift
//  Keyboard
//
//  Created by ensan on 2020/10/19.
//  Copyright © 2020 ensan. All rights reserved.
//

import CustardKit
import Foundation
import KeyboardThemes
import SwiftUI

struct FlickChangeKeyboardModel<Extension: ApplicationSpecificKeyboardViewExtension>: FlickKeyModelProtocol {
    @MainActor private var _enablePasteButton: Bool {
        Extension.SettingProvider.enablePasteButton
    }
    @MainActor private var usePasteButton: Bool {
        !SemiStaticStates.shared.needsInputModeSwitchKey && SemiStaticStates.shared.hasFullAccess && _enablePasteButton
    }
    @MainActor var needSuggestView: Bool {
        usePasteButton
    }

    static var shared: FlickChangeKeyboardModel {
        Self()
    }

    func pressActions(variableStates: VariableStates) -> [ActionType] {
        switch SemiStaticStates.shared.needsInputModeSwitchKey {
        case true:
            return []
        case false:
            return [.setCursorBar(.toggle)]
        }
    }
    func longPressActions(variableStates _: VariableStates) -> LongpressActionType {
        .none
    }

    func flickKeys(variableStates: VariableStates) -> [FlickDirection: FlickedKeyModel] {
        if usePasteButton {
            return [.top: FlickedKeyModel(labelType: .image("doc.on.clipboard"), pressActions: [.paste])]
        }
        return [:]
    }

    func label<ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable>(width: CGFloat, theme: ThemeData<ThemeExtension>, states: VariableStates) -> KeyLabel<Extension> {
        switch SemiStaticStates.shared.needsInputModeSwitchKey {
        case true:
            return KeyLabel(.changeKeyboard, width: width)
        case false:
            return KeyLabel(.image("arrowtriangle.left.and.line.vertical.and.arrowtriangle.right"), width: width)
        }
    }

    func backgroundStyleWhenUnpressed(states: VariableStates, theme: ThemeData<some ApplicationSpecificTheme>) -> FlickKeyBackgroundStyleValue {
        theme.specialKeyFillColor.flickKeyBackgroundStyle
    }

    func feedback(variableStates: VariableStates) {
        KeyboardFeedback<Extension>.tabOrOtherKey()
    }
}
