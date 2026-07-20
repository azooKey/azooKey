import AzooKeyUtils
import Foundation
import KeyboardViews
import SwiftUtils
import UIKit
import enum KanaKanjiConverterModule.InputPiece
import enum KanaKanjiConverterModule.InputStyle
import struct KanaKanjiConverterModule.Candidate
import struct KanaKanjiConverterModule.ComposingText
import enum KanaKanjiConverterModule.ComposingCount

struct ReportSubmissionHelper {
    @MainActor
    static func submitSuggestion(
        content: ReportContent,
        variableStates: VariableStates,
        inputManager: InputManager
    ) async -> Bool {
        guard SemiStaticStates.shared.hasFullAccess else { return false }
        let url = URL(string: "https://docs.google.com/forms/d/e/1FAIpQLSeTdOtFZfuFHurrDMIIzLyX-Z84Y3IKHflewNZ8dPOFgCTOtw/formResponse")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("no-cors", forHTTPHeaderField: "mode")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let entries = reportFormEntries(for: content, variableStates: variableStates, inputManager: inputManager)
        request.httpBody = buildFormBody(from: entries)

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            debug("reportSuggestion response", response)
            return true
        } catch {
            debug("reportSuggestion error", error)
            return false
        }
    }

    @MainActor
    static func submitWrongConversion(
        candidate: any ResultViewItemData,
        index: Int?,
        variableStates: VariableStates,
        inputManager: InputManager
    ) async {
        let url = URL(string: "https://docs.google.com/forms/d/e/1FAIpQLSfpYQqbX8u5SgGVfXjNzCPtKAH_5Mp7PCkUiCiUceEaevb8pQ/formResponse")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("no-cors", forHTTPHeaderField: "mode")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let surfaceCandidate = switch candidate.label {
        case .text(let text): text
        case .systemImage: "System Image"
        }
        let ruby = makeRubyDescription(candidate: candidate, inputManager: inputManager)
        let indexString = index?.description ?? "nil"
        let version = SharedStore.currentAppVersion?.description ?? "Unknown Version"
        @KeyboardSetting(.learningType) var learningType
        let learning = learningType.needUsingMemory ? "有効" : "無効"
        request.httpBody = buildFormBody(from: [
            ("entry.134904003", surfaceCandidate),
            ("entry.869464972", ruby),
            ("entry.1459534202", indexString),
            ("entry.571429448", version),
            ("entry.524189292", learning),
        ])

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            debug("notifyReportWrongConversion response", response)
            variableStates.temporalMessage = .doneReportWrongConversion
        } catch {
            debug("notifyReportWrongConversion error", error)
        }
    }

    @MainActor
    static func reportFormEntries(
        for content: ReportContent,
        variableStates: VariableStates,
        inputManager: InputManager
    ) -> [(String, String)] {
        let payload = reportPayloadJSON(
            for: content,
            variableStates: variableStates,
            inputManager: inputManager
        )
        return [
            ("entry.1715004013", "non_first_candidate_selection_report"),
            ("entry.562739847", payload),
        ]
    }

    @MainActor
    static func detailEntries(
        for content: ReportContent,
        variableStates: VariableStates,
        inputManager: InputManager
    ) -> [ReportDetailEntry] {
        let base = baseEntries(for: content, variableStates: variableStates, inputManager: inputManager)
        guard let state = variableStates.reportDetailState, state.content == content else {
            return base
        }
        return base.map { entry in
            if let override = state.entries.first(where: { $0.field == entry.field }) {
                var updated = entry
                updated.isExcluded = override.isExcluded
                return updated
            }
            return entry
        }
    }

    @MainActor
    private static func baseEntries(
        for content: ReportContent,
        variableStates: VariableStates,
        inputManager: InputManager
    ) -> [ReportDetailEntry] {
        let appVersion = SharedStore.currentAppVersion?.description ?? "Unknown Version"
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        @KeyboardSetting(.zenzaiEnable) var zenzaiEnabled
        @KeyboardSetting(.zenzaiEffort) var zenzaiEffort
        let effortValue: String = switch zenzaiEffort {
        case .low: "low"
        case .medium: "medium"
        case .high: "high"
        }
        let layout = resolveJapaneseLayout(variableStates: variableStates)
        let dateString = ISO8601DateFormatter().string(from: Date())
        let textContentType = variableStates.textContentType?.rawValue ?? "nil"
        let returnKeyType = describe(returnKeyType: variableStates.returnKeyType)
        let inputEntry = currentInputEntry(content: content, variableStates: variableStates, inputManager: inputManager)
        let contextEntries = contextEntries(for: content, variableStates: variableStates, inputManager: inputManager)
        let nicknameEntry = nicknameEntry()

        switch content {
        case let .candidateRankingMismatch(top, selected):
            var entries: [ReportDetailEntry] = [
                ReportDetailEntry(field: "suggested", value: top.displayText, isExcluded: false, isOptional: false),
                ReportDetailEntry(field: "selected", value: selected.displayText, isExcluded: false, isOptional: false),
                ReportDetailEntry(field: "selectedIndex", value: String(selected.rank), isExcluded: false, isOptional: false),
                inputEntry,
            ]
            if let count = selected.composingCount {
                entries.append(
                    ReportDetailEntry(
                        field: "selectedComposingCount",
                        value: describe(count),
                        isExcluded: false,
                        isOptional: false
                    )
                )
            }
            entries.append(contentsOf: contextEntries)
            if let nicknameEntry {
                entries.append(nicknameEntry)
            }
            entries.append(contentsOf: [
                ReportDetailEntry(field: "appVersion", value: appVersion, isExcluded: false, isOptional: false),
                ReportDetailEntry(field: "osVersion", value: osVersion, isExcluded: false, isOptional: false),
                ReportDetailEntry(field: "zenzaiEnabled", value: zenzaiEnabled ? "true" : "false", isExcluded: false, isOptional: false),
                ReportDetailEntry(field: "zenzaiEffort", value: effortValue, isExcluded: false, isOptional: false),
                ReportDetailEntry(field: "japaneseLayout", value: layout, isExcluded: false, isOptional: false),
                ReportDetailEntry(field: "textContentType", value: textContentType, isExcluded: false, isOptional: false),
                ReportDetailEntry(field: "returnKeyType", value: returnKeyType, isExcluded: false, isOptional: false),
                ReportDetailEntry(field: "date", value: dateString, isExcluded: false, isOptional: false),
            ])
            return entries
        }
    }

    @MainActor
    private static func resolveJapaneseLayout(variableStates: VariableStates) -> String {
        switch variableStates.tabManager.resolvedTab() {
        case .standard(.flick_japanese):
            return "flick"
        case .standard(.qwerty_japanese):
            return "qwerty"
        case .custard:
            return "custurd"
        case .standard, .clipboardHistory, .emoji:
            return "other"
        }
    }

    @MainActor
    private static func contextEntries(
        for content: ReportContent,
        variableStates: VariableStates,
        inputManager: InputManager
    ) -> [ReportDetailEntry] {
        @KeyboardSetting(.wrongConversionIncludeContext) var includeContext
        if let stored = storedContext(from: content) {
            let entries = [
                stored.left.map {
                    ReportDetailEntry(
                        field: "leftSideContext",
                        value: limitContext($0, suffix: true),
                        isExcluded: !includeContext,
                        isOptional: true
                    )
                },
                stored.right.map {
                    ReportDetailEntry(
                        field: "rightSideContext",
                        value: limitContext($0, prefix: true),
                        isExcluded: !includeContext,
                        isOptional: true
                    )
                },
            ].compactMap { $0 }
            if !entries.isEmpty {
                return entries
            }
        }

        let (left, _, right) = inputManager.getSurroundingText()
        let leftContext = limitContext(String(left), suffix: true)
        let rightContext = limitContext(String(right), prefix: true)

        return [
            ReportDetailEntry(
                field: "leftSideContext",
                value: leftContext,
                isExcluded: leftContext.isEmpty ? true : !includeContext,
                isOptional: true
            ),
            ReportDetailEntry(
                field: "rightSideContext",
                value: rightContext,
                isExcluded: rightContext.isEmpty ? true : !includeContext,
                isOptional: true
            ),
        ]
    }

    @MainActor
    private static func currentInputEntry(
        content: ReportContent,
        variableStates: VariableStates,
        inputManager: InputManager
    ) -> ReportDetailEntry {
        let snapshot = inputSnapshot(from: content)
            ?? fallbackInputSnapshot(variableStates: variableStates, inputManager: inputManager)
        let encoded = encode(snapshot: snapshot)
        return ReportDetailEntry(field: "input", value: encoded, isExcluded: false, isOptional: false)
    }

    private static func inputSnapshot(from content: ReportContent) -> InputSnapshot? {
        switch content {
        case let .candidateRankingMismatch(top, selected):
            if let selectedInputs = selected.composingInputs {
                return snapshot(from: selectedInputs)
            } else if let topInputs = top.composingInputs {
                return snapshot(from: topInputs)
            }
            return nil
        }
    }

    @MainActor private static func fallbackInputSnapshot(
        variableStates: VariableStates,
        inputManager: InputManager
    ) -> InputSnapshot {
        let composing = inputManager.getComposingText()
        if !composing.convertTarget.isEmpty {
            let segments = snapshot(from: composing.input).segments
            return InputSnapshot(
                text: composing.convertTarget,
                segments: segments
            )
        }
        let (left, center, right) = inputManager.getSurroundingText()
        if !center.isEmpty {
            return InputSnapshot(
                text: center,
                segments: [Segment(value: center, inputStyle: nil)]
            )
        }
        let composedSnapshot = snapshot(from: composing.input)
        if !composedSnapshot.text.isEmpty {
            return composedSnapshot
        }
        let surrounding = left.suffix(5) + right.prefix(5)
        return InputSnapshot(text: String(surrounding), segments: [Segment(value: String(surrounding), inputStyle: nil)])
    }

    private static func snapshot(from elements: [ComposingText.InputElement]) -> InputSnapshot {
        let segments = elements.map { element in
            Segment(
                value: pieceCharacterRepresentation(element.piece),
                inputStyle: describe(inputStyle: element.inputStyle)
            )
        }
        return InputSnapshot(text: snapshotText(from: elements), segments: segments)
    }

    private static func snapshotText(from elements: [ComposingText.InputElement]) -> String {
        elements.map { pieceCharacterRepresentation($0.piece) }.joined()
    }

    private static func pieceCharacterRepresentation(_ piece: InputPiece) -> String {
        switch piece {
        case .character(let char):
            return String(char)
        case .compositionSeparator:
            return ""
        case .key(intention: _, input: let input, modifiers: _):
            return String(input)
        @unknown default:
            return ""
        }
    }

    private static func makeRubyDescription(candidate: any ResultViewItemData, inputManager: InputManager) -> String {
        if candidate is Candidate {
            let composingText = inputManager.getComposingText()
            let segments = composingText.input.map { element in
                "\(describe(inputStyle: element.inputStyle))(\(pieceCharacterRepresentation(element.piece)))"
            }
            return composingText.convertTarget + " / " + segments.joined()
        }
        return "Unknown case"
    }

    private static func buildFormBody(from parameters: [(String, String)]) -> Data {
        parameters
            .map { key, value in "\(key)=\(value)" }
            .joined(separator: "&")
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)?
            .data(using: .utf8) ?? Data()
    }

    private struct ComposingComponent {
        enum Kind { case input, surface }
        let kind: Kind
        let value: Int
    }

    private static func describe(_ count: ComposingCount) -> String {
        describeComponents(count)
            .map { component in
                let label = component.kind == .input ? "input" : "surface"
                return "\(label):\(component.value)"
            }
            .joined(separator: " + ")
    }

    private static func describe(returnKeyType: UIReturnKeyType) -> String {
        switch returnKeyType {
        case .default: "default"
        case .go: "go"
        case .google: "google"
        case .join: "join"
        case .next: "next"
        case .route: "route"
        case .search: "search"
        case .send: "send"
        case .yahoo: "yahoo"
        case .done: "done"
        case .emergencyCall: "emergencyCall"
        case .continue: "continue"
        @unknown default: "unknown"
        }
    }

    private static func describeComponents(_ count: ComposingCount) -> [ComposingComponent] {
        switch count {
        case .inputCount(let value):
            value == 0 ? [] : [ComposingComponent(kind: .input, value: value)]
        case .surfaceCount(let value):
            value == 0 ? [] : [ComposingComponent(kind: .surface, value: value)]
        case .composite(let lhs, let rhs):
            mergeComponents(describeComponents(lhs), describeComponents(rhs))
        }
    }

    private static func mergeComponents(_ lhs: [ComposingComponent], _ rhs: [ComposingComponent]) -> [ComposingComponent] {
        guard let last = lhs.last, let first = rhs.first, last.kind == first.kind else {
            return lhs + rhs
        }
        var merged = lhs
        merged.removeLast()
        merged.append(ComposingComponent(kind: last.kind, value: last.value + first.value))
        merged.append(contentsOf: rhs.dropFirst())
        return merged
    }

    private static func storedContext(from content: ReportContent) -> (left: String?, right: String?)? {
        switch content {
        case let .candidateRankingMismatch(_, selected):
            if selected.leftContext == nil && selected.rightContext == nil {
                return nil
            }
            return (selected.leftContext, selected.rightContext)
        }
    }

    private static func limitContext(_ value: String, prefix: Bool = false, suffix: Bool = false) -> String {
        guard !value.isEmpty else { return value }
        if prefix {
            return String(value.prefix(10))
        }
        if suffix {
            return String(value.suffix(10))
        }
        return value
    }

    private static func describe(inputStyle: InputStyle) -> String {
        switch inputStyle {
        case .direct: "direct"
        case .roman2kana: "roman2kana"
        case .mapped(id: let id): "mapped(\(id))"
        }
    }

    private static func encode(snapshot: InputSnapshot) -> String {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(snapshot), let string = String(data: data, encoding: .utf8) {
            return string
        }
        return snapshot.text
    }

    @MainActor
    private static func reportPayloadJSON(
        for content: ReportContent,
        variableStates: VariableStates,
        inputManager: InputManager
    ) -> String {
        let includedEntries = detailEntries(
            for: content,
            variableStates: variableStates,
            inputManager: inputManager
        ).filter { !$0.isExcluded }

        var payloadDictionary: [String: Any] = [:]
        for entry in includedEntries {
            if entry.field == "input", let data = entry.value.data(using: .utf8),
               let object = try? JSONSerialization.jsonObject(with: data) {
                payloadDictionary[entry.field] = object
            } else {
                payloadDictionary[entry.field] = entry.value
            }
        }
        if let data = try? JSONSerialization.data(withJSONObject: payloadDictionary, options: [.sortedKeys]),
           let string = String(data: data, encoding: .utf8) {
            return string
        }
        return "{}"
    }

    @MainActor
    private static func nicknameEntry() -> ReportDetailEntry? {
        @KeyboardSetting(.wrongConversionReportUserNickname) var nickname
        let trimmed = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }
        return ReportDetailEntry(field: "userNickname", value: trimmed, isExcluded: false, isOptional: true)
    }
}

private struct InputSnapshot: Codable {
    let text: String
    let segments: [Segment]
}

private struct Segment: Codable {
    let value: String
    let inputStyle: String?
}
