//
//  UserActionManager.swift
//  Keyboard
//
//  Created by ensan on 2021/02/06.
//  Copyright © 2021 ensan. All rights reserved.
//

import Foundation
import KeyboardExtensionUtils
import SwiftUI

/// キーボードの操作を管理するためのクラス
open class UserActionManager: @unchecked Sendable {
    public init() {}
    @MainActor open func registerAction(_ action: ActionType, variableStates: VariableStates) {}
    @MainActor open func registerActions(_ actions: [ActionType], variableStates: VariableStates) {}
    /// 長押し成立時に状態を更新してから入力する。falseならstart/repeatのどちらも実行しない。
    @MainActor open func reserveLongPressAction(_ action: LongpressActionType, taskStartDuration: Double, variableStates: VariableStates, onStart: @escaping @MainActor () -> Bool = { true }) {}
    @MainActor open func registerLongPressActionEnd(_ action: LongpressActionType) {}
    @MainActor open func setTextDocumentProxy(_ proxy: AnyTextDocumentProxy) {}
    @MainActor open func notifyComplete(_ candidate: any ResultViewItemData, variableStates: VariableStates) {}
    @MainActor open func notifyForgetCandidate(_ candidate: any ResultViewItemData, variableStates: VariableStates) {}
    @MainActor open func notifyReportWrongConversion(_ candidate: any ResultViewItemData, index: Int?, variableStates: VariableStates) async {}
    @MainActor open func prepareReportSuggestion(candidate: any ResultViewItemData, index: Int, variableStates: VariableStates) {}
    @MainActor open func reportSuggestion(_ content: ReportContent, variableStates: VariableStates) async -> Bool { false }
    @MainActor open func presentReportDetail(_ content: ReportContent, variableStates: VariableStates) {}
    @MainActor open func dismissReportDetail(variableStates: VariableStates) {}
    @MainActor open func notifySomethingWillChange(left: String, center: String, right: String) {}
    @MainActor open func notifySomethingDidChange(a_left: String, a_center: String, a_right: String, variableStates: VariableStates) {}

    @MainActor open func makeChangeKeyboardButtonView<Extension: ApplicationSpecificKeyboardViewExtension>() -> ChangeKeyboardButtonView<Extension> {
        ChangeKeyboardButtonView(selector: nil, size: Design.fonts.iconFontSize(keyViewFontSizePreference: Extension.SettingProvider.keyViewFontSize))
    }
}
