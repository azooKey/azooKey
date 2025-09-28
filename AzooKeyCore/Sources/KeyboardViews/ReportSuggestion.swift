//
//  ReportSuggestion.swift
//
//  Created for report suggestion PoC.
//

import Foundation
import struct KanaKanjiConverterModule.ComposingText
import enum KanaKanjiConverterModule.ComposingCount

public struct CandidateSummary: Equatable {
    public let displayText: String
    public let rank: Int
    public let rawCandidate: (any ResultViewItemData)?
    public let composingInputs: [ComposingText.InputElement]?
    public let candidateID: String?
    public let composingCount: ComposingCount?
    public let leftContext: String?
    public let rightContext: String?

    public init(
        displayText: String,
        rank: Int,
        rawCandidate: (any ResultViewItemData)? = nil,
        composingInputs: [ComposingText.InputElement]? = nil,
        candidateID: String? = nil,
        composingCount: ComposingCount? = nil,
        leftContext: String? = nil,
        rightContext: String? = nil
    ) {
        self.displayText = displayText
        self.rank = rank
        self.rawCandidate = rawCandidate
        self.composingInputs = composingInputs
        self.candidateID = candidateID
        self.composingCount = composingCount
        self.leftContext = leftContext
        self.rightContext = rightContext
    }

    public static func == (lhs: CandidateSummary, rhs: CandidateSummary) -> Bool {
        lhs.displayText == rhs.displayText
            && lhs.rank == rhs.rank
            && lhs.candidateID == rhs.candidateID
    }
}

extension CandidateSummary: @unchecked Sendable {}

public enum ReportContent: Equatable {
    case candidateRankingMismatch(top: CandidateSummary, selected: CandidateSummary)
}

extension ReportContent: @unchecked Sendable {}

public struct ReportDetailEntry: Equatable, Sendable {
    public let field: String
    public let value: String
    public var isExcluded: Bool
    public var isOptional: Bool

    public init(field: String, value: String, isExcluded: Bool = false, isOptional: Bool = true) {
        self.field = field
        self.value = value
        self.isExcluded = isExcluded
        self.isOptional = isOptional
    }
}

public struct ReportDetailState: Equatable {
    public let content: ReportContent
    public let entries: [ReportDetailEntry]

    public init(content: ReportContent, entries: [ReportDetailEntry]) {
        self.content = content
        self.entries = entries
    }
}

extension ReportDetailState: @unchecked Sendable {}
