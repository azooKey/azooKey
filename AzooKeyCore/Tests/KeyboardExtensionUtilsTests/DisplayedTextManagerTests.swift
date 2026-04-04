import KanaKanjiConverterModule
@testable import KeyboardExtensionUtils
import XCTest

final class KeyboardExtensionUtils: XCTestCase {
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
        print("Here1")
        composingText.insertAtCursorPosition("b", inputStyle: .direct)
        manager.updateComposingText(composingText: composingText, newLiveConversionText: nil)
        XCTAssertEqual(manager.composingText, composingText)
        XCTAssertEqual(mockProxy.documentContextBeforeInput, "ab")
        print("Here2")
        _ = composingText.moveCursorFromCursorPosition(count: -1)
        manager.updateComposingText(composingText: composingText, newLiveConversionText: nil)
        XCTAssertEqual(manager.composingText, composingText)
        XCTAssertEqual(mockProxy.documentContextBeforeInput, "a")
        XCTAssertEqual(mockProxy.documentContextAfterInput, "b")
        print("Here3")
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
}
