import AzooKeyUtils
import Foundation
import XCTest

@MainActor
final class DuoFlickLayoutDefaultsTests: XCTestCase {
    func test_existingNarrowPreferencesExpandOnceAndLaterAdjustmentsAreKept() throws {
        let suite = "DuoFlickLayoutDefaultsTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(320.0, forKey: DuoFlickPanelWidth.key)
        defaults.set(80.0, forKey: DuoFlickCenterGap.key)

        DuoFlickLayoutDefaults.migrateIfNeeded(in: defaults)
        XCTAssertEqual(defaults.double(forKey: DuoFlickPanelWidth.key), 0)
        XCTAssertEqual(defaults.double(forKey: DuoFlickCenterGap.key), 16)

        defaults.set(450.0, forKey: DuoFlickPanelWidth.key)
        defaults.set(8.0, forKey: DuoFlickCenterGap.key)
        DuoFlickLayoutDefaults.migrateIfNeeded(in: defaults)
        XCTAssertEqual(defaults.double(forKey: DuoFlickPanelWidth.key), 450)
        XCTAssertEqual(defaults.double(forKey: DuoFlickCenterGap.key), 8)
    }
}
