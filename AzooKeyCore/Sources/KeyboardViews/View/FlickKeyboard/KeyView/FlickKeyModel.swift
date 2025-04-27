//
//  KeyModel.swift
//  Keyboard
//
//  Created by ensan on 2020/04/11.
//  Copyright © 2020 ensan. All rights reserved.
//

import CustardKit
import Foundation
import KeyboardThemes
import SwiftUI

struct FlickKeyModel<Extension: ApplicationSpecificKeyboardViewExtension>: FlickKeyModelProtocol {
    static var delete: Self { Self(labelType: .image("delete.left"), pressActions: [.delete(1)], longPressActions: .init(repeat: [.delete(1)]), flickKeys: [
        .left: FlickedKeyModel(
            labelType: .image("xmark"),
            pressActions: [.smoothDelete]
        )
    ], needSuggestView: false, keycolorType: .tabkey)
    }

    let needSuggestView: Bool
    private let flickKeys: [FlickDirection: FlickedKeyModel]

    let labelType: KeyLabelType
    private let pressActions: [ActionType]
    let longPressActions: LongpressActionType
    private let keycolorType: FlickKeyBackgroundStyle

    init(labelType: KeyLabelType, pressActions: [ActionType], longPressActions: LongpressActionType = .none, flickKeys: [FlickDirection: FlickedKeyModel], needSuggestView: Bool = true, keycolorType: FlickKeyBackgroundStyle = .normal) {
        self.labelType = labelType
        self.pressActions = pressActions
        self.longPressActions = longPressActions
        self.flickKeys = flickKeys
        self.needSuggestView = needSuggestView
        self.keycolorType = keycolorType
    }

    func backgroundStyleWhenUnpressed(states: VariableStates, theme: ThemeData<some ApplicationSpecificTheme>) -> FlickKeyBackgroundStyleValue {
        keycolorType.backgroundStyle(theme: theme)
    }

    func pressActions(variableStates: VariableStates) -> [ActionType] {
        self.pressActions
    }

    func longPressActions(variableStates: VariableStates) -> LongpressActionType {
        self.longPressActions
    }

    func flickKeys(variableStates: VariableStates) -> [FlickDirection: FlickedKeyModel] {
        self.flickKeys
    }

    func label<ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable>(width: CGFloat, theme: ThemeData<ThemeExtension>, states: VariableStates) -> KeyLabel<Extension> {
        KeyLabel(self.labelType, width: width)
    }

    func feedback(variableStates: VariableStates) {
        self.pressActions.first?.feedback(variableStates: variableStates, extension: Extension.self)
    }
}
