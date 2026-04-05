//
//  KeyboardActionManager.swift
//  azooKey
//
//  Created by ensan on 2020/04/10.
//  Copyright © 2020 ensan. All rights reserved.
//

import AzooKeyUtils
import Foundation
import KanaKanjiConverterModule
import KeyboardViews
import enum KeyboardExtensionUtils.AnyTextDocumentProxy
import SwiftUI
import SwiftUtils

/// キーボードへのアクション部門の動作を担う。
final class KeyboardActionManager: UserActionManager, @unchecked Sendable {
    override init() {}

    var inputManager = InputManager()
    private weak var delegate: KeyboardViewController?

    // 即時変数
    private var tasks: [(type: LongpressActionType, task: Task<Void, any Error>)] = []
    private var tempTextData: (left: String, center: String, right: String)?
    private var pendingReportDismissTask: Task<Void, Never>?

    // キーボードを閉じる際に呼び出す
    // inputManagerはキーボードを閉じる際にある種の操作を行う
    @MainActor func closeKeyboard() {
        self.inputManager.closeKeyboard()
        for (_, task) in self.tasks {
            task.cancel()
        }
        self.tasks = []
        self.tempTextData = nil
    }

    @MainActor func importDynamicUserDictionary(_ userDictionary: [DicdataElement]) {
        self.inputManager.importDynamicUserDictionary(userDictionary)
    }

    @MainActor  func setDelegateViewController(_ controller: KeyboardViewController) {
        self.delegate = controller
        self.inputManager.setTextDocumentProxy(.mainProxy(controller.textDocumentProxy))
    }

    @MainActor func setResultViewUpdateCallback(_ variableStates: VariableStates) {
        self.inputManager.setUpdateResult { [weak variableStates, weak self] update in
            if let variableStates {
                update(&variableStates.resultModel)
                self?.refreshUpsideComponent(for: variableStates)
            }
        }
    }

    override func setTextDocumentProxy(_ proxy: AnyTextDocumentProxy) {
        self.inputManager.setTextDocumentProxy(proxy)
    }

    override func makeChangeKeyboardButtonView<Extension: ApplicationSpecificKeyboardViewExtension>() -> ChangeKeyboardButtonView<Extension> {
        delegate?.makeChangeKeyboardButtonView(size: Design.fonts.iconFontSize(keyViewFontSizePreference: Extension.SettingProvider.keyViewFontSize)) ?? ChangeKeyboardButtonView(selector: nil, size: Design.fonts.iconFontSize(keyViewFontSizePreference: Extension.SettingProvider.keyViewFontSize))
    }

    /// 変換を確定した場合に呼ばれる。
    /// - Parameters:
    ///   - candidate: 確定された候補。
    ///   - variableStates: 状態。
    override func notifyComplete(_ candidate: any ResultViewItemData, variableStates: VariableStates) {
        if let candidate = candidate as? Candidate {
            self.inputManager.complete(candidate: candidate)
            self.registerActions(candidate.actions.map(\.action), variableStates: variableStates)
        } else if let candidate = candidate as? ReplacementCandidate {
            self.inputManager.replaceLastCharacters(table: [candidate.target: candidate.replace], inputStyle: .direct)
            variableStates.keyboardInternalSettingManager.update(\.tabCharacterPreference) { item in
                switch candidate.targetType {
                case .emoji:
                    item.setPreference(base: candidate.base, replace: candidate.replace, for: .system(.emoji))
                }
            }
        } else if let candidate = candidate as? PostCompositionPredictionCandidate {
            self.inputManager.input(text: candidate.text, simpleInsert: true, inputStyle: .direct)
            if !candidate.isTerminal {
                self.inputManager.postCompositionPredictionCandidateSelected(candidate: candidate)
            } else {
                self.inputManager.resetPostCompositionPredictionCandidates()
            }
        } else if candidate is EmojiTabShortcutCandidate {
            // 入力を削除して絵文字タブに移動する
            self.inputManager.deleteBackward(convertTargetCount: self.inputManager.composingText.convertTargetCursorPosition)
            self.inputManager.stopComposition()
            self.setTextDocumentProxy(.preference(.main))
            self.registerActions([.setUpsideComponent(nil), .moveTab(.system(.emoji_tab))], variableStates: variableStates)
        } else {
            debug("notifyComplete: 確定できません")
        }
        // 左右の文字列
        let (left, center, right) = self.inputManager.getSurroundingText()
        // MARK: Replacementの更新をする
        let target = variableStates.tabManager.existentialTab().replacementTarget
        if !target.isEmpty {
            self.inputManager.updateTextReplacementCandidates(left: left, center: center, right: right, target: target)
        }
        // エンターキーの状態の更新
        variableStates.setEnterKeyState(self.inputManager.getEnterKeyState())
    }

    override func notifyForgetCandidate(_ candidate: any ResultViewItemData, variableStates: VariableStates) {
        if let candidate = candidate as? Candidate {
            self.inputManager.forgetMemory(candidate)
            variableStates.temporalMessage = .doneForgetCandidate
        }
    }

    @MainActor override func notifyReportWrongConversion(_ candidate: any ResultViewItemData, index: Int?, variableStates: VariableStates) async {
        await handleReportWrongConversion(candidate, index: index, variableStates: variableStates)
    }

    @MainActor override func prepareReportSuggestion(candidate: any ResultViewItemData, index: Int, variableStates: VariableStates) {
        handlePrepareReportSuggestion(candidate: candidate, index: index, variableStates: variableStates)
    }

    @MainActor override func reportSuggestion(_ content: ReportContent, variableStates: VariableStates) async -> Bool {
        await handleReportSuggestion(content, variableStates: variableStates)
    }

    @MainActor override func presentReportDetail(_ content: ReportContent, variableStates: VariableStates) {
        handlePresentReportDetail(content, variableStates: variableStates)
    }

    @MainActor override func dismissReportDetail(variableStates: VariableStates) {
        handleDismissReportDetail(variableStates: variableStates)
    }

    private func showResultView(variableStates: VariableStates) {
        variableStates.barState = .none
    }

    @MainActor
    private func textEditingActionDidBegin(variableStates: VariableStates) {
        self.showResultView(variableStates: variableStates)
        self.dismissReportInterfacesIfNeeded(variableStates: variableStates)
    }

    @MainActor private func shiftStateOff(variableStates: VariableStates) {
        variableStates.boolStates[VariableStates.BoolStates.isShiftedKey] = false
    }

    @MainActor private func doAction(_ action: ActionType, requireSetResult: Bool = true, variableStates: VariableStates) {
        debug("doAction", action)
        var undoAction: ActionType?
        switch action {
        case let .input(text, simpleInsert):
            self.textEditingActionDidBegin(variableStates: variableStates)
            let input: String
            if (variableStates.boolStates.isCapsLocked || variableStates.boolStates.isShifted) && [.en_US, .el_GR].contains(variableStates.keyboardLanguage) {
                input = text.uppercased()
            } else {
                input = text
            }

            if let candidate = variableStates.resultModel.getSelectedCandidate() {
                if let candidate = candidate as? Candidate,
                   requireSetResult,
                   self.inputManager.completeAndStartNewComposition(candidate: candidate, with: input, simpleInsert: simpleInsert, inputStyle: variableStates.inputStyle) {
                    self.registerActions(candidate.actions.map(\.action), variableStates: variableStates)
                    let (left, center, right) = self.inputManager.getSurroundingText()
                    let target = variableStates.tabManager.existentialTab().replacementTarget
                    if !target.isEmpty {
                        self.inputManager.updateTextReplacementCandidates(left: left, center: center, right: right, target: target)
                    }
                    variableStates.setEnterKeyState(self.inputManager.getEnterKeyState())
                } else {
                    self.notifyComplete(candidate, variableStates: variableStates)
                    self.inputManager.input(text: input, requireSetResult: requireSetResult, simpleInsert: simpleInsert, inputStyle: variableStates.inputStyle)
                }
            } else {
                self.inputManager.input(text: input, requireSetResult: requireSetResult, simpleInsert: simpleInsert, inputStyle: variableStates.inputStyle)
            }
            self.shiftStateOff(variableStates: variableStates)
        case let .insertMainDisplay(text):
            self.inputManager.insertMainDisplayText(text)
            self.shiftStateOff(variableStates: variableStates)
        case let .delete(count):
            self.textEditingActionDidBegin(variableStates: variableStates)
            self.shiftStateOff(variableStates: variableStates)
            self.inputManager.deleteBackward(convertTargetCount: count, requireSetResult: requireSetResult)
        case .smoothDelete:
            KeyboardFeedback<AzooKeyKeyboardViewExtension>.smoothDelete()
            self.textEditingActionDidBegin(variableStates: variableStates)
            self.shiftStateOff(variableStates: variableStates)
            let deletedText = self.inputManager.smoothDelete(requireSetResult: requireSetResult)
            if !deletedText.isEmpty {
                undoAction = .input(deletedText, simplyInsert: true)
            }
        case let .smartDelete(item):
            self.textEditingActionDidBegin(variableStates: variableStates)
            self.shiftStateOff(variableStates: variableStates)
            let deletedText: String
            switch item.direction {
            case .forward:
                deletedText = self.inputManager.smoothDeleteForward(to: item.targets.map {Character($0)}, requireSetResult: requireSetResult)
            case .backward:
                deletedText = self.inputManager.smoothDelete(to: item.targets.map {Character($0)}, requireSetResult: requireSetResult)
            }
            if !deletedText.isEmpty {
                undoAction = .input(deletedText, simplyInsert: true)
            }
        case .paste:
            // ペーストではシフトを解除しない
            if SemiStaticStates.shared.hasFullAccess {
                self.inputManager.paste()
            }

        case let .moveCursor(count):
            // カーソル移動ではシフトを解除しない
            self.inputManager.moveCursor(count: count, requireSetResult: requireSetResult)

        case let .smartMoveCursor(item):
            switch item.direction {
            case .forward:
                self.inputManager.smartMoveCursorForward(to: item.targets.map {Character($0)}, requireSetResult: requireSetResult)
            case .backward:
                self.inputManager.smartMoveCursorBackward(to: item.targets.map {Character($0)}, requireSetResult: requireSetResult)
            }

        case let .setCursorBar(operation):
            self.dismissReportInterfacesIfNeeded(variableStates: variableStates)
            let (left, center, right) = self.inputManager.getSurroundingText()
            variableStates.setSurroundingText(leftSide: left, center: center, rightSide: right)
            switch operation {
            case .on:
                variableStates.barState = .cursor
            case .off:
                variableStates.barState = .none
            case .toggle:
                if variableStates.barState == .cursor {
                    variableStates.barState = .none
                } else {
                    variableStates.barState = .cursor
                }
            }

        case .enter:
            self.textEditingActionDidBegin(variableStates: variableStates)
            self.shiftStateOff(variableStates: variableStates)
            if let candidate = variableStates.resultModel.getSelectedCandidate() {
                self.notifyComplete(candidate, variableStates: variableStates)
            } else {
                let actions = self.inputManager.enter(requireSetResult: requireSetResult)
                self.registerActions(actions, variableStates: variableStates)
            }
        case .completeCharacterForm(let forms):
            self.textEditingActionDidBegin(variableStates: variableStates)
            self.shiftStateOff(variableStates: variableStates)
            self.notifyComplete(self.inputManager.getCandidate(for: forms), variableStates: variableStates)

        case let .changeCharacterType(behavior):
            self.textEditingActionDidBegin(variableStates: variableStates)
            self.shiftStateOff(variableStates: variableStates)
            self.inputManager.changeCharacter(behavior: behavior, requireSetResult: requireSetResult, inputStyle: variableStates.inputStyle)

        case let .replaceLastCharacters(table):
            self.textEditingActionDidBegin(variableStates: variableStates)
            self.shiftStateOff(variableStates: variableStates)
            self.inputManager.replaceLastCharacters(table: table, requireSetResult: requireSetResult, inputStyle: variableStates.inputStyle)

        case let .selectCandidate(selection):
            variableStates.resultModel.setSelectionRequest(selection)
        case let .moveTab(type):
            // タブ移動ではシフトを解除しない
            self.dismissReportInterfacesIfNeeded(variableStates: variableStates)
            variableStates.setTab(type)

        case let .setUpsideComponent(type):
            self.applyUpsideComponent(type, variableStates: variableStates)

        case let .setTabBar(operation):
            self.dismissReportInterfacesIfNeeded(variableStates: variableStates)
            switch operation {
            case .on:
                variableStates.barState = .tab
            case .off:
                variableStates.barState = .none
            case .toggle:
                if variableStates.barState == .tab {
                    variableStates.barState = .none
                } else {
                    variableStates.barState = .tab
                }
            }

        case .enableResizingMode:
            variableStates.setResizingMode(.resizing)

        case .hideLearningMemory:
            self.hideLearningMemory()

        case .dismissKeyboard:
            self.delegate?.dismissKeyboard()

        case let .openApp(scheme):
            delegate?.openApp(scheme: scheme)

        case let .setBoolState(key, operation):
            switch operation {
            case .on:
                variableStates.boolStates[key] = true
            case .off:
                variableStates.boolStates[key] = false
            case .toggle:
                variableStates.boolStates[key]?.toggle()
            }
        case let .boolSwitch(compiledExpression, trueAction, falseAction):
            if let condition = variableStates.boolStates.evaluateExpression(compiledExpression) {
                if condition {
                    self.registerActions(trueAction, variableStates: variableStates)
                } else {
                    self.registerActions(falseAction, variableStates: variableStates)
                }
            }
        case let .setSearchQuery(query, target):
            let results = self.inputManager.getSearchResult(query: query, target: target)
            variableStates.resultModel.setSearchResults(results)
            self.refreshUpsideComponent(for: variableStates)
        }

        if requireSetResult {
            // MARK: VariableStateに操作の結果を反映する
            // 左右の文字列
            let (left, center, right) = self.inputManager.getSurroundingText()
            variableStates.setSurroundingText(leftSide: left, center: center, rightSide: right)
            // エンターキーの状態
            variableStates.setEnterKeyState(
                variableStates.resultModel.getSelectedCandidate() == nil ? self.inputManager.getEnterKeyState() : .complete
            )
            // 文字列の変更を適用
            variableStates.textChangedCount = self.inputManager.getTextChangedCount()
            // 必要に応じて予測変換をリセット
            self.inputManager.resetPostCompositionPredictionCandidatesIfNecessary(textChangedCount: variableStates.textChangedCount)

            if let undoAction {
                variableStates.undoAction = .init(action: undoAction, textChangedCount: variableStates.textChangedCount)
            }
            // MARK: 言語を更新する
            self.inputManager.setKeyboardLanguage(variableStates.keyboardLanguage)
            // MARK: Replacementの更新をする
            if !variableStates.tabManager.existentialTab().replacementTarget.isEmpty {
                self.inputManager.updateTextReplacementCandidates(left: left, center: center, right: right, target: variableStates.tabManager.existentialTab().replacementTarget)
            }
        }
    }

    @MainActor
    private func refreshUpsideComponent(for variableStates: VariableStates) {
        let current = variableStates.upsideComponent
        let hasSupplementary = variableStates.resultModel.hasSupplementaryCandidates

        var nextComponent = current
        if hasSupplementary {
            if current == nil || current == .supplementaryCandidates {
                nextComponent = .supplementaryCandidates
            }
        } else if current == .supplementaryCandidates {
            nextComponent = nil
        }

        if nextComponent != current {
            self.applyUpsideComponent(nextComponent, variableStates: variableStates)
        } else {
            variableStates.setHasUpsideComponent(variableStates.upsideComponent != nil)
        }
    }

    @MainActor
    func applyUpsideComponent(_ component: UpsideComponent?, variableStates: VariableStates) {
        if variableStates.upsideComponent == component {
            variableStates.setHasUpsideComponent(variableStates.upsideComponent != nil)
            return
        }

        self.delegate?.prepareScreenHeight(for: component)

        DispatchQueue.main.async { [weak variableStates, weak self] in
            guard let variableStates else {
                return
            }
            if component == nil {
                variableStates.reportSuggestionState?.clearTimestamp()
                self?.pendingReportDismissTask?.cancel()
                self?.pendingReportDismissTask = nil
            } else if case .reportSuggestion = component {
                self?.pendingReportDismissTask?.cancel()
                self?.pendingReportDismissTask = nil
            }
            variableStates.upsideComponent = component
            variableStates.setHasUpsideComponent(variableStates.upsideComponent != nil)
            self?.delegate?.updateScreenHeight()
        }
    }

    /// 押した場合に行われる。
    /// - Parameters:
    ///   - action: 行われた動作。
    override func registerAction(_ action: ActionType, variableStates: VariableStates) {
        self.doAction(action, variableStates: variableStates)
    }

    private enum ActionTriggerStyle {
        /// 集約対象ではない
        case irrelevant
        /// 集約を強制的に止める
        case separator
        /// 集約できるアクション
        case maybe
    }

    private func actionTriggerStyle(_ action: ActionType) -> ActionTriggerStyle {
        switch action {
        case .input, .delete, .changeCharacterType, .smoothDelete, .smartDelete, .moveCursor, .replaceLastCharacters, .smartMoveCursor:
            .maybe
        case .enter:
            .separator
        default:
            .irrelevant
        }
    }

    /// actionの塊を実行する
    ///  - parameters:
    ///    - actionBlock: アクションの一連の列。1つのブロックの中には任意個の集約対象のアクションと集約対象でないアクションが含まれ、先頭にのみ集約できないアクションが出現できる
    @MainActor private func runActionBlock(actionBlock: some BidirectionalCollection<ActionType>, variableStates: VariableStates) {
        // setResult可能な最後の
        if let lastIndex = actionBlock.lastIndex(where: { actionTriggerStyle($0) != .irrelevant }) {
            for (i, action) in zip(actionBlock.indices, actionBlock) {
                if i == lastIndex {
                    self.doAction(action, requireSetResult: true, variableStates: variableStates)
                } else {
                    self.doAction(action, requireSetResult: false, variableStates: variableStates)
                }
            }
        } else {
            for action in actionBlock {
                self.doAction(action, variableStates: variableStates)
            }
        }
    }

    /// 複数のアクションを実行する
    /// - note: アクションを実行する前に最適化を施すことでパフォーマンスを向上させる
    ///  サポートされている最適化
    /// - `setResult`を一度のみ実施する
    override func registerActions(_ actions: [ActionType], variableStates: VariableStates) {
        var actions = actions[...]
        while let firstIndex = actions.firstIndex(where: { actionTriggerStyle($0) == .separator }) {
            self.runActionBlock(actionBlock: actions[..<firstIndex], variableStates: variableStates)
            self.doAction(actions[firstIndex], variableStates: variableStates)
            actions = actions[(firstIndex + 1)...]
        }
        self.runActionBlock(actionBlock: actions, variableStates: variableStates)
    }

    @MainActor
    private func dismissReportInterfacesIfNeeded(variableStates: VariableStates) {
        if case .reportSuggestion = variableStates.upsideComponent, let reportSuggestionState = variableStates.reportSuggestionState {
            let minimumDisplayInterval: TimeInterval = 3  // 3秒
            let presentedAt = reportSuggestionState.presentedAt ?? Date()
            let elapsed = Date().timeIntervalSince(presentedAt)
            if elapsed >= minimumDisplayInterval {
                self.performReportDismiss(variableStates: variableStates)
            } else {
                pendingReportDismissTask?.cancel()
                pendingReportDismissTask = Task { @MainActor [weak self, weak variableStates] in
                    // 3秒程度表示しておく
                    try? await Task.sleep(for: .seconds(3))
                    guard let self, let variableStates else {
                        return
                    }
                    self.performReportDismiss(variableStates: variableStates)
                }
            }
        } else {
            pendingReportDismissTask?.cancel()
            pendingReportDismissTask = nil
            if variableStates.reportDetailState != nil {
                variableStates.reportDetailState = nil
            }
        }
    }

    @MainActor
    private func performReportDismiss(variableStates: VariableStates) {
        pendingReportDismissTask?.cancel()
        pendingReportDismissTask = nil
        self.applyUpsideComponent(nil, variableStates: variableStates)
        if variableStates.reportDetailState != nil {
            variableStates.reportDetailState = nil
        }
    }

    @MainActor
    /// 長押しを予約する関数。
    /// - Parameters:
    ///   - action: 長押しで起こる動作のタイプ。
    override func reserveLongPressAction(_ action: LongpressActionType, taskStartDuration: Double, variableStates: VariableStates) {
        if tasks.contains(where: {$0.type == action}) {
            return
        }
        let nanoseconds = UInt64(taskStartDuration * 1_000_000_000)
        let startTask = Task {
            try await Task.sleep(nanoseconds: nanoseconds)
            action.start.first?.feedback(variableStates: variableStates, extension: AzooKeyKeyboardViewExtension.self)
            self.registerActions(action.start, variableStates: variableStates)
        }
        self.tasks.append((type: action, task: startTask))

        let repeatTask = Task {
            try await Task.sleep(nanoseconds: nanoseconds)
            while !Task.isCancelled {
                action.repeat.first?.feedback(variableStates: variableStates, extension: AzooKeyKeyboardViewExtension.self)
                self.registerActions(action.repeat, variableStates: variableStates)
                try await Task.sleep(nanoseconds: 0_100_000_000)
            }
        }
        self.tasks.append((type: action, task: repeatTask))
    }

    /// 長押しを終了する関数。継続的な動作、例えば連続的な文字削除を行っていたタイマーを停止する。
    /// - Parameters:
    ///   - action: どの動作を終了するか判定するために用いる。
    override func registerLongPressActionEnd(_ action: LongpressActionType) {
        tasks = tasks.compactMap {task in
            if task.type == action {
                task.task.cancel()
                return nil
            }
            return task
        }
    }

    /// 何かが変化する前に状態の保存を行う関数。
    override func notifySomethingWillChange(left: String, center: String, right: String) {
        // self.tempTextDataが`nil`でない場合、上書きせず終了する
        guard self.tempTextData == nil else {
            debug("notifySomethingWillChange: There is already `tempTextData`: \(tempTextData!)")
            return
        }
        self.tempTextData = (left: left, center: center, right: right)
    }
    // MARK: iOS16以降
    /*
     |はカーソル位置。二つある場合は選択範囲
     ---------------------
     |abc              :nil/nil/abc
     ---------------------
     abc|def           :abc/nil/def
     ---------------------
     abc|def|ghi       :abc/def/ghi
     ---------------------
     abc|              :abc/nil/nil
     ---------------------
     abc|              :abc/nil/nil  // MARK: ここが以前と違う。以前はこの場合afterInputにEmptyが来ていたが、nilになっている。

     ---------------------
     :\n/nil/def
     |def
     ---------------------
     abc|              :abc/nil/nil  // MARK: ここが以前と違う。以前はこの場合afterInputにEmptyが来ていたが、nilになっている。
     def
     ---------------------
     abc
     |def              :abc\n/nil/def  // MARK: ここが以前と違う。以前はこの場合afterInputにEmptyが来ていたが、\nabcになっている。
     ---------------------
     a|bc
     d|ef              :a/bc \n d/ef
     ---------------------
     */

    // MARK: iOS15以前でleft/center/rightとして得られる情報は以下の通り
    /*
     |はカーソル位置。二つある場合は選択範囲
     ---------------------
     |abc              :nil/nil/abc
     ---------------------
     abc|def           :abc/nil/def
     ---------------------
     abc|def|ghi       :abc/def/ghi
     ---------------------
     abc|              :abc/nil/nil
     ---------------------
     abc|              :abc/nil/empty

     ---------------------
     :\n/nil/def
     |def
     ---------------------
     abc|              :abc/nil/empty
     def
     ---------------------
     abc
     |def              :\n/nil/def
     ---------------------
     a|bc
     d|ef              :a/bc \n d/ef
     ---------------------
     */

    /// 何かが変化した後に状態を比較し、どのような変化が起こったのか判断する関数。
    override func notifySomethingDidChange(a_left: String, a_center: String, a_right: String, variableStates: VariableStates) {
        defer {
            variableStates.setSurroundingText(leftSide: a_left, center: a_center, rightSide: a_right)
            // エンターキーの状態の更新
            variableStates.setEnterKeyState(self.inputManager.getEnterKeyState())
            // Replacementの更新
            if !variableStates.tabManager.existentialTab().replacementTarget.isEmpty {
                self.inputManager.updateTextReplacementCandidates(left: a_left, center: a_center, right: a_right, target: variableStates.tabManager.existentialTab().replacementTarget)
            }
        }
        // 前のデータが保存されていない場合は操作しない
        guard let (tempLeft, b_center, b_right) = self.tempTextData else {
            debug("notifySomethingDidChange: Could not found `tempTextData`")
            return
        }
        let expectedEditConsumption = self.inputManager.consumeExpectedEdit(
            beforeLeft: tempLeft,
            beforeCenter: b_center,
            beforeRight: b_right,
            afterLeft: a_left,
            afterCenter: a_center,
            afterRight: a_right
        )
        switch expectedEditConsumption {
        case .matched(let hasMoreEdits):
            self.tempTextData = hasMoreEdits ? (left: a_left, center: a_center, right: a_right) : nil
            return
        case .noMatch:
            break
        }

        // 終了時に必ずtempTextDataを`nil`にする
        defer {
            self.tempTextData = nil
        }

        // iOS16以降左側の文字列の設計が変わったので、adjustする
        let a_left = self.inputManager.adjustLeftString(a_left)
        let b_left = self.inputManager.adjustLeftString(tempLeft)

        let hasSomethingChanged = a_left != b_left || a_center != b_center || a_right != b_right
        if hasSomethingChanged {
            dismissReportInterfacesIfNeeded(variableStates: variableStates)
        }
        let a_wholeText = a_left + a_center + a_right
        // ライブ変換を行っていて入力中の場合、まずは確定してから話を進める
        if !self.inputManager.composingText.isEmpty && !self.inputManager.isSelected && self.inputManager.liveConversionManager.enabled && hasSomethingChanged {
            debug("in live conversion, user did change something: \((a_left, a_center, a_right)) \((b_left, b_center, b_right))")
            if a_wholeText.isEmpty {
                debug("it seems that the action is submission. just ignore it.")
                // 何もしない方が良い
                self.inputManager.stopComposition()
                return
            }
            _ = self.inputManager.enter(shouldModifyDisplayedText: false)
        }

        // この場合はユーザによる操作であると考えられる
        debug("user operation happend: \((a_left, a_center, a_right)), \((b_left, b_center, b_right))")

        let b_wholeText = b_left + b_center + b_right
        let isWholeTextChanged = a_wholeText != b_wholeText
        let wasSelected = !b_center.isEmpty
        let isSelected = !a_center.isEmpty

        if isSelected {
            debug("user operation id: 0", a_center)
            // 検索フィールドなどでは再変換を抑制する
            let lengthLimit: Int = switch variableStates.keyboardType {
            case .default, .twitter:
                switch variableStates.returnKeyType {
                case .emergencyCall:
                    0
                case .search, .google, .yahoo, .route:
                    5
                default:
                    100
                }
            case .decimalPad, .URL, .asciiCapableNumberPad, .emailAddress, .phonePad, .namePhonePad, .alphabet, .numbersAndPunctuation, .numberPad, .asciiCapable:
                0
            case .webSearch:
                5
            @unknown default:
                50
            }
            self.inputManager.userSelectedText(text: a_center, lengthLimit: lengthLimit)
            // barStateの更新
            variableStates.barState = .none
            return
        }

        // 全体としてテキストが変化せず、選択範囲が存在している場合→新たに選択した、または選択範囲を変更した
        if !isWholeTextChanged {
            // 全体としてテキストが変化せず、選択範囲が無くなっている場合→選択を解除した
            if wasSelected && !isSelected {
                self.inputManager.userDeselectedText()
                debug("user operation id: 1")
                return
            }

            // 全体としてテキストが変化せず、選択範囲は前後ともになく、左側(右側)の文字列だけが変わっていた場合→カーソルを移動した
            if !wasSelected && !isSelected && b_left != a_left {
                debug("user operation id: 2", b_left, a_left)
                let offset = a_left.count - b_left.count
                let actions = self.inputManager.userMovedCursor(count: offset)
                self.registerActions(actions, variableStates: variableStates)
                // カーソルが動いているのでtextChangedCountを増やす
                variableStates.textChangedCount += 1
                self.inputManager.resetPostCompositionPredictionCandidatesIfNecessary(textChangedCount: variableStates.textChangedCount)
                return
            }

            // MarkedTextを利用する設定では、ホスト側の送信や確定が起きても UITextDocumentProxy からは before/after の差分が見えず、no-op callback としてここに到達することがある。
            // このとき composition が残っているなら、外部要因で入力が閉じられたとみなして stopComposition し、内部状態をホスト側に合わせる。
            @KeyboardSetting(.markedTextSetting) var markedTextSetting
            if markedTextSetting != .disabled, !self.inputManager.composingText.isEmpty {
                debug("user operation id: 2.5")
                self.inputManager.stopComposition()
                return
            }
            // ただタップしただけ、などの場合ここにくる事がある。
            debug("user operation id: 3")

            return
        }
        // 以降isWholeTextChangedは常にtrue
        // 全体としてテキストが変化しており、前は左は改行コードになっていて選択範囲が存在し、かつ前の選択範囲と後の全体が一致する場合→行全体の選択が解除された
        // 行全体を選択している場合は改行コードが含まれる。

        defer {
            variableStates.textChangedCount += 1
            // 予測変換はテキストが変化したら解除する
            self.inputManager.resetPostCompositionPredictionCandidatesIfNecessary(textChangedCount: variableStates.textChangedCount)
        }

        if b_left == "\n" && b_center == a_wholeText {
            debug("user operation id: 5")
            self.inputManager.userDeselectedText()
            return
        }

        // 全体としてテキストが変化しており、左右の文字列を合わせたものが不変である場合→カットしたのではないか？
        if b_left + b_right == a_left + a_right {
            debug("user operation id: 6")
            self.inputManager.userCutText(text: b_center)
            return
        }

        // 全体としてテキストが変化しており、右側の文字列が不変であった場合→Undoしたと推測できる
        if b_left.hasPrefix(a_left) && b_right == a_right {
            debug("user operation id: 7")
            self.inputManager.stopComposition()
            return
        }

        if b_right == a_right {
            debug("user operation id: 8")
            self.inputManager.stopComposition()
            return
        }

        if a_left == "\n" && b_left.isEmpty && a_right == b_right {
            debug("user operation id: 9")
            self.inputManager.stopComposition()
            return
        }

        // 上記のどれにも引っかからず、なおかつテキスト全体が変更された場合→ユーザがカーソルをジャンプした
        debug("user operation id: 10, \((a_left, a_center, a_right)), \((b_left, b_center, b_right))")
        let actions = self.inputManager.userJumpedCursor()
        self.registerActions(actions, variableStates: variableStates)
    }

    private func hideLearningMemory() {
        // TODO: Provide up-to-date implementation
    }
}
