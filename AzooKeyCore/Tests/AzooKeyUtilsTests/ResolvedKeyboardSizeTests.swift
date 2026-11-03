import AzooKeyUtils
import Foundation
import XCTest

@MainActor
final class ResolvedKeyboardSizeTests: XCTestCase {
    func test_cachedSizeIsIsolatedByOrientation() throws {
        let suite = "ResolvedKeyboardSizeTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let portrait = CGSize(width: 452, height: 335)
        SharedStore.setResolvedKeyboardSize(portrait, orientation: .vertical, in: defaults)
        XCTAssertEqual(SharedStore.resolvedKeyboardSize(orientation: .vertical, in: defaults), portrait)
        XCTAssertNil(SharedStore.resolvedKeyboardSize(orientation: .horizontal, in: defaults))
    }

    func test_invalidSizeDoesNotReplaceTheValidCachedSize() throws {
        let suite = "ResolvedKeyboardSizeTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let valid = CGSize(width: 452, height: 272)
        SharedStore.setResolvedKeyboardSize(valid, orientation: .vertical, in: defaults)
        for width: CGFloat in [0, -1, .nan, .infinity] {
            SharedStore.setResolvedKeyboardSize(CGSize(width: width, height: 272), orientation: .vertical, in: defaults)
            XCTAssertEqual(SharedStore.resolvedKeyboardSize(orientation: .vertical, in: defaults), valid)
        }
    }
}
