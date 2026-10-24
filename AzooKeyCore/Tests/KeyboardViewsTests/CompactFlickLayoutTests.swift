import CustardKit
@testable import KeyboardViews
import XCTest

final class CompactFlickLayoutTests: XCTestCase {
    func test_closedPortraitHeightStopsGrowingWithScreenWidth() {
        for width: CGFloat in [390, 452, 466, 599] {
            let context = KeyboardLayoutContext(containerWidth: width, orientation: .vertical, idiom: .phone, duoFlickEnabled: true)
            XCTAssertEqual(Design.keyboardHeight(context: context), 270, accuracy: 0.001)
            XCTAssertFalse(context.usesSplitFlick)
        }
        XCTAssertEqual(CompactFlickLayout.keyboardHeight(containerWidth: 320, orientation: .vertical), 51 / 74 * 320 + 12, accuracy: 0.001)
    }

    @MainActor
    func test_closedGridFillsTheHostWidthWithNativeReferenceSpacing() {
        let context = KeyboardLayoutContext(containerWidth: 452, orientation: .vertical, idiom: .phone, duoFlickEnabled: true)
        var design = Custard.flickJapanese.interface.tabDesign(interfaceSize: CGSize(width: 452, height: 270), layoutContext: context)
        design.keySpacing = CompactFlickLayout.keySpacing(orientation: .vertical)
        XCTAssertEqual(design.keysWidth, 452, accuracy: 0.001)
        XCTAssertEqual(design.keyViewWidth, 84.8, accuracy: 0.001)
        XCTAssertEqual(design.keyViewHeight, 50.25, accuracy: 0.001)
        XCTAssertEqual(design.horizontalSpacing, 7)
        XCTAssertEqual(design.verticalSpacing, 7)
        XCTAssertEqual(Design.keyboardBarHeight(interfaceHeight: 270, context: context) + 12, 48)
    }

    func test_closedLandscapeDoesNotSplitJustBecauseItIsWide() {
        for width: CGFloat in [678, 760, 874] {
            let context = KeyboardLayoutContext(containerWidth: width, orientation: .horizontal, idiom: .phone,
                                                duoFlickEnabled: true, allowsDuoFlickPanels: false)
            XCTAssertFalse(context.usesSplitFlick)
            XCTAssertEqual(Design.keyboardHeight(context: context), 200, accuracy: 0.001)
            XCTAssertGreaterThanOrEqual(Design.keyboardBarHeight(interfaceHeight: 200, context: context) + 12, 44)
        }
    }

    func test_disablingDuoKeepsTheOriginalHeightCalculation() {
        let context = KeyboardLayoutContext(containerWidth: 452, orientation: .vertical, idiom: .phone)
        XCTAssertEqual(Design.keyboardHeight(context: context), 51 / 74 * 452 + 12, accuracy: 0.001)
    }

    func test_upsideComponentsUseTheSameCompactBaseHeight() {
        let context = KeyboardLayoutContext(containerWidth: 452, orientation: .vertical, idiom: .phone, duoFlickEnabled: true)
        XCTAssertEqual(Design.keyboardHeight(context: context, upsideComponent: .supplementaryCandidates), (270 - 12) * 1.15 + 12, accuracy: 0.001)
    }

    func test_singleAndSplitCacheProfilesAreDifferentAtTheSameWidth() {
        var context = KeyboardLayoutContext(containerWidth: 760, orientation: .horizontal, idiom: .phone, duoFlickEnabled: true)
        let split = context.resolvedSizeCacheIdentifier
        context.allowsDuoFlickPanels = false
        XCTAssertNotEqual(context.resolvedSizeCacheIdentifier, split)
        context.duoFlickEnabled = false
        XCTAssertEqual(context.resolvedSizeCacheIdentifier, "standard")
    }
}
