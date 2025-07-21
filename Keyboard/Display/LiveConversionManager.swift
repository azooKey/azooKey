//
//  LiveConversionManager.swift
//  Keyboard
//
//  Created by ensan on 2022/12/30.
//  Copyright © 2022 ensan. All rights reserved.
//

import AzooKeyUtils
import Foundation
import KanaKanjiConverterModule
import SwiftUtils

// ライブ変換を管理するためのクラス
final class LiveConversionManager {
    init(enabled: Bool) {
        self.enabled = enabled
    }
    var enabled = false

    private(set) var isFirstClauseCompletion: Bool = false
    // 現在ディスプレイに表示されている候補
    private(set) var lastUsedCandidate: Candidate?
    private var headClauseCandidateHistories: [[Candidate]] = []

    @MainActor func stopComposition() {
        self.lastUsedCandidate = nil
        @KeyboardSetting(.liveConversion) var enabled
        self.enabled = enabled
        self.headClauseCandidateHistories = []
    }

    func updateAfterFirstClauseCompletion() {
        // ここはどうにかしたい
        self.lastUsedCandidate = nil
        // フラグを戻す
        self.isFirstClauseCompletion = false
        // 最初を落とす
        if !headClauseCandidateHistories.isEmpty {
            headClauseCandidateHistories.removeFirst()
        }
    }

    private func updateHistories(newCandidate: Candidate, firstClauseCandidates: [Candidate]) {
        var data = newCandidate.data[...]
        var count = 0
        while !data.isEmpty {
            var clause = Candidate.makePrefixClauseCandidate(data: data)
            // ローマ字向けに補正処理を入れる
            if count == 0, let first = firstClauseCandidates.first(where: {$0.text == clause.text}) {
                clause.composingCount = first.composingCount
            }
            if self.headClauseCandidateHistories.count <= count {
                self.headClauseCandidateHistories.append([clause])
            } else {
                self.headClauseCandidateHistories[count].append(clause)
            }
            data = data.dropFirst(clause.data.count)
            count += 1
        }
    }

    /// かな漢字変換結果を受け取ってライブ変換状態の更新を行う関数
    ///  - Returns: ライブ変換で表示するテキスト
    func updateWithNewResults(_ composingText: ComposingText, _ candidates: [Candidate], firstClauseResults: [Candidate], convertTargetCursorPosition: Int, convertTarget: String) -> String {
        // TODO: 最後の1単語のライブ変換を抑制したい
        // TODO: ローマ字入力中に最後の単語が優先される問題
        var candidate: Candidate
        if convertTargetCursorPosition > 1, let firstCandidate = candidates.first(where: {$0.data.map {$0.ruby}.joined().count == convertTarget.count}) {
            candidate = firstCandidate
        } else {
            candidate = .init(text: convertTarget, value: 0, composingCount: .inputCount(composingText.input.count), lastMid: MIDData.一般.mid, data: [.init(ruby: convertTarget.toKatakana(), cid: CIDData.一般名詞.cid, mid: MIDData.一般.mid, value: 0)])
        }
        self.adjustCandidate(candidate: &candidate)
        debug("Live Conversion:", candidate)

        // カーソルなどを調整する
        if convertTargetCursorPosition > 0 {
            self.setLastUsedCandidate(candidate, firstClauseCandidates: firstClauseResults)
            return candidate.text
        } else {
            self.setLastUsedCandidate(nil)
            return ""
        }
    }

    /// `lastUsedCandidate`を更新する関数
    func setLastUsedCandidate(_ candidate: Candidate?, firstClauseCandidates: [Candidate] = []) {
        if let candidate {
            // 削除や置換ではなく付加的な変更である場合に限って更新を実施したい。
            let diff: Int
            if let lastUsedCandidate {
                let lastLength = lastUsedCandidate.data.reduce(0) {$0 + $1.ruby.count}
                let newLength = candidate.data.reduce(0) {$0 + $1.ruby.count}
                diff = newLength - lastLength
            } else {
                diff = 1
            }
            self.lastUsedCandidate = candidate
            // 追加である場合
            if diff > 0 {
                self.updateHistories(newCandidate: candidate, firstClauseCandidates: firstClauseCandidates)
            } else if diff < 0 {
                // 削除の場合には最後尾のログを1つ落とす。
                self.headClauseCandidateHistories.mutatingForEach {
                    _ = $0.popLast()
                }
            } else {
                // 置換の場合には更新を追加で入れる。
                self.headClauseCandidateHistories.mutatingForEach {
                    _ = $0.popLast()
                }
                self.updateHistories(newCandidate: candidate, firstClauseCandidates: firstClauseCandidates)
            }
        } else {
            self.lastUsedCandidate = nil
            self.headClauseCandidateHistories = []
        }
    }

    /// 条件に応じてCandidateを微調整するための関数
    func adjustCandidate(candidate: inout Candidate) {
        if let last = candidate.data.last, last.ruby.count < 2 {
            let ruby_hira = last.ruby.toHiragana()
            let newElement = DicdataElement(word: ruby_hira, ruby: last.ruby, lcid: last.lcid, rcid: last.rcid, mid: last.mid, value: last.adjustedData(0).value(), adjust: last.adjust)
            var newCandidate = Candidate(text: candidate.data.dropLast().map {$0.word}.joined() + ruby_hira, value: candidate.value, composingCount: candidate.composingCount, lastMid: candidate.lastMid, data: candidate.data.dropLast() + [newElement])
            newCandidate.parseTemplate()
            debug(candidate, newCandidate)
            candidate = newCandidate
        }
    }

    /// 最初の文節を確定して良い場合Candidateを返す関数
    /// - warning:
    ///   この関数を呼んで結果を得た場合、必ずそのCandidateで確定処理を行う必要がある。
    @MainActor func candidateForCompleteFirstClause() -> Candidate? {
        @KeyboardSetting(.automaticCompletionStrength) var strength
        guard let history = headClauseCandidateHistories.first else {
            return nil
        }
        if history.count < strength.threshold {
            return nil
        }

        // 過去十分な回数変動がなければ、prefixを確定して良い
        debug("History", history)
        let texts = history.suffix(strength.threshold).mapSet { $0.text }
        if texts.count == 1 {
            self.isFirstClauseCompletion = true
            return history.last!
        } else {
            return nil
        }
    }
}
