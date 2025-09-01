//
//  PredictionManager.swift
//  Keyboard
//
//  Created by miwa on 2023/09/18.
//  Copyright © 2023 miwa. All rights reserved.
//

import KanaKanjiConverterModule
import KeyboardViews
#if canImport(FoundationModels)
import RegexBuilder
import FoundationModels
#endif

final class PredictionManager {
    private struct State {
        var candidate: Candidate
        var textChangedCount: Int
    }

    private var lastState: State?
    private var asyncTask: Task<Void, any Error>?
    private var asyncCandidate: PostCompositionPredictionCandidate?

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
            self.cancelAsyncPrediction()
            return true
        }
        return false
    }

    func getAsyncCandidate() -> PostCompositionPredictionCandidate? {
        asyncCandidate
    }

    func clearAsyncCandidate() {
        asyncCandidate = nil
    }

    private func cancelAsyncPrediction() {
        asyncTask?.cancel()
        asyncTask = nil
        asyncCandidate = nil
    }

    @MainActor func loadAsyncPrediction(leftContext: String, rightContext: String, textChangedCount: Int, onUpdate: @escaping @MainActor (PostCompositionPredictionCandidate) -> Void) {
        cancelAsyncPrediction()
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            let model = SystemLanguageModel(useCase: .general)
            guard model.isAvailable else {
                print(#function, "model is not available", model.availability)
                return
            }
            self.asyncTask = Task {
                let session = LanguageModelSession(model: model, instructions: "Predict the completed version of input text. For example, if the input is '今日は朝', then the completion could be '今日は朝早く起きた' or something similar.")
                let predictionPattern = Regex {
                    Regex<Substring>(verbatim: leftContext)
                    /.+/
                }
                let predictionSchema = DynamicGenerationSchema(
                    name: "FollowingWordPrediction",
                    properties: [
                        DynamicGenerationSchema.Property(
                            name: "completion",
                            description: "The completion of the input. You must first repeat the input, followed by the completion. At most 10 additional characters.",
                            schema: DynamicGenerationSchema(type: String.self, guides: [.pattern(predictionPattern)])
                        )
                    ]
                )
                let schema = try GenerationSchema(root: predictionSchema, dependencies: [])
                let response = try await session.respond(to: leftContext, schema: schema)
                let content = try response.content.value(String.self, forProperty: "completion")
                guard content.hasPrefix(leftContext) else {
                    return
                }
                let predictionText = String(content.dropFirst(leftContext.count).split(separator: #/[,.!?、。！？\n]/#).first ?? "")
                guard !predictionText.isEmpty else {
                    return
                }
                await MainActor.run {
                    // モック候補を作成 - 簡単なDicdataElementを使用
                    let mockData = DicdataElement(word: predictionText, ruby: predictionText, cid: CIDData.固有名詞.cid, mid: MIDData.一般.mid, value: -1000)
                    let mockCandidate = PostCompositionPredictionCandidate(
                        text: predictionText,
                        value: -1000,
                        type: .additional(data: [mockData])
                    )
                    self.asyncCandidate = mockCandidate
                    onUpdate(mockCandidate)
                }
            }
        }
        #endif
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
