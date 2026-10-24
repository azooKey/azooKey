import AzooKeyUtils
import Foundation
import XCTest

@MainActor
final class ResolvedKeyboardSizeTests: XCTestCase {
    func test_cachedSizeCannotLeakBetweenClosedAndSplitOrFromAnOlderBuild() throws {
        let suite = "ResolvedKeyboardSizeTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        SharedStore.setResolvedKeyboardSize(CGSize(width: 452, height: 335), orientation: .vertical, in: defaults)
        XCTAssertNil(SharedStore.resolvedKeyboardSize(orientation: .vertical, layoutProfile: "duo-compact-v1", in: defaults))
        let compact = CGSize(width: 452, height: 272)
        SharedStore.setResolvedKeyboardSize(compact, orientation: .vertical, layoutProfile: "duo-compact-v1", in: defaults)
        XCTAssertEqual(SharedStore.resolvedKeyboardSize(orientation: .vertical, layoutProfile: "duo-compact-v1", in: defaults), compact)
        XCTAssertNil(SharedStore.resolvedKeyboardSize(orientation: .vertical, layoutProfile: "duo-split-v1", in: defaults))
        XCTAssertNil(SharedStore.resolvedKeyboardSize(orientation: .horizontal, layoutProfile: "duo-compact-v1", in: defaults))
        XCTAssertEqual(SharedStore.resolvedKeyboardSize(orientation: .vertical, in: defaults), compact)
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
