//
//  DisplayedTextManager.swift
//  Keyboard
//
//  Created by ensan on 2022/12/30.
//  Copyright © 2022 ensan. All rights reserved.
//

import KanaKanjiConverterModule
import SwiftUtils
import UIKit

/// UI側の入力中のテキストの更新を受け持つクラス
final public class DisplayedTextManager {
    public init(isLiveConversionEnabled: Bool, isMarkedTextEnabled: Bool) {
        self.isLiveConversionEnabled = isLiveConversionEnabled
        self.isMarkedTextEnabled = isMarkedTextEnabled
    }
    /// `convertTarget`に対応する文字列
    private(set) public var composingText: ComposingText = .init()
    /// ライブ変換の有効化状態
    private(set) public var isLiveConversionEnabled: Bool
    /// ライブ変換結果として表示されるべきテキスト
    private(set) public var displayedLiveConversionText: String?
    /// テキストを変更するたびに増やす値
    private var textChangedCount = 0
    private var expectedEditTracker = ExpectedEditTracker()

    /// `textChangedCount`のgetter。
    public func getTextChangedCount() -> Int {
        self.textChangedCount
    }

    /// marked textの有効化状態
    private(set) var isMarkedTextEnabled: Bool
    private var proxy: (any UITextDocumentProxy)? {
        switch preferredTextProxy {
        case .main: return displayedTextProxy
        case .ikTextField: return ikTextFieldProxy?.proxy ?? displayedTextProxy
        }
    }

    private var preferredTextProxy: AnyTextDocumentProxy.Preference = .main
    /// キーボード外のテキストを扱う`UITextDocumentProxy`
    private var displayedTextProxy: (any UITextDocumentProxy)?
    /// キーボード内テキストフィールドの`UITextDocumentProxy`
    private var ikTextFieldProxy: (id: UUID, proxy: (any UITextDocumentProxy))?

    public func setTextDocumentProxy(_ proxy: AnyTextDocumentProxy) {
        switch proxy {
        case let .mainProxy(proxy):
            self.displayedTextProxy = proxy
        case let .ikTextFieldProxy(id, proxy):
            if let proxy {
                self.ikTextFieldProxy = (id, proxy)
            } else if let (currentId, _) = ikTextFieldProxy, currentId == id {
                self.ikTextFieldProxy = nil
                self.preferredTextProxy = .main
            }
        case let .preference(preference):
            self.preferredTextProxy = preference
        }
    }

    @MainActor public var documentContextAfterInput: String? {
        self.proxy?.documentContextAfterInput
    }

    @MainActor public var selectedText: String? {
        self.proxy?.selectedText
    }

    @MainActor public func documentContextBeforeInput(ignoreComposition: Bool = false) -> String? {
        if ignoreComposition, !self.isMarkedTextEnabled {
            if let leftText = self.proxy?.documentContextBeforeInput {
                let possibleSuffix = self.displayedLiveConversionText ?? self.composingText.convertTarget
                if leftText.hasSuffix(possibleSuffix) {
                    return String(leftText.dropLast(possibleSuffix.count))
                } else {
                    return leftText
                }
            } else {
                return nil
            }
        } else {
            return self.proxy?.documentContextBeforeInput
        }
    }

    public var shouldSkipMarkedTextChange: Bool {
        self.isMarkedTextEnabled && preferredTextProxy == .ikTextField && ikTextFieldProxy != nil
    }

    public func closeKeyboard() {
        self.ikTextFieldProxy = nil
    }

    /// 入力を停止する
    /// - note: この関数を呼んだ後に`updateSettings`を呼ぶと良い
    @MainActor public func stopComposition() {
        debug("DisplayedTextManager.stopComposition")
        if self.isMarkedTextEnabled {
            self.observeExpectedEdit(label: "unmarkText") {
                self.proxy?.unmarkText()
            }
        } else {
            // Do nothing
        }
        self.composingText = .init()
        self.displayedLiveConversionText = nil
    }

    /// 設定を更新する
    @MainActor public func updateSettings(isLiveConversionEnabled: Bool, isMarkedTextEnabled: Bool) {
        self.isLiveConversionEnabled = isLiveConversionEnabled
        self.isMarkedTextEnabled = isMarkedTextEnabled
    }

    /// カーソルを何カウント分動かせばいいか計算する
    @MainActor private func getActualOffset(count: Int) -> Int {
        if count == 0 {
            return 0
        } else if count > 0 {
            if let after = self.proxy?.documentContextAfterInput {
                // 改行があって右端の場合ここに来る。
                if after.isEmpty {
                    return 1
                }
                let suf = after.prefix(count)
                return suf.utf16.count
            } else {
                return 1
            }
        } else {
            if let before = self.proxy?.documentContextBeforeInput {
                let pre = before.suffix(-count)
                return -pre.utf16.count
            } else {
                return -1
            }
        }
    }

    /// MarkedTextを更新する関数
    /// この関数自体はisMarkedTextEnabledのチェックを行わない。
    @MainActor private func updateMarkedText() {
        let text = self.displayedLiveConversionText ?? self.composingText.convertTarget
        let cursorPosition = self.displayedLiveConversionText.map(NSString.init(string:))?.length ?? NSString(string: String(self.composingText.convertTarget.prefix(self.composingText.convertTargetCursorPosition))).length
        let before = self.observedTextState()
        self.proxy?.setMarkedText(text, selectedRange: NSRange(location: cursorPosition, length: 0))
        let after = before.map {
            self.observedStateByApplyingMarkedText(text, selectedRange: NSRange(location: cursorPosition, length: 0), to: $0)
        }
        self.expectedEditTracker.record(before: before, after: after)
    }

    @MainActor
    private func observedStateByApplyingMarkedText(_ markedText: String, selectedRange: NSRange, to before: ObservedTextState) -> ObservedTextState {
        let nsText = markedText as NSString
        let cursorLocation = max(0, min(selectedRange.location, nsText.length))
        let leftMarkedText = nsText.substring(to: cursorLocation)
        let rightMarkedText = nsText.substring(from: cursorLocation)
        return .init(
            left: before.left + leftMarkedText,
            center: "",
            right: rightMarkedText + before.right
        )
    }

    @MainActor
    private func recordExpectedEdit(before: ObservedTextState?, after: ObservedTextState?, label: String) {
        self.expectedEditTracker.record(before: before, after: after)
    }

    @MainActor
    private func observeExpectedEdit<T>(on proxy: (any UITextDocumentProxy)? = nil, label: String, _ body: () -> T) -> T {
        let before = self.observedTextState(for: proxy)
        let result = body()
        let after = self.observedTextState(for: proxy)
        self.recordExpectedEdit(before: before, after: after, label: label)
        return result
    }

    @MainActor
    public func insertText(_ text: String) {
        guard !text.isEmpty else {
            return
        }
        self.observeExpectedEdit(label: "insertText(\(text))") {
            self.proxy?.insertText(text)
        }
        self.textChangedCount += 1
    }

    /// In-Keyboard TextFiledが用いられていても、そちらではない方に強制的に入力を行う関数
    @MainActor public func insertMainDisplayText(_ text: String) {
        guard !text.isEmpty else {
            return
        }
        self.observeExpectedEdit(on: self.displayedTextProxy, label: "insertMainDisplayText(\(text))") {
            self.displayedTextProxy?.insertText(text)
        }
        self.textChangedCount += 1
    }

    @MainActor public func moveCursor(count: Int) {
        guard count != 0 else {
            return
        }
        let offset = self.getActualOffset(count: count)
        self.observeExpectedEdit(label: "moveCursor(\(count) -> \(offset))") {
            self.proxy?.adjustTextPosition(byCharacterOffset: offset)
        }
        self.textChangedCount += 1
    }

    // ただ与えられた回数の削除を実行する関数
    @MainActor private func rawDeleteBackward(count: Int = 1) {
        guard count != 0 else {
            return
        }
        for _ in 0 ..< count {
            self.observeExpectedEdit(label: "deleteBackward") {
                self.proxy?.deleteBackward()
            }
        }
        self.textChangedCount += 1
    }

    // isComposingの場合、countはadjust済みであることを期待する
    // されていなかった場合は例外を投げる
    @MainActor public func deleteBackward(count: Int) {
        if count == 0 {
            return
        }
        if count < 0 {
            self.deleteForward(count: abs(count))
            return
        }
        self.rawDeleteBackward(count: count)
    }

    // ただ与えられた回数の削除を入力方向に実行する関数
    // カーソルが動かせない場合を検知するために工夫を入れている
    // TODO: iOS16以降のテキストフィールドの仕様変更で動かなくなっている。直す必要があるが、どうしようもない気がしている。
    @MainActor private func rawDeleteForward(count: Int) {
        guard count != 0 else {
            return
        }
        for _ in 0 ..< count {
            let before_b = self.proxy?.documentContextBeforeInput
            let before_a = self.proxy?.documentContextAfterInput
            self.moveCursor(count: 1)
            if before_a != self.proxy?.documentContextAfterInput || before_b != self.proxy?.documentContextBeforeInput {
                self.proxy?.deleteBackward()
            } else {
                return
            }
        }
        self.textChangedCount += 1
    }

    // isComposingの場合、countはadjust済みであることを期待する
    // されていなかった場合は例外を投げる
    @MainActor public func deleteForward(count: Int = 1) {
        if count == 0 {
            return
        }
        if count < 0 {
            self.deleteBackward(count: abs(count))
            return
        }
        self.rawDeleteForward(count: count)
    }

    /// `composingText`を更新する
    @MainActor public func updateComposingText(composingText: ComposingText, newLiveConversionText: String?) {
        if isMarkedTextEnabled {
            self.composingText = composingText
            self.displayedLiveConversionText = newLiveConversionText
            self.updateMarkedText()
        } else {
            let oldDisplayedText = displayedLiveConversionText ?? self.composingText.convertTarget
            let oldCursorPosition = displayedLiveConversionText?.count ?? self.composingText.convertTargetCursorPosition
            let newDisplayedText = newLiveConversionText ?? composingText.convertTarget
            let newCursorPosition = newLiveConversionText?.count ?? composingText.convertTargetCursorPosition
            self.composingText = composingText
            self.displayedLiveConversionText = newLiveConversionText
            // アップデートのアルゴリズム
            // まず、カーソルをcomposingTextの右端に移動する
            // ついで差分を計算し、必要な分だけ削除して修正する
            // 最後にもう一度カーソルを動かす
            let commonPrefix = oldDisplayedText.commonPrefix(with: newDisplayedText)
            let delete = oldDisplayedText.count - commonPrefix.count
            let input = newDisplayedText.suffix(newDisplayedText.count - commonPrefix.count)

            self.moveCursor(count: oldDisplayedText.count - oldCursorPosition)
            self.rawDeleteBackward(count: delete)
            self.observeExpectedEdit(label: "insertComposingText(\(String(input)))") {
                self.proxy?.insertText(String(input))
            }
            self.moveCursor(count: newCursorPosition - newDisplayedText.count)
        }
    }

    @MainActor public func updateComposingText(composingText: ComposingText, userMovedCount: Int, adjustedMovedCount: Int) -> Bool {
        let delta = adjustedMovedCount - userMovedCount
        self.composingText = composingText
        if delta != 0 {
            let offset = self.getActualOffset(count: delta)
            self.observeExpectedEdit(label: "userMovedCursorDelta(\(delta) -> \(offset))") {
                self.proxy?.adjustTextPosition(byCharacterOffset: offset)
            }
            return true
        }
        return false
    }

    @MainActor public func updateComposingText(composingText: ComposingText, completedPrefix: String, isSelected: Bool) {
        if isMarkedTextEnabled {
            self.insertText(completedPrefix)
            self.composingText = composingText
            self.displayedLiveConversionText = nil
            self.updateMarkedText()
        } else {
            // (例１): [あいし|てる] (「あい」を確定)
            // (削除): [|てる]
            // (挿入): 愛[|てる]
            // (挿入): 愛[し|てる]
            // (移動): 愛[し|てる]
            //
            // (例２): [あい|してる] (「あい」を確定)
            // (削除): [|してる]
            // (挿入): 愛[|してる]
            // (挿入): 愛[|してる]
            // (移動): 愛[してる|]
            // (例３): [愛してる|] (「愛してる」をライブ変換しており、そのまま確定)
            // (何もしない)
            defer {
                self.composingText = composingText
                self.displayedLiveConversionText = nil
            }
            // 例３のケース
            if composingText.isEmpty && completedPrefix == self.displayedLiveConversionText {
                return
            }
            // 選択中でない場合、必要なだけ削除を実行する
            if !isSelected {
                let count = self.displayedLiveConversionText?.count ?? self.composingText.convertTargetCursorPosition
                self.deleteBackward(count: count)
            }
            let delta = self.composingText.convertTarget.count - composingText.convertTarget.count
            let cursorPosition = self.composingText.convertTargetCursorPosition - delta
            self.insertText(completedPrefix + String(self.composingText.convertTargetBeforeCursor.suffix(cursorPosition)))
            self.moveCursor(count: composingText.convertTargetCursorPosition - cursorPosition)
        }
    }

    @MainActor
    public func updateComposingText(completedPrefix: String, composingText: ComposingText, newLiveConversionText: String?) {
        if isMarkedTextEnabled {
            self.insertText(completedPrefix)
            self.composingText = composingText
            self.displayedLiveConversionText = newLiveConversionText
            self.updateMarkedText()
            return
        }

        let oldDisplayedText = self.displayedLiveConversionText ?? self.composingText.convertTarget
        let oldCursorPosition = self.displayedLiveConversionText?.count ?? self.composingText.convertTargetCursorPosition
        let newDisplayedText = newLiveConversionText ?? composingText.convertTarget
        let newCursorPosition = newLiveConversionText?.count ?? composingText.convertTargetCursorPosition

        self.moveCursor(count: oldDisplayedText.count - oldCursorPosition)
        self.rawDeleteBackward(count: oldDisplayedText.count)
        self.insertText(completedPrefix + newDisplayedText)
        self.moveCursor(count: newCursorPosition - newDisplayedText.count)

        self.composingText = composingText
        self.displayedLiveConversionText = newLiveConversionText
    }

    @MainActor
    public func consumeExpectedEdit(before: ObservedTextState, after: ObservedTextState) -> ExpectedEditTracker.Consumption {
        self.expectedEditTracker.consume(before: before, after: after)
    }

    @MainActor
    private func observedTextState(for proxy: (any UITextDocumentProxy)? = nil) -> ObservedTextState? {
        let proxy = proxy ?? self.proxy
        guard let proxy else {
            return nil
        }
        return .init(
            left: proxy.documentContextBeforeInput ?? "",
            center: proxy.selectedText ?? "",
            right: proxy.documentContextAfterInput ?? ""
        )
    }
}
