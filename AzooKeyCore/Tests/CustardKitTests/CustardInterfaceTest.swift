import XCTest
@testable import CustardKit

final class CustardInterfaceTest: XCTestCase {
    func testDecode() {
        do {
            let target = """
            {
            "key_layout": {
                "type": "grid_fit",
                "row_count": 3,
                "column_count": 2,
            },
            "key_style": "tenkey_style",
            "keys": [{
                "specifier_type": "grid_fit",
                "specifier": {
                    "x": 1,
                    "y": 0,
                    "width": 1,
                    "height": 1
                },
                "key_type": "custom",
                "key": {
                    "design": {"label":{"text": "超弩級"}, "color": "normal"},
                    "press_actions": [],
                    "longpress_actions": {
                        "start": [],
                        "repeat": []
                    },
                    "variations": []
                }
            }]}
            """
            XCTAssertEqual(
                CustardInterface.quickDecode(target: target),
                .init(
                    keyStyle: .tenkeyStyle,
                    keyLayout: .gridFit(.init(rowCount: 3, columnCount: 2)),
                    keys: [
                        .gridFit(.init(x: 1, y: 0)): .custom(.init(design: .init(label: .text("超弩級"), color: .normal), press_actions: [], longpress_actions: .none, variations: []))
                    ]
                )
            )
        }
        do {
            let target = """
            {"key_layout": {
                "type": "grid_scroll",
                "direction": "horizontal",
                "row_count": 7.5,
                "column_count": 3.3,
            },
            "key_style": "pc_style",
            "keys": [{
                "specifier_type": "grid_scroll",
                "specifier": {
                    "index": 1,
                },
                "key_type": "system",
                "key": {
                    "type": "change_keyboard",
                }
            }]}
            """
            XCTAssertEqual(
                CustardInterface.quickDecode(target: target),
                .init(
                    keyStyle: .pcStyle,
                    keyLayout: .gridScroll(.init(direction: .horizontal, rowCount: 7.5, columnCount: 3.3)),
                    keys: [
                        .gridScroll(1): .system(.changeKeyboard)
                    ]
                )
            )
        }

    }

    func testEncode() {
        do {
            let target = CustardInterface.init(keyStyle: .pcStyle, keyLayout: .gridScroll(.init(direction: .vertical, rowCount: 3, columnCount: 8)), keys: [.gridScroll(0): .custom(.flickDelete()), .gridScroll(1): .custom(.flickSpace())])
            XCTAssertEqual(target.quickEncodeDecode(), target)
        }
    }
}
