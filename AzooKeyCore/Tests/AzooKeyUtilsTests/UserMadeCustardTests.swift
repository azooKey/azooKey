@testable import AzooKeyUtils
import CustardKit
import KeyboardViews
import XCTest

final class UserMadeCustardTests: XCTestCase {
    private func makeGridFitCustard(
        keyStyle: UserMadeGridFitCustard.KeyStyle
    ) -> UserMadeGridFitCustard {
        UserMadeGridFitCustard(
            tabName: "test",
            rowCount: "2",
            columnCount: "1",
            inputStyle: .direct,
            language: .en_US,
            keys: [:],
            keyStyle: keyStyle,
            addTabBarAutomatically: false
        )
    }

    func test_gridFitKeyStyleRoundTrips() throws {
        let original = makeGridFitCustard(keyStyle: .pcStyle)

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(
            UserMadeGridFitCustard.self,
            from: data
        )

        XCTAssertEqual(decoded, original)
        XCTAssertEqual(decoded.keyStyle, .pcStyle)
    }

    func test_fractionalGridFitEditingDataRoundTrips() throws {
        var original = makeGridFitCustard(keyStyle: .pcStyle)
        original.keys[.gridFit(x: 1.5, y: 2.3)] = .init(
            model: .system(.qwertySpace),
            width: 1.4,
            height: 0.5
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(
            UserMadeGridFitCustard.self,
            from: data
        )

        XCTAssertEqual(decoded.tabName, original.tabName)
        XCTAssertEqual(decoded.rowCount, original.rowCount)
        XCTAssertEqual(decoded.columnCount, original.columnCount)
        XCTAssertEqual(decoded.inputStyle, original.inputStyle)
        XCTAssertEqual(decoded.language, original.language)
        XCTAssertEqual(decoded.keyStyle, original.keyStyle)
        XCTAssertEqual(decoded.emptyKeys, original.emptyKeys)
        XCTAssertEqual(
            decoded.keys[.gridFit(x: 1.5, y: 2.3)]?.model,
            .system(.qwertySpace)
        )
        XCTAssertEqual(
            decoded.keys[.gridFit(x: 1.5, y: 2.3)]?.width,
            1.4
        )
        XCTAssertEqual(
            decoded.keys[.gridFit(x: 1.5, y: 2.3)]?.height,
            0.5
        )
    }

    func test_legacyIntegerKeySizeDecodes() throws {
        let data = Data(
            """
            {
              "type": "system",
              "key": {"type": "enter"},
              "width": 1,
              "height": 2
            }
            """.utf8
        )

        let decoded = try JSONDecoder().decode(
            UserMadeKeyData.self,
            from: data
        )

        XCTAssertEqual(decoded.width, 1)
        XCTAssertEqual(decoded.height, 2)
    }

    func test_legacyGridFitDataDefaultsToTenkeyStyle() throws {
        let original = UserMadeCustard.tenkey(
            makeGridFitCustard(keyStyle: .pcStyle)
        )
        let encoded = try JSONEncoder().encode(original)
        var json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        )
        var tenkey = try XCTUnwrap(json["tenkey"] as? [String: Any])
        tenkey.removeValue(forKey: "keyStyle")
        json["tenkey"] = tenkey
        let legacyData = try JSONSerialization.data(withJSONObject: json)

        let decoded = try JSONDecoder().decode(
            UserMadeCustard.self,
            from: legacyData
        )

        guard case let .tenkey(value) = decoded else {
            return XCTFail("Expected grid-fit editing data")
        }
        XCTAssertEqual(value.keyStyle, .tenkeyStyle)
    }

    func test_pcStyleCustardCanBeConvertedForEditing() throws {
        let custard = Custard(
            identifier: "pc-style",
            language: .en_US,
            input_style: .direct,
            metadata: .init(
                custard_version: .v1_2,
                display_name: "PC Style"
            ),
            interface: .init(
                keyStyle: .pcStyle,
                keyLayout: .gridFit(.init(rowCount: 2, columnCount: 1)),
                keys: [
                    .gridFit(.init(x: 0, y: 0)): .system(.enter),
                ]
            )
        )

        let editingData = try XCTUnwrap(custard.userMadeGridFitCustard)

        XCTAssertEqual(editingData.keyStyle, .pcStyle)
        XCTAssertEqual(editingData.rowCount, "2")
        XCTAssertEqual(editingData.columnCount, "1")
        XCTAssertEqual(
            editingData.keys[.gridFit(x: 0, y: 0)]?.model,
            .system(.enter)
        )
        XCTAssertTrue(editingData.emptyKeys.isEmpty)
    }

    func test_defaultQwertyCustardsCanBeConvertedForEditing() throws {
        let custards: [Custard] = [
            .qwertyJapanese,
            .qwertyEnglish,
            .qwertyNumbers,
            .qwertySymbols,
        ]

        for custard in custards {
            let editingData = try XCTUnwrap(
                custard.userMadeGridFitCustard,
                custard.identifier
            )

            XCTAssertEqual(editingData.keyStyle, .pcStyle)
            XCTAssertEqual(editingData.rowCount, "10")
            XCTAssertEqual(editingData.columnCount, "4")
            XCTAssertFalse(editingData.keys.isEmpty)
            XCTAssertNotNil(
                editingData.keys[.gridFit(x: 1.5, y: 2)],
                custard.identifier
            )
        }
    }

    func test_defaultQwertyCustardsUseStandardLanguageKeys() {
        assertLanguageKey(
            in: .qwertyJapanese,
            at: .init(x: 0, y: 2, width: 1.4)
        )
        assertLanguageKey(
            in: .qwertyEnglish,
            at: .init(x: 0, y: 2, width: 1.4)
        )
        for custard in [Custard.qwertyNumbers, .qwertySymbols] {
            assertLanguageKey(
                in: custard,
                at: .init(x: 0, y: 3, width: 1.4)
            )
        }
    }

    func test_defaultQwertyCustardsUseStandardBottomRowGeometry() throws {
        let positions = [
            GridFitPositionSpecifier(x: 0, y: 3, width: 1.4),
            GridFitPositionSpecifier(x: 1.4, y: 3, width: 1.4),
            GridFitPositionSpecifier(x: 2.8, y: 3, width: 4.4),
            GridFitPositionSpecifier(x: 7.2, y: 3, width: 2.8),
        ]

        for custard in [
            Custard.qwertyJapanese,
            .qwertyEnglish,
            .qwertyNumbers,
            .qwertySymbols,
        ] {
            for position in positions {
                XCTAssertNotNil(
                    custard.interface.keys[.gridFit(position)],
                    "\(custard.identifier): \(position)"
                )
            }
            XCTAssertEqual(
                custard.interface.keys[
                    .gridFit(.init(x: 1.4, y: 3, width: 1.4))
                ],
                .system(.qwertyDynamicChange)
            )
            XCTAssertEqual(
                custard.interface.keys[
                    .gridFit(.init(x: 2.8, y: 3, width: 4.4))
                ],
                .system(.qwertySpace)
            )
        }
    }

    func test_defaultQwertySymbolRowsUseEqualKeyWidths() {
        let positions = [1.5, 2.9, 4.3, 5.7, 7.1].map {
            GridFitPositionSpecifier(x: $0, y: 2, width: 1.4)
        }

        for custard in [Custard.qwertyNumbers, .qwertySymbols] {
            for position in positions {
                XCTAssertNotNil(
                    custard.interface.keys[.gridFit(position)],
                    "\(custard.identifier): \(position)"
                )
            }
        }
    }

    func test_defaultQwertyCustardsPreserveVariationPresentation() throws {
        let japaneseLetter = try customKey(
            in: .qwertyJapanese,
            at: .init(x: 0, y: 0)
        )
        XCTAssertEqual(
            japaneseLetter.longpress_variation_direction,
            .right
        )
        XCTAssertEqual(japaneseLetter.shows_tap_bubble, true)

        let japaneseBar = try customKey(
            in: .qwertyJapanese,
            at: .init(x: 9, y: 1)
        )
        XCTAssertEqual(japaneseBar.longpress_variation_direction, .left)
        XCTAssertEqual(japaneseBar.shows_tap_bubble, true)

        let numberCenter = try customKey(
            in: .qwertyNumbers,
            at: .init(x: 4, y: 0)
        )
        XCTAssertEqual(numberCenter.longpress_variation_direction, .center)
        XCTAssertEqual(numberCenter.shows_tap_bubble, true)

        let numberRightEdge = try customKey(
            in: .qwertyNumbers,
            at: .init(x: 0, y: 0)
        )
        XCTAssertEqual(numberRightEdge.longpress_variation_direction, .right)

        let numberLeftEdge = try customKey(
            in: .qwertyNumbers,
            at: .init(x: 9, y: 0)
        )
        XCTAssertEqual(numberLeftEdge.longpress_variation_direction, .left)

        let symbolWithoutVariations = try customKey(
            in: .qwertySymbols,
            at: .init(x: 0, y: 1)
        )
        XCTAssertEqual(
            symbolWithoutVariations.longpress_variation_direction,
            .right
        )
        XCTAssertEqual(symbolWithoutVariations.shows_tap_bubble, false)
    }

    func test_shiftEnabledEnglishQwertyUsesSystemShiftKey() {
        let custard = Custard.qwertyEnglish(useShiftKey: true)

        XCTAssertEqual(
            custard.interface.keys[
                .gridFit(.init(x: 0, y: 3, width: 1.4))
            ],
            .system(.qwertyShift)
        )
        XCTAssertNotEqual(
            custard.interface.keys[.gridFit(.init(x: 9, y: 1))],
            .system(.upperLower)
        )
    }

    func test_deprecatedShiftEnglishQwertyUsesLeftShiftKey() {
        let custard = Custard.qwertyEnglish(
            useShiftKey: true,
            useDeprecatedShiftKeyBehavior: true
        )

        XCTAssertEqual(
            custard.interface.keys[.gridFit(.init(x: 0, y: 1))],
            .system(.qwertyShift)
        )
        XCTAssertNotEqual(
            custard.interface.keys[
                .gridFit(.init(x: 0, y: 3, width: 1.4))
            ],
            .system(.qwertyShift)
        )
    }

    private func assertLanguageKey(
        in custard: Custard,
        at position: GridFitPositionSpecifier,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(
            custard.interface.keys[.gridFit(position)],
            .system(.qwertyLanguageSwitch),
            file: file,
            line: line
        )
    }

    private func customKey(
        in custard: Custard,
        at position: GridFitPositionSpecifier,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> CustardInterfaceCustomKey {
        let interfaceKey = try XCTUnwrap(
            custard.interface.keys[.gridFit(position)],
            file: file,
            line: line
        )
        guard case let .custom(key) = interfaceKey else {
            XCTFail("Expected custom key", file: file, line: line)
            throw TestError.expectedCustomKey
        }
        return key
    }

    private enum TestError: Error {
        case expectedCustomKey
    }
}
