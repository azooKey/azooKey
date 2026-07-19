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
            XCTAssertEqual(editingData.rowCount, "20")
            XCTAssertEqual(editingData.columnCount, "4")
            XCTAssertFalse(editingData.keys.isEmpty)
            XCTAssertEqual(
                editingData.keys.count + editingData.emptyKeys.count,
                80,
                custard.identifier
            )
        }
    }

    func test_defaultQwertyCustardsUseStandardLanguageKeys() {
        assertLanguageKey(
            in: .qwertyJapanese,
            at: .init(x: 0, y: 2, width: 3)
        )
        assertLanguageKey(
            in: .qwertyEnglish,
            at: .init(x: 0, y: 2, width: 3)
        )
        for custard in [Custard.qwertyNumbers, .qwertySymbols] {
            assertLanguageKey(
                in: custard,
                at: .init(x: 0, y: 3, width: 3)
            )
        }
    }

    func test_defaultQwertyCustardsUseStandardBottomRowGeometry() throws {
        let positions = [
            GridFitPositionSpecifier(x: 0, y: 3, width: 3),
            GridFitPositionSpecifier(x: 3, y: 3, width: 3),
            GridFitPositionSpecifier(x: 6, y: 3, width: 8),
            GridFitPositionSpecifier(x: 14, y: 3, width: 6),
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
        }
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
}
