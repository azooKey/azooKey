//
//  ResultViewItemData.swift
//  azooKey
//
//  Created by ensan on 2023/03/24.
//  Copyright © 2023 ensan. All rights reserved.
//

import enum CustardKit.CandidateSelection
import Foundation

public protocol ResultViewItemData {
    var text: String {get}
    var inputable: Bool {get}
    #if DEBUG
    func getDebugInformation() -> String
    #endif
}

public struct ResultModel {
    private(set) var results: [ResultData] = []
    private var predictionResults: [ResultData] = []
    private(set) var searchResults: [ResultData] = []
    private(set) var asyncPredictionCandidate: ResultData? = nil
    private(set) var updateResult: Bool = false
    private(set) var selection: Int?

    enum DisplayState: Hashable, Sendable {
        case nothing
        case results
        case predictions
    }

    /// `results`が空でない場合は`results`の表示を常に優先する
    var displayState: DisplayState {
        if !results.isEmpty {
            .results
        } else if !predictionResults.isEmpty {
            .predictions
        } else {
            .nothing
        }
    }

    var resultData: [ResultData] {
        switch displayState {
        case .results:
            results
        case .predictions:
            predictionResults
        case .nothing:
            []
        }
    }

    public mutating func setResults(_ results: [any ResultViewItemData]) {
        self.results = results.indices.map {ResultData(id: $0, candidate: results[$0])}
        self.predictionResults = []
        self.asyncPredictionCandidate = nil // 非同期候補もクリア
        self.selection = nil
        self.updateResult.toggle()
    }
    public mutating func setSearchResults(_ results: [any ResultViewItemData]) {
        self.searchResults = results.enumerated().map {ResultData(id: $0.offset, candidate: $0.element)}
        self.selection = nil
    }
    public mutating func setPredictionResults(_ results: [any ResultViewItemData]) {
        self.predictionResults = results.enumerated().map {ResultData(id: $0.offset, candidate: $0.element)}
        self.selection = nil
        self.updateResult.toggle()
    }
    
    public mutating func setAsyncPredictionCandidate(_ candidate: (any ResultViewItemData)?) {
        self.asyncPredictionCandidate = candidate.map { ResultData(id: -1, candidate: $0) }
        self.updateResult.toggle()
    }
    public mutating func setSelectionRequest(_ request: CandidateSelection?) {
        self.selection = switch request {
        case .none:
            nil
        case .first:
            0
        case .last:
            self.resultData.endIndex - 1
        case .exact(let value):
            min(max(0, value), self.resultData.endIndex - 1)
        case .offset(let value):
            if let selection {
                min(max(0, selection + value), self.resultData.endIndex - 1)
            } else {
                0
            }
        }
    }

    public func getSelectedCandidate() -> (any ResultViewItemData)? {
        if let selection,
           self.resultData.indices.contains(selection) {
            self.resultData[selection].candidate
        } else {
            nil
        }
    }
}

struct ResultData: Identifiable {
    var id: Int
    var candidate: any ResultViewItemData
}
