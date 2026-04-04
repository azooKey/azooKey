import KanaKanjiConverterModule
@testable import KeyboardExtensionUtils
import XCTest

final class DisplayedTextManagerTests: XCTestCase {
    private func makeObservedState(_ left: String, center: String = "", right: String = "") -> ObservedTextState {
        .init(left: left, center: center, right: right)
    }

    @MainActor
    func testOperation() throws {
        let manager = DisplayedTextManager(isLiveConversionEnabled: false, isMarkedTextEnabled: false)
        var composingText = ComposingText()

        let mockProxy = MockTextDocumentProxy()
        manager.setTextDocumentProxy(.mainProxy(mockProxy))

        composingText.insertAtCursorPosition("a", inputStyle: .direct)
        manager.updateComposingText(composingText: composingText, newLiveConversionText: nil)
        XCTAssertEqual(manager.composingText, composingText)
        XCTAssertEqual(mockProxy.documentContextBeforeInput, "a")
        composingText.insertAtCursorPosition("b", inputStyle: .direct)
        manager.updateComposingText(composingText: composingText, newLiveConversionText: nil)
        XCTAssertEqual(manager.composingText, composingText)
        XCTAssertEqual(mockProxy.documentContextBeforeInput, "ab")
        _ = composingText.moveCursorFromCursorPosition(count: -1)
        manager.updateComposingText(composingText: composingText, newLiveConversionText: nil)
        XCTAssertEqual(manager.composingText, composingText)
        XCTAssertEqual(mockProxy.documentContextBeforeInput, "a")
        XCTAssertEqual(mockProxy.documentContextAfterInput, "b")
        composingText.deleteBackwardFromCursorPosition(count: 1)
        manager.updateComposingText(composingText: composingText, newLiveConversionText: nil)
        XCTAssertEqual(manager.composingText, composingText)
        XCTAssertEqual(mockProxy.documentContextBeforeInput, "")
        XCTAssertEqual(mockProxy.documentContextAfterInput, "b")

        _ = composingText.moveCursorFromCursorPosition(count: 1)
        manager.updateComposingText(composingText: composingText, newLiveConversionText: nil)
        XCTAssertEqual(manager.composingText, composingText)
        XCTAssertEqual(mockProxy.documentContextBeforeInput, "b")
        XCTAssertEqual(mockProxy.documentContextAfterInput, "")
    }

    @MainActor
    func testCompleteAndContinueInputWithoutMarkedText() throws {
        let manager = DisplayedTextManager(isLiveConversionEnabled: false, isMarkedTextEnabled: false)
        var composingText = ComposingText()

        let mockProxy = MockTextDocumentProxy()
        manager.setTextDocumentProxy(.mainProxy(mockProxy))

        composingText.insertAtCursorPosition("あいうえお", inputStyle: .direct)
        manager.updateComposingText(composingText: composingText, newLiveConversionText: nil)

        var nextComposingText = ComposingText()
        nextComposingText.insertAtCursorPosition("さ", inputStyle: .direct)

        manager.updateComposingText(completedPrefix: "あいうえお順", composingText: nextComposingText, newLiveConversionText: nil)

        XCTAssertEqual(manager.composingText, nextComposingText)
        XCTAssertEqual(mockProxy.documentContextBeforeInput, "あいうえお順さ")
        XCTAssertEqual(mockProxy.documentContextAfterInput, "")
    }

    @MainActor
    func testCompleteAndContinueInputConsumesCombinedExpectedEditWithoutMarkedText() throws {
        let manager = DisplayedTextManager(isLiveConversionEnabled: false, isMarkedTextEnabled: false)
        var composingText = ComposingText()

        let mockProxy = MockTextDocumentProxy()
        manager.setTextDocumentProxy(.mainProxy(mockProxy))

        composingText.insertAtCursorPosition("あいうえお", inputStyle: .direct)
        manager.updateComposingText(composingText: composingText, newLiveConversionText: nil)
        XCTAssertEqual(
            manager.consumeExpectedEdit(
                before: makeObservedState(""),
                after: makeObservedState("あいうえお")
            ),
            .matched(hasMoreEdits: false)
        )

        var nextComposingText = ComposingText()
        nextComposingText.insertAtCursorPosition("さ", inputStyle: .direct)
        manager.updateComposingText(completedPrefix: "あいうえお順", composingText: nextComposingText, newLiveConversionText: nil)

        XCTAssertEqual(
            manager.consumeExpectedEdit(
                before: makeObservedState("あいうえお"),
                after: makeObservedState("あいうえお順さ")
            ),
            .matched(hasMoreEdits: false)
        )
    }

    @MainActor
    func testCompleteAndContinueInputWithMarkedText() throws {
        let manager = DisplayedTextManager(isLiveConversionEnabled: false, isMarkedTextEnabled: true)
        var composingText = ComposingText()

        let mockProxy = MockTextDocumentProxy()
        manager.setTextDocumentProxy(.mainProxy(mockProxy))

        composingText.insertAtCursorPosition("あいうえお", inputStyle: .direct)
        manager.updateComposingText(composingText: composingText, newLiveConversionText: nil)

        var nextComposingText = ComposingText()
        nextComposingText.insertAtCursorPosition("さ", inputStyle: .direct)

        manager.updateComposingText(completedPrefix: "あいうえお順", composingText: nextComposingText, newLiveConversionText: nil)

        XCTAssertEqual(manager.composingText, nextComposingText)
        XCTAssertEqual(mockProxy.documentContextBeforeInput, "あいうえお順さ")
        XCTAssertEqual(mockProxy.documentContextAfterInput, "")
        XCTAssertEqual(mockProxy.utf16MarkedRange, NSRange(location: NSString(string: "あいうえお順").length, length: NSString(string: "さ").length))
    }

    @MainActor
    func testCompleteAndContinueInputConsumesCombinedExpectedEditWithMarkedText() throws {
        let manager = DisplayedTextManager(isLiveConversionEnabled: false, isMarkedTextEnabled: true)
        var composingText = ComposingText()

        let mockProxy = MockTextDocumentProxy()
        manager.setTextDocumentProxy(.mainProxy(mockProxy))

        composingText.insertAtCursorPosition("あいうえお", inputStyle: .direct)
        manager.updateComposingText(composingText: composingText, newLiveConversionText: nil)
        XCTAssertEqual(
            manager.consumeExpectedEdit(
                before: makeObservedState(""),
                after: makeObservedState("あいうえお")
            ),
            .matched(hasMoreEdits: false)
        )

        var nextComposingText = ComposingText()
        nextComposingText.insertAtCursorPosition("さ", inputStyle: .direct)
        manager.updateComposingText(completedPrefix: "あいうえお順", composingText: nextComposingText, newLiveConversionText: nil)

        XCTAssertEqual(
            manager.consumeExpectedEdit(
                before: makeObservedState("あいうえお"),
                after: makeObservedState("あいうえお順さ")
            ),
            .matched(hasMoreEdits: false)
        )
    }

    @MainActor
    func testCompleteAndContinueInputWithLiveConversionTextWithoutMarkedText() throws {
        let manager = DisplayedTextManager(isLiveConversionEnabled: true, isMarkedTextEnabled: false)
        var composingText = ComposingText()

        let mockProxy = MockTextDocumentProxy()
        manager.setTextDocumentProxy(.mainProxy(mockProxy))

        composingText.insertAtCursorPosition("あいうえお", inputStyle: .direct)
        manager.updateComposingText(composingText: composingText, newLiveConversionText: "あいうえお")
        _ = manager.consumeExpectedEdit(before: makeObservedState(""), after: makeObservedState("あいうえお"))

        var nextComposingText = ComposingText()
        nextComposingText.insertAtCursorPosition("さ", inputStyle: .direct)
        manager.updateComposingText(completedPrefix: "あいうえお順", composingText: nextComposingText, newLiveConversionText: "差")

        XCTAssertEqual(manager.composingText, nextComposingText)
        XCTAssertEqual(manager.displayedLiveConversionText, "差")
        XCTAssertEqual(mockProxy.documentContextBeforeInput, "あいうえお順差")
        XCTAssertEqual(mockProxy.documentContextAfterInput, "")
    }

    @MainActor
    func testCompleteAndContinueInputWithLiveConversionTextWithMarkedText() throws {
        let manager = DisplayedTextManager(isLiveConversionEnabled: true, isMarkedTextEnabled: true)
        var composingText = ComposingText()

        let mockProxy = MockTextDocumentProxy()
        manager.setTextDocumentProxy(.mainProxy(mockProxy))

        composingText.insertAtCursorPosition("あいうえお", inputStyle: .direct)
        manager.updateComposingText(composingText: composingText, newLiveConversionText: "あいうえお")
        _ = manager.consumeExpectedEdit(before: makeObservedState(""), after: makeObservedState("あいうえお"))

        var nextComposingText = ComposingText()
        nextComposingText.insertAtCursorPosition("さ", inputStyle: .direct)
        manager.updateComposingText(completedPrefix: "あいうえお順", composingText: nextComposingText, newLiveConversionText: "差")

        XCTAssertEqual(manager.composingText, nextComposingText)
        XCTAssertEqual(manager.displayedLiveConversionText, "差")
        XCTAssertEqual(mockProxy.documentContextBeforeInput, "あいうえお順差")
        XCTAssertEqual(mockProxy.documentContextAfterInput, "")
        XCTAssertEqual(mockProxy.utf16MarkedRange, NSRange(location: NSString(string: "あいうえお順").length, length: NSString(string: "差").length))
    }
}
