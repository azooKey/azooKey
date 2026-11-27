@testable import AzooKeyUtils
import Foundation
import XCTest

final class ThemeManagerTests: XCTestCase {
    func testSystemThemesAreIncludedInDisplayOrder() {
        let manager = ThemeIndexManager(index: ThemeIndices())

        XCTAssertEqual(
            Array(manager.indices.reversed()),
            [
                ThemeIndices.minimumThemeIndex,
                ThemeIndices.technoThemeIndex,
                ThemeIndices.classicDefaultThemeIndex,
                ThemeIndices.defaultThemeIndex,
            ]
        )
    }

    func testSystemThemeIndicesResolveToTheirThemes() throws {
        let manager = ThemeIndexManager(index: ThemeIndices())

        XCTAssertEqual(
            try manager.theme(at: ThemeIndices.minimumThemeIndex),
            .minimum
        )
        XCTAssertEqual(
            try manager.theme(at: ThemeIndices.technoThemeIndex),
            .techno
        )
    }

    func testNewSystemThemesUseTransparentKeyboardBackgrounds() {
        let themes = [AzooKeyTheme.minimum, .techno]

        for theme in themes {
            XCTAssertEqual(theme.backgroundColor, .dynamic(.clear))
            XCTAssertEqual(theme.resultBackgroundColor, .dynamic(.clear))
        }
    }

    func testNewSystemThemesHaveDistinctKeyRendering() {
        XCTAssertEqual(AzooKeyTheme.minimum.style, .minimal)

        XCTAssertEqual(AzooKeyTheme.techno.style, .faceted)
    }

    func testSavedThemesWithoutStyleUseStandardRendering() throws {
        var theme = AzooKeyTheme.base
        theme.id = 1
        let encodedTheme = try JSONEncoder().encode(theme)
        var object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: encodedTheme) as? [String: Any]
        )
        object.removeValue(forKey: "style")
        let legacyTheme = try JSONSerialization.data(withJSONObject: object)

        let decodedTheme = try JSONDecoder().decode(AzooKeyTheme.self, from: legacyTheme)

        XCTAssertEqual(decodedTheme.style, .standard)
    }

    func testSystemThemesCannotBeRemoved() {
        var manager = ThemeIndexManager(index: ThemeIndices())
        let originalIndices = manager.indices

        manager.remove(index: ThemeIndices.minimumThemeIndex)
        manager.remove(index: ThemeIndices.technoThemeIndex)
        XCTAssertEqual(manager.indices, originalIndices)
    }
}
