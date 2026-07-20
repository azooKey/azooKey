import XCTest
@testable import CustardKit

final class CustardTest: XCTestCase {
    func testDecode() {
        do {
            let target = """
            {
                "identifier": "Hisui no machi",
                "language": "ja_JP",
                "input_style": "direct",
                "metadata": {
                    "custard_version": "1.0",
                    "display_name": "翡翠のまち"
                },
                "interface": {
                    "key_layout": {
                        "type": "grid_fit",
                        "row_count": 1,
                        "column_count": 1,
                    },
                    "key_style": "tenkey_style",
                    "keys": [
                        {
                            "specifier_type": "grid_fit",
                            "specifier": {
                                "x": 0,
                                "y": 0,
                                "width": 1,
                                "height": 1
                            },
                            "key_type": "system",
                            "key": {
                                "type": "enter",
                        }
                        }
                    ]
                }
            }
            """
            XCTAssertEqual(
                Custard.quickDecode(target: target),
                .init(
                    identifier: "Hisui no machi",
                    language: .ja_JP,
                    input_style: .direct,
                    metadata: .init(custard_version: .v1_0, display_name: "翡翠のまち"),
                    interface: .init(keyStyle: .tenkeyStyle, keyLayout: .gridFit(.init(rowCount: 1, columnCount: 1)), keys: [.gridFit(.init(x: 0, y: 0)): .system(.enter)])
                )
            )
        }
    }

    func testEncode() {
        do {
            let cuneiforms = Array(String.UnicodeScalarView((UInt32(0x12480)...UInt32(0x12543)).compactMap(UnicodeScalar.init))).map(String.init)
            let keys: [CustardKeyPositionSpecifier: CustardInterfaceKey] = [
                .gridScroll(0): .system(.changeKeyboard),
                .gridScroll(1): .custom(
                    .init(
                        design: .init(label: .text("←"), color: .special),
                        press_actions: [.moveCursor(-1)],
                        longpress_actions: .init(repeat: [.moveCursor(-1)]),
                        variations: []
                    )
                ),
                .gridScroll(2): .custom(
                    .init(
                        design: .init(label: .text("→"), color: .special),
                        press_actions: [.moveCursor(1)],
                        longpress_actions: .init(repeat: [.moveCursor(1)]),
                        variations: []
                    )
                ),
                .gridScroll(3): .custom(
                    .init(
                        design: .init(label: .systemImage("list.bullet"), color: .special),
                        press_actions: [.toggleTabBar],
                        longpress_actions: .none,
                        variations: []
                    )
                ),
                .gridScroll(4): .custom(
                    .init(
                        design: .init(label: .systemImage("delete.left"), color: .special),
                        press_actions: [.delete(1)],
                        longpress_actions: .init(repeat: [.delete(1)]),
                        variations: []
                    )
                )
            ]

            var cuneiforms_keys = keys
            cuneiforms.indices.forEach {
                cuneiforms_keys[.gridScroll(GridScrollPositionSpecifier(cuneiforms_keys.count))] = .custom(
                    .init(
                        design: .init(label: .text(cuneiforms[$0]), color: .normal),
                        press_actions: [.input(cuneiforms[$0])],
                        longpress_actions: .none,
                        variations: []
                    )
                )
            }

            let target = Custard(
                identifier: "Cuneiforms",
                language: .none,
                input_style: .direct,
                metadata: .init(custard_version: .v1_0, display_name: "楔形文字"),
                interface: .init(
                    keyStyle: .tenkeyStyle,
                    keyLayout: .gridScroll(.init(direction: .vertical, rowCount: 8, columnCount: 4.2)),
                    keys: cuneiforms_keys
                )
            )
            XCTAssertEqual(target.quickEncodeDecode(), target)
        }
    }

}
