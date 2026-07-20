@testable import CustardKit
import XCTest

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
            {
            "key_layout": {
                "type": "grid_fit",
                "row_count": 10,
                "column_count": 4
            },
            "key_style": "pc_style",
            "keys": [{
                "specifier_type": "grid_fit",
                "specifier": {
                    "x": 1.5,
                    "y": 2,
                    "width": 1.4,
                    "height": 1
                },
                "key_type": "system",
                "key": {
                    "type": "qwerty_shift"
                }
            }]}
            """
            XCTAssertEqual(
                CustardInterface.quickDecode(target: target),
                .init(
                    keyStyle: .pcStyle,
                    keyLayout: .gridFit(
                        .init(rowCount: 10, columnCount: 4)
                    ),
                    keys: [
                        .gridFit(
                            .init(x: 1.5, y: 2, width: 1.4)
                        ): .system(.qwertyShift),
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
            let target = CustardInterface(
                keyStyle: .pcStyle,
                keyLayout: .gridScroll(
                    .init(
                        direction: .vertical,
                        rowCount: 3,
                        columnCount: 8
                    )
                ),
                keys: [
                    .gridScroll(0): .custom(.flickDelete()),
                    .gridScroll(1): .custom(.flickSpace()),
                ]
            )
            XCTAssertEqual(target.quickEncodeDecode(), target)
        }
        do {
            let target = CustardInterface(
                keyStyle: .pcStyle,
                keyLayout: .gridFit(
                    .init(rowCount: 10, columnCount: 4)
                ),
                keys: [
                    .gridFit(
                        .init(x: 2.8, y: 3, width: 4.4)
                    ): .custom(.flickSpace()),
                ]
            )
            XCTAssertEqual(target.quickEncodeDecode(), target)
        }
    }

    func testQwertySystemKeysRequirePCStyleGridFit() throws {
        let qwertyKeys: [CustardInterfaceSystemKey] = [
            .qwertyLanguageSwitch,
            .qwertyShift,
            .qwertyDynamicChange,
            .qwertySpace,
        ]

        for key in qwertyKeys {
            let valid = CustardInterface(
                keyStyle: .pcStyle,
                keyLayout: .gridFit(
                    .init(rowCount: 10, columnCount: 4)
                ),
                keys: [
                    .gridFit(.init(x: 0, y: 0)): .system(key),
                ]
            )
            XCTAssertNoThrow(try valid.validate())

            let invalidScroll = CustardInterface(
                keyStyle: .pcStyle,
                keyLayout: .gridScroll(
                    .init(
                        direction: .vertical,
                        rowCount: 4,
                        columnCount: 8
                    )
                ),
                keys: [
                    .gridScroll(0): .system(key),
                ]
            )
            XCTAssertThrowsError(try invalidScroll.validate()) { error in
                XCTAssertEqual(
                    error as? CustardInterfaceValidationError,
                    .qwertySystemKeyRequiresPCStyleGridFit
                )
            }
            XCTAssertThrowsError(try JSONEncoder().encode(invalidScroll))
        }

        let invalidTenkey = CustardInterface(
            keyStyle: .tenkeyStyle,
            keyLayout: .gridFit(.init(rowCount: 5, columnCount: 4)),
            keys: [
                .gridFit(.init(x: 0, y: 0)):
                    .system(.qwertyLanguageSwitch),
            ]
        )
        XCTAssertThrowsError(try invalidTenkey.validate())
    }

    func testDecodeRejectsQwertySystemKeyInGridScroll() {
        let target = """
        {
          "key_layout": {
            "type": "grid_scroll",
            "direction": "vertical",
            "row_count": 4,
            "column_count": 8
          },
          "key_style": "pc_style",
          "keys": [{
            "specifier_type": "grid_scroll",
            "specifier": {"index": 0},
            "key_type": "system",
            "key": {"type": "qwerty_space"}
          }]
        }
        """

        XCTAssertNil(CustardInterface.quickDecode(target: target))
    }
}
