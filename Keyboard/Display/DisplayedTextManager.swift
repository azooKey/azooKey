//
//  DisplayedTextManager.swift
//  Keyboard
//
//  Created by ensan on 2022/12/30.
//  Copyright © 2022 ensan. All rights reserved.
//

import UIKit

/// UI側の入力中のテキストの更新を受け持つクラス
final class DisplayedTextManager {
    init() {
        @KeyboardSetting(.liveConversion) var enabled
        self.isLiveConversionEnabled = enabled

        @KeyboardSetting(.markedTextSetting) var markedTextEnabled
        self.isMarkedTextEnabled = markedTextEnabled != .disabled
    }
    /// `convertTarget`に対応する文字列
    private(set) var composingText: ComposingText = .init()
    /// ライブ変換の有効化状態
    private(set) var isLiveConversionEnabled: Bool
    /// ライブ変換結果として表示されるべきテキスト
    private(set) var displayedLiveConversionText: String?
    /// marked textの有効化状態
    private(set) var isMarkedTextEnabled: Bool
    private var proxy: UITextDocumentProxy! {
        if let inKeyboardProxy {
            return inKeyboardProxy
        }
        return displayedTextProxy
    }
    /// キーボード外のテキストを扱う`UITextDocumentProxy`
    private var displayedTextProxy: UITextDocumentProxy!
    /// キーボード内テキストフィールドの`UITextDocumentProxy`
    private var inKeyboardProxy: UITextDocumentProxy?

    func setTextDocumentProxy(_ proxy: UITextDocumentProxy!) {
        self.displayedTextProxy = proxy
    }

    func setInKeyboardProxy(_ proxy: UITextDocumentProxy?) {
        self.inKeyboardProxy = proxy
    }

    var documentContextAfterInput: String? {
        self.proxy.documentContextAfterInput
    }

    var selectedText: String? {
        self.proxy.selectedText
    }

    var documentContextBeforeInput: String? {
        self.proxy.documentContextBeforeInput
    }

    /// `ComposingText`を完全に削除し、無い状態にする
    func clear() {
        debug("DisplayedTextManager.clear")
        // 状態を全て削除する
        self.updateComposingText(composingText: ComposingText(), newLiveConversionText: nil)
        // 設定を更新する
        self.reloadSetting()
    }

    /// 設定を更新する
    private func reloadSetting() {
        @KeyboardSetting(.liveConversion) var enabled
        self.isLiveConversionEnabled = enabled
        @KeyboardSetting(.markedTextSetting) var markedTextEnabled
        self.isMarkedTextEnabled = markedTextEnabled != .disabled
    }

    /// カーソルを何カウント分動かせばいいか計算する
    private func getActualOffset(count: Int) -> Int {
        if count == 0 {
            return 0
        } else if count > 0 {
            if let after = self.proxy.documentContextAfterInput {
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
            if let before = self.proxy.documentContextBeforeInput {
                let pre = before.suffix(-count)
                return -pre.utf16.count
            } else {
                return -1
            }
        }
    }

    /// MarkedTextを更新する関数
    /// この関数自体はisMarkedTextEnabledのチェックを行わない。
    private func updateMarkedText() {
        let text = self.displayedLiveConversionText ?? self.composingText.convertTarget
        let cursorPosition = self.displayedLiveConversionText.map(NSString.init(string:))?.length ?? NSString(string: String(self.composingText.convertTarget.prefix(self.composingText.convertTargetCursorPosition))).length
        self.proxy.setMarkedText(text, selectedRange: NSRange(location: cursorPosition, length: 0))
    }

    func insertText(_ text: String) {
        guard !text.isEmpty else {
            return
        }
        self.proxy.insertText(text)
        VariableStates.shared.textChangedCount += 1
    }

    /// In-Keyboard TextFiledが用いられていても、そちらではない方に強制的に入力を行う関数
    func insertMainDisplayText(_ text: String) {
        guard !text.isEmpty else {
            return
        }
        self.displayedTextProxy.insertText(text)
        VariableStates.shared.textChangedCount += 1
    }

    func moveCursor(count: Int) {
        guard count != 0 else {
            return
        }
        let offset = self.getActualOffset(count: count)
        self.proxy.adjustTextPosition(byCharacterOffset: offset)
        VariableStates.shared.textChangedCount += 1
    }

    // ただ与えられた回数の削除を実行する関数
    private func rawDeleteBackward(count: Int = 1) {
        guard count != 0 else {
            return
        }
        for _ in 0 ..< count {
            self.proxy.deleteBackward()
        }
        VariableStates.shared.textChangedCount += 1
    }

    // isComposingの場合、countはadjust済みであることを期待する
    // されていなかった場合は例外を投げる
    func deleteBackward(count: Int) {
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
    private func rawDeleteForward(count: Int) {
        guard count != 0 else {
            return
        }
        for _ in 0 ..< count {
            let before_b = self.proxy.documentContextBeforeInput
            let before_a = self.proxy.documentContextAfterInput
            self.moveCursor(count: 1)
            if before_a != self.proxy.documentContextAfterInput || before_b != self.proxy.documentContextBeforeInput {
                self.proxy.deleteBackward()
            } else {
                return
            }
        }
        VariableStates.shared.textChangedCount += 1
    }

    // isComposingの場合、countはadjust済みであることを期待する
    // されていなかった場合は例外を投げる
    func deleteForward(count: Int = 1) {
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
    func updateComposingText(composingText: ComposingText, newLiveConversionText: String?) {
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
            self.proxy.insertText(String(input))
            self.moveCursor(count: newCursorPosition - newDisplayedText.count)
        }
    }

    func updateComposingText(composingText: ComposingText, userMovedCount: Int, composingTextOperation: ComposingText.ViewOperation) -> Bool {
        let delta = composingTextOperation.cursor - userMovedCount
        self.composingText = composingText
        if delta != 0 {
            let offset = self.getActualOffset(count: delta)
            self.proxy.adjustTextPosition(byCharacterOffset: offset)
            return true
        }
        return false
    }

    func updateComposingText(composingText: ComposingText, completedPrefix: String, isSelected: Bool) {
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
            // 選択中でない場合、削除する
            if !isSelected {
                let count = self.displayedLiveConversionText?.count ?? self.composingText.convertTargetCursorPosition
                self.deleteBackward(count: count)
            }
            let delta = self.composingText.convertTarget.count - composingText.convertTarget.count
            let cursorPosition = self.composingText.convertTargetCursorPosition - delta
            self.insertText(completedPrefix + String(self.composingText.convertTargetBeforeCursor.suffix(cursorPosition)))
            self.moveCursor(count: composingText.convertTargetCursorPosition - cursorPosition)
            self.composingText = composingText
            self.displayedLiveConversionText = nil
        }
    }
}
