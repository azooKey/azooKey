import AzooKeyUtils
import KanaKanjiConverterModuleWithDefaultDictionary
import UIKit
import XCTest

@MainActor
final class InputManagerTests: XCTestCase {
    private func withLiveConversion(_ body: () throws -> Void) rethrows {
        @KeyboardSetting(.liveConversion) var liveConversion
        @KeyboardSetting(.markedTextSetting) var markedTextSetting
        let previousLiveConversion = liveConversion
        let previousMarkedTextSetting = markedTextSetting
        liveConversion = true
        markedTextSetting = .disabled
        defer {
            liveConversion = previousLiveConversion
            markedTextSetting = previousMarkedTextSetting
        }
        try body()
    }

    private func makeComposition(prefix: String) -> (InputManager, TextDocumentProxy) {
        let manager = InputManager()
        let proxy = TextDocumentProxy()
        proxy.insertText(prefix)
        manager.setTextDocumentProxy(.mainProxy(proxy))
        // Set up a known live-conversion result without depending on model output.
        manager.input(text: "さくらのはな", requireSetResult: false, inputStyle: .direct)
        let candidate = Candidate(
            text: "桜の花",
            value: -18,
            composingCount: .inputCount(manager.composingText.input.count),
            lastMid: MIDData.一般.mid,
            data: [.init(word: "桜の花", ruby: "サクラノハナ", cid: CIDData.一般名詞.cid, mid: MIDData.一般.mid, value: -18)]
        )
        manager.liveConversionManager.setLastUsedCandidate(candidate)
        manager.displayedTextManager.updateComposingText(composingText: manager.composingText, newLiveConversionText: candidate.text)
        return (manager, proxy)
    }

    func testEnterAfterExternalChangeEndsCompositionWithoutEditingDocument() {
        withLiveConversion {
            for prefix in ["", "今日は"] {
                for position in [0, 1] {
                    for requireSetResult in [true, false] {
                        let (manager, proxy) = makeComposition(prefix: prefix)
                        proxy.adjustTextPosition(byCharacterOffset: position - "桜の花".utf16.count)
                        let before = proxy.documentContextBeforeInput
                        let after = proxy.documentContextAfterInput
                        let edits = proxy.textEditCount

                        _ = manager.enter(shouldModifyDisplayedText: false, requireSetResult: requireSetResult)

                        XCTAssertTrue(manager.composingText.isEmpty)
                        XCTAssertTrue(manager.displayedTextManager.composingText.isEmpty)
                        XCTAssertNil(manager.liveConversionManager.lastUsedCandidate)
                        XCTAssertEqual(proxy.documentContextBeforeInput, before)
                        XCTAssertEqual(proxy.documentContextAfterInput, after)
                        XCTAssertEqual(proxy.textEditCount, edits)
                    }
                }
            }
        }
    }

    func testInputAfterExternalChangeStartsNewComposition() {
        withLiveConversion {
            let (manager, proxy) = makeComposition(prefix: "今日は")
            proxy.adjustTextPosition(byCharacterOffset: -"桜の花".utf16.count)
            _ = manager.enter(shouldModifyDisplayedText: false, requireSetResult: false)

            // Inspect the next composition before conversion so this assertion is
            // independent of dictionary ranking, learning data, and zenzai.
            manager.input(text: "いぬ", requireSetResult: false, inputStyle: .direct)

            XCTAssertEqual(manager.composingText.convertTarget, "いぬ")
            XCTAssertNil(manager.liveConversionManager.lastUsedCandidate)
            XCTAssertEqual(proxy.documentContextBeforeInput, "今日は")
            XCTAssertEqual(proxy.documentContextAfterInput, "桜の花")
        }
    }

    private final class TextDocumentProxy: NSObject, UITextDocumentProxy {
        private var text = ""
        private var cursor = 0
        private(set) var textEditCount = 0
        var documentIdentifier = UUID()
        var documentInputMode: UITextInputMode? { nil }
        var selectedText: String? { nil }
        var hasText: Bool { !text.isEmpty }
        var documentContextBeforeInput: String? { (text as NSString).substring(to: cursor) }
        var documentContextAfterInput: String? { (text as NSString).substring(from: cursor) }

        func insertText(_ insertedText: String) {
            text = documentContextBeforeInput! + insertedText + documentContextAfterInput!
            cursor += insertedText.utf16.count
            textEditCount += 1
        }

        func deleteBackward() {
            let before = String(documentContextBeforeInput!.dropLast())
            text = before + documentContextAfterInput!
            cursor = before.utf16.count
            textEditCount += 1
        }

        func adjustTextPosition(byCharacterOffset offset: Int) {
            cursor = max(0, min(cursor + offset, text.utf16.count))
        }

        func setMarkedText(_ markedText: String, selectedRange: NSRange) {
            XCTFail("Marked text is disabled for these tests")
        }

        func unmarkText() {}
    }
}
