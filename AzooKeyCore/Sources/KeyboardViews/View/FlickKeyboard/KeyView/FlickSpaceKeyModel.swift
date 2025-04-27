//
//  FlickSpaceKeyModel.swift
//  azooKey
//
//  Created by ensan on 2021/02/07.
//  Copyright © 2021 ensan. All rights reserved.
//

import CustardKit
import Foundation
import KeyboardThemes
import SwiftUI

struct FlickSpaceKeyModel<Extension: ApplicationSpecificKeyboardViewExtension>: FlickKeyModelProtocol {
    static var shared: Self { FlickSpaceKeyModel<Extension>() }
    let needSuggestView = true

    func flickKeys(variableStates: VariableStates) -> [FlickDirection: FlickedKeyModel] {
        flickKeys
    }

    private let flickKeys: [FlickDirection: FlickedKeyModel] = [
        .left: FlickedKeyModel(
            labelType: .text("←"),
            pressActions: [.moveCursor(-1)],
            longPressActions: .init(repeat: [.moveCursor(-1)])
        ),
        .top: FlickedKeyModel(
            labelType: .text("全角"),
            pressActions: [.input("　")]
        ),
        .bottom: FlickedKeyModel(
            labelType: .text("Tab"),
            pressActions: [.input("\u{0009}")]
        )
    ]

    func pressActions(variableStates: VariableStates) -> [ActionType] {
        [.input(" ")]
    }

    func longPressActions(variableStates _: VariableStates) -> LongpressActionType {
        .init(start: [.setCursorBar(.toggle)])
    }

    func label<ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable>(width: CGFloat, theme: ThemeData<ThemeExtension>, states: VariableStates) -> KeyLabel<Extension> {
        KeyLabel(.text("空白"), width: width)
    }

    func backgroundStyleWhenUnpressed(states: VariableStates, theme: ThemeData<some ApplicationSpecificTheme>) -> FlickKeyBackgroundStyleValue {
        theme.specialKeyFillColor.flickKeyBackgroundStyle
    }

    func feedback(variableStates: VariableStates) {
        KeyboardFeedback<Extension>.click()
    }
}
