import XCTest
@testable import CustardKit

final class DecodeCodableActionTest: XCTestCase {
    func testDecodeInput() {
        do {
            let target = """
            {
                "type": "input",
                "text": "😆"
            }
            """
            let decoded = CodableActionData.quickDecode(target: target)
            XCTAssertEqual(decoded, .input("😆"))
        }
        do {
            let target = """
            {
                "type": "input",
                "text": 42
            }
            """
            let decoded = CodableActionData.quickDecode(target: target)
            XCTAssertEqual(decoded, nil)
        }
    }

    func testDecodeDirectInput() {
        do {
            let target = """
            {
                "type": "direct_input",
                "text": "佐藤さんまたは鈴木さんが対応します。"
            }
            """
            let decoded = CodableActionData.quickDecode(target: target)
            XCTAssertEqual(decoded, .directInput("佐藤さんまたは鈴木さんが対応します。"))
        }
        do {
            let target = """
            {
                "type": "direct_input",
                "text": 42
            }
            """
            let decoded = CodableActionData.quickDecode(target: target)
            XCTAssertEqual(decoded, nil)
        }
    }

    func testDecodeReplaceLastCharacters() {
        do {
            let target = """
            {
                "type": "replace_last_characters",
                "table": {
                    "天": "地",
                    "海": "山",
                    "正": "負",
                    "嬉": "悲"
                }
            }
            """
            let decoded = CodableActionData.quickDecode(target: target)
            XCTAssertEqual(decoded, .replaceLastCharacters([
                "天": "地",
                "海": "山",
                "正": "負",
                "嬉": "悲"
            ]))
        }
        do {
            let target = """
            {
                "type": "replace_last_characters",
                "table": {}
            }
            """
            let decoded = CodableActionData.quickDecode(target: target)
            XCTAssertEqual(decoded, .replaceLastCharacters([:]))
        }
    }

    func testDecodeDelete() {
        do {
            let target = """
            {
                "type": "delete",
                "count": 3
            }
            """
            let decoded = CodableActionData.quickDecode(target: target)
            XCTAssertEqual(decoded, .delete(3))
        }
        do {
            let target = """
            {
                "type": "delete",
                "count": "-8"
            }
            """
            let decoded = CodableActionData.quickDecode(target: target)
            XCTAssertEqual(decoded, nil)
        }
    }

    func testDecodeSmartDelete() {
        do {
            let target = """
            {
                "type": "smart_delete",
                "targets": ["_"],
                "direction": "backward"
            }
            """
            let decoded = CodableActionData.quickDecode(target: target)
            XCTAssertEqual(decoded, .smartDelete(.init(targets: ["_"], direction: .backward)))
        }
        do {
            let target = """
            {
                "direction": "forward",
                "type": "smart_delete",
                "targets": ["、","。","！","？",".",",","．","，", "\\n"]
            }
            """
            let decoded = CodableActionData.quickDecode(target: target)
            XCTAssertEqual(decoded, .smartDelete())
        }
    }

    func testDecodeMoveCursor() {
        do {
            let target = """
            {
                "type": "move_cursor",
                "count": 3
            }
            """
            let decoded = CodableActionData.quickDecode(target: target)
            XCTAssertEqual(decoded, .moveCursor(3))
        }
        do {
            let target = """
            {
                "type": "move_cursor",
                "count": "-8"
            }
            """
            let decoded = CodableActionData.quickDecode(target: target)
            XCTAssertEqual(decoded, nil)
        }
    }

    func testDecodeSmartMoveCursor() {
        do {
            let target = """
            {
                "type": "smart_move_cursor",
                "targets": ["…"],
                "direction": "backward"
            }
            """
            let decoded = CodableActionData.quickDecode(target: target)
            XCTAssertEqual(decoded, .smartMoveCursor(.init(targets: ["…"], direction: .backward)))
        }
        do {
            let target = """
            {
                "direction": "forward",
                "type": "smart_move_cursor",
                "targets": ["、","。","！","？",".",",","．","，", "\\n"]
            }
            """
            let decoded = CodableActionData.quickDecode(target: target)
            XCTAssertEqual(decoded, .smartMoveCursor())
        }
    }

    func testDecodeMoveTab() {
        do {
            let target = """
            {
                "type": "move_tab",
                "tab_type": "system",
                "identifier": "last_tab"
            }
            """
            let decoded = CodableActionData.quickDecode(target: target)
            XCTAssertEqual(decoded, .moveTab(.system(.last_tab)))
        }
        do {
            let target = """
            {
                "type": "move_tab",
                "tab_type": "custom",
                "identifier": "flick_greek"
            }
            """
            let decoded = CodableActionData.quickDecode(target: target)
            XCTAssertEqual(decoded, .moveTab(.custom("flick_greek")))
        }
    }

    func testDecodeSelectCandidate() throws {
        do {
            let target = """
            {
                "type": "select_candidate",
                "selection": { "type": "first" }
            }
            """
            let decoded: CodableActionData = try CodableActionData.quickDecode(target: target)
            XCTAssertEqual(decoded, .selectCandidate(.first))
        }
        do {
            let target = """
            {
                "selection": { "type": "offset", "value": -1 },
                "type": "select_candidate"
            }
            """
            let decoded: CodableActionData = try CodableActionData.quickDecode(target: target)
            XCTAssertEqual(decoded, .selectCandidate(.offset(-1)))
        }
    }

    func testDecodeCompleteCharacterForm() {
        do {
            let target = """
            {
                "type": "complete_character_form",
                "forms": ["katakana", "uppercase"]
            }
            """
            let decoded = CodableActionData.quickDecode(target: target)
            XCTAssertEqual(decoded, .completeCharacterForm([.katakana, .uppercase]))
        }
        do {
            let target = """
            {
                "type": "complete_character_form",
                "forms": ["hiragana"]
            }
            """
            let decoded = CodableActionData.quickDecode(target: target)
            XCTAssertEqual(decoded, .completeCharacterForm([.hiragana]))
        }
    }

    func testDecodeNoArgumentActions() {
        do {
            let target = """
            {"type": "replace_default"}
            """
            let decoded = CodableActionData.quickDecode(target: target)
            XCTAssertEqual(decoded, .replaceDefault(.default))
        }
        do {
            let target = """
            {"type": "replace_default", "replace_type": "dakuten"}
            """
            let decoded = CodableActionData.quickDecode(target: target)
            XCTAssertEqual(decoded, .replaceDefault(.init(type: .dakuten, fallbacks: [])))
        }
        do {
            let target = """
            {"type": "replace_default", "replace_type": "dakuten", "fallbacks": ["default"]}
            """
            let decoded = CodableActionData.quickDecode(target: target)
            XCTAssertEqual(decoded, .replaceDefault(.init(type: .dakuten, fallbacks: [.default])))
        }
        do {
            let target = """
            {"type": "smart_delete_default"}
            """
            let decoded = CodableActionData.quickDecode(target: target)
            XCTAssertEqual(decoded, .smartDeleteDefault)
        }
        do {
            let target = """
            {"type": "complete"}
            """
            let decoded = CodableActionData.quickDecode(target: target)
            XCTAssertEqual(decoded, .complete)
        }
        do {
            let target = """
            {"type": "enable_resizing_mode"}
            """
            let decoded = CodableActionData.quickDecode(target: target)
            XCTAssertEqual(decoded, .enableResizingMode)
        }
        do {
            let target = """
            {"type": "toggle_cursor_bar"}
            """
            let decoded = CodableActionData.quickDecode(target: target)
            XCTAssertEqual(decoded, .toggleCursorBar)
        }
        do {
            let target = """
            {"type": "toggle_tab_bar"}
            """
            let decoded = CodableActionData.quickDecode(target: target)
            XCTAssertEqual(decoded, .toggleTabBar)
        }
        do {
            let target = """
            {"type": "toggle_caps_lock_state"}
            """
            let decoded = CodableActionData.quickDecode(target: target)
            XCTAssertEqual(decoded, .toggleCapsLockState)
        }
        do {
            let target = """
            {"type": "dismiss_keyboard"}
            """
            let decoded = CodableActionData.quickDecode(target: target)
            XCTAssertEqual(decoded, .dismissKeyboard)
        }
        do {
            let target = """
            {"type": "paste"}
            """
            let decoded = CodableActionData.quickDecode(target: target)
            XCTAssertEqual(decoded, .paste)
        }
    }
    func testDecodeDebugBuildCompatibility() {
        // Debug build compatibility
        do {
            let target = """
            {"type": "__paste"}
            """
            let decoded = CodableActionData.quickDecode(target: target)
            XCTAssertEqual(decoded, .paste)
        }
        do {
            let target = """
            {
                "type": "move_tab",
                "tab_type": "system",
                "identifier": "__emoji_tab"
            }
            """
            let decoded = CodableActionData.quickDecode(target: target)
            XCTAssertEqual(decoded, .moveTab(.system(.emoji_tab)))
        }
    }
}
