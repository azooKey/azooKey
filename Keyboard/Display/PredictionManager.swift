//
//  PredictionManager.swift
//  Keyboard
//
//  Created by miwa on 2023/09/18.
//  Copyright © 2023 miwa. All rights reserved.
//

import KanaKanjiConverterModule
import KeyboardViews

final class PredictionManager {
    private struct State {
        var candidate: Candidate
        var textChangedCount: Int
    }

    private var lastState: State?

    // TODO: `KanaKanjiConverter.mergeCandidates`を呼んだほうが適切
    private func mergeCandidates(_ left: Candidate, _ right: Candidate) -> Candidate {
        // 厳密なmergeにはleft.lastRcidとright.lastLcidの連接コストの計算が必要だが、予測変換の文脈で厳密なValueの計算は不要なので行わない
        var result = left
        result.text += right.text
        result.data += right.data
        result.value += right.value
        result.composingCount = .composite(lhs: result.composingCount, rhs: right.composingCount)
        result.lastMid = right.lastMid == MIDData.EOS.mid ? left.lastMid : right.lastMid
        return result
    }

    /// 部分的に確定した後に更新を行う
    func partialUpdate(candidate: Candidate) {
        if let lastState {
            self.lastState = .init(candidate: self.mergeCandidates(lastState.candidate, candidate), textChangedCount: lastState.textChangedCount)
        } else {
            self.lastState = .init(candidate: candidate, textChangedCount: -1)
        }
    }

    /// 確定直後にcandidateと合わせて更新する
    func updateAfterComplete(candidate: Candidate, textChangedCount: Int) {
        if let lastState, lastState.textChangedCount == -1 {
            self.lastState = State(candidate: self.mergeCandidates(lastState.candidate, candidate), textChangedCount: textChangedCount)
        } else {
            self.lastState = State(candidate: candidate, textChangedCount: textChangedCount)
        }
    }

    /// 確定後にcandidateと合わせて更新する
    func update(candidate: Candidate, textChangedCount: Int) {
        self.lastState = State(candidate: candidate, textChangedCount: textChangedCount)
    }

    func getLastCandidate() -> Candidate? {
        lastState?.candidate
    }

    func shouldResetPrediction(textChangedCount: Int) -> Bool {
        if let lastState, lastState.textChangedCount != textChangedCount {
            self.lastState = nil
            return true
        }
        return false
    }
}

extension PostCompositionPredictionCandidate: @retroactive ResultViewItemData {
    public var inputable: Bool {
        true
    }
    #if DEBUG
    public func getDebugInformation() -> String {
        text
    }
    #endif
}
