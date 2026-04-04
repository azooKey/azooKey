import UIKit

final class MockTextDocumentProxy: NSObject, UITextDocumentProxy {
    var documentContextBeforeInput: String? {
        let prefix = utf16String.prefix(utf16CursorRange.startPosition)
        return String(utf16CodeUnits: Array(prefix), count: prefix.count)
    }

    var documentContextAfterInput: String? {
        let suffix = utf16String.dropFirst(utf16CursorRange.startPosition + utf16CursorRange.length)
        return String(utf16CodeUnits: Array(suffix), count: suffix.count)
    }

    var selectedText: String? {
        if utf16CursorRange.length == 0 {
            return nil
        } else {
            return String(utf16CodeUnits: Array(utf16String[utf16CursorRange.startPosition ..< utf16CursorRange.startPosition + utf16CursorRange.length]), count: utf16CursorRange.length)
        }
    }

    var documentInputMode: UITextInputMode?

    var documentIdentifier: UUID = UUID()

    var utf16CursorRange = (startPosition: 0, length: 0)
    var utf16String: [UInt16] = []
    var utf16MarkedRange: NSRange?

    private func replace(range: NSRange, with text: [UInt16]) {
        utf16String.replaceSubrange(range.location ..< range.location + range.length, with: text)
    }

    func adjustTextPosition(byCharacterOffset offset: Int) {
        if utf16CursorRange.length != 0 {
            utf16CursorRange = (utf16CursorRange.startPosition + utf16CursorRange.length, 0)
        } else {
            utf16CursorRange.startPosition += offset
            utf16CursorRange.startPosition = max(min(utf16CursorRange.startPosition, utf16String.endIndex), 0)
        }
    }

    func setMarkedText(_ markedText: String, selectedRange: NSRange) {
        let targetRange = utf16MarkedRange ?? NSRange(location: utf16CursorRange.startPosition, length: utf16CursorRange.length)
        let markedTextUTF16 = Array(markedText.utf16)
        replace(range: targetRange, with: markedTextUTF16)
        utf16MarkedRange = NSRange(location: targetRange.location, length: markedTextUTF16.count)

        let location = max(0, min(selectedRange.location, markedTextUTF16.count))
        let length = max(0, min(selectedRange.length, markedTextUTF16.count - location))
        utf16CursorRange = (targetRange.location + location, length)
    }

    func unmarkText() {
        utf16MarkedRange = nil
    }

    var hasText: Bool {
        !utf16String.isEmpty
    }

    func insertText(_ text: String) {
        let replacementRange = utf16MarkedRange ?? NSRange(location: utf16CursorRange.startPosition, length: utf16CursorRange.length)
        let utf16Text = Array(text.utf16)
        replace(range: replacementRange, with: utf16Text)
        utf16MarkedRange = nil
        utf16CursorRange = (replacementRange.location + utf16Text.count, 0)
    }

    func deleteBackward() {
        if let utf16MarkedRange {
            utf16String.removeSubrange(utf16MarkedRange.location ..< utf16MarkedRange.location + utf16MarkedRange.length)
            utf16CursorRange = (utf16MarkedRange.location, 0)
            self.utf16MarkedRange = nil
            return
        }
        if utf16CursorRange.length != 0 {
            utf16String.removeSubrange(utf16CursorRange.startPosition ..< utf16CursorRange.startPosition + utf16CursorRange.length)
            utf16CursorRange.length = 0
            return
        }
        if utf16CursorRange.startPosition == 0 {
            return
        }
        utf16String.remove(at: utf16CursorRange.startPosition - 1)
        utf16CursorRange.startPosition -= 1
    }
}
