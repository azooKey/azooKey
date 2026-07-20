import CustardKit
import KanaKanjiConverterModule
@testable import KeyboardViews
import XCTest

final class StandardKeyboardCatalogTests: XCTestCase {
    func testStandardTabsHaveStableOrder() {
        XCTAssertEqual(
            StandardKeyboardCatalog.standardTabs,
            [
                .flick_japanese,
                .flick_english,
                .flick_numbersymbols,
                .qwerty_japanese,
                .qwerty_english,
                .qwerty_numbers,
                .qwerty_symbols,
            ]
        )
    }

    func testTemplatesHaveStableOrderAndIdentifiers() {
        let identifiers = StandardKeyboardCatalog.templates(
            configuration: .default
        ).map(\.identifier)

        XCTAssertEqual(
            identifiers,
            [
                "japanese_flick",
                "english_flick",
                "symbols_flick",
                "japanese_qwerty",
                "english_qwerty",
                "numbers_qwerty",
                "symbols_qwerty",
            ]
        )
    }

    func testDefaultFlickCustardsUseSystemFlickSpace() {
        for keyboard in [
            TabData.SystemTab.flick_japanese,
            .flick_english,
            .flick_numbersymbols,
        ] {
            let custard = StandardKeyboardCatalog.custard(
                for: keyboard,
                configuration: .default
            )
            XCTAssertEqual(
                custard.interface.keys[
                    .gridFit(.init(x: 4, y: 1))
                ],
                .system(.flickSpace)
            )
        }
    }

    func testEnglishShiftConfigurationIsAppliedByCatalog() {
        let none = StandardKeyboardCatalog.custard(
            for: .qwerty_english,
            configuration: .init(
                useEnglishQwertyShiftKey: false,
                useDeprecatedEnglishQwertyShiftKeyBehavior: false,
                numberTabCustomKeys: .defaultValue
            )
        )
        let left = StandardKeyboardCatalog.custard(
            for: .qwerty_english,
            configuration: .init(
                useEnglishQwertyShiftKey: true,
                useDeprecatedEnglishQwertyShiftKeyBehavior: true,
                numberTabCustomKeys: .defaultValue
            )
        )
        let bottom = StandardKeyboardCatalog.custard(
            for: .qwerty_english,
            configuration: .init(
                useEnglishQwertyShiftKey: true,
                useDeprecatedEnglishQwertyShiftKeyBehavior: false,
                numberTabCustomKeys: .defaultValue
            )
        )

        XCTAssertFalse(none.interface.keys.values.contains(.system(.qwertyShift)))
        XCTAssertEqual(
            left.interface.keys[.gridFit(.init(x: 0, y: 1))],
            .system(.qwertyShift)
        )
        XCTAssertEqual(
            bottom.interface.keys[.gridFit(.init(x: 0, y: 3, width: 1.4))],
            .system(.qwertyShift)
        )
    }

    func testResolvedStandardNumberAndSymbolTabsPreserveLanguage() {
        for keyboard in [
            TabData.SystemTab.flick_numbersymbols,
            .qwerty_numbers,
            .qwerty_symbols,
        ] {
            let tab = ResolvedTab.standard(keyboard)
            XCTAssertNil(tab.language)
        }
    }

    func testResolvedCustomCustardKeepsExplicitNoneLanguage() {
        let tab = ResolvedTab.custard(.qwertyNumbers)

        XCTAssertEqual(tab.language, KeyboardLanguage.none)
    }
}
