//
//  TabKeyModel.swift
//  Keyboard
//
//  Created by ensan on 2020/04/12.
//  Copyright © 2020 ensan. All rights reserved.
//

import CustardKit
import Foundation
import KeyboardThemes
import SwiftUI

struct FlickTabKeyModel<Extension: ApplicationSpecificKeyboardViewExtension>: FlickKeyModelProtocol {
    private let data: KeyFlickSetting.SettingData
    let needSuggestView: Bool = true

    @MainActor static func hiraTabKeyModel() -> Self { FlickTabKeyModel(tab: .user_dependent(.japanese), key: .hiraTab) }
    @MainActor static func abcTabKeyModel() -> Self {  FlickTabKeyModel(tab: .user_dependent(.english), key: .abcTab) }
    @MainActor static func numberTabKeyModel() -> Self {  FlickTabKeyModel(tab: .existential(.flick_numbersymbols), key: .symbolsTab) }

    func pressActions(variableStates: VariableStates) -> [ActionType] {
        self.data.actions
    }
    func longPressActions(variableStates _: VariableStates) -> LongpressActionType {
        self.data.longpressActions
    }

    func flickKeys(variableStates: VariableStates) -> [FlickDirection: FlickedKeyModel] {
        self.data.flick
    }

    private var tab: KeyboardTab

    @MainActor private init(tab: KeyboardTab, key: CustomizableFlickKey) {
        self.data = Extension.SettingProvider.get(key)
        self.tab = tab
    }

    func label<ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable>(width: CGFloat, theme: ThemeData<ThemeExtension>, states: VariableStates) -> KeyLabel<Extension> {
        KeyLabel(self.data.labelType, width: width)
    }

    func backgroundStyleWhenUnpressed(states: VariableStates, theme: ThemeData<some ApplicationSpecificTheme>) -> FlickKeyBackgroundStyleValue {
        if states.tabManager.isCurrentTab(tab: tab) {
            theme.pushedKeyFillColor.flickKeyBackgroundStyle
        } else {
            theme.specialKeyFillColor.flickKeyBackgroundStyle
        }
    }

    func feedback(variableStates: VariableStates) {
        KeyboardFeedback<Extension>.tabOrOtherKey()
    }
}
