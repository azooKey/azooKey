import CustardKit
@testable import KeyboardViews
import XCTest

final class DuoFlickLayoutTests: XCTestCase {
    func test_automaticPanelsUseTheFullScreenAndOnlyLeaveTheRequestedGap() throws {
        for width: CGFloat in [600, 680, 760, 1_024, 1_366] {
            let layout = try XCTUnwrap(DuoFlickLayout(containerWidth: width, preferredPanelWidth: 0, minimumCenterGap: 16))
            XCTAssertEqual(layout.centerGap, 16, accuracy: 0.001)
            XCTAssertEqual(layout.panelWidth, (width - 30) / 2, accuracy: 0.001)
            XCTAssertEqual(layout.edgeInset, 7)
        }
    }

    func test_compactAndInvalidContainersUseStandardKeyboard() {
        for width: CGFloat in [0, 390, 599, .nan, .infinity] {
            XCTAssertNil(DuoFlickLayout(containerWidth: width, preferredPanelWidth: 320, minimumCenterGap: 80))
        }
    }

    func test_panelsStayAtEdgesAndLeaveRoomForTheFold() throws {
        for width: CGFloat in [600, 680, 760, 1_024, 1_366] {
            for requestedGap: Double in [0, 80, 240] {
                let layout = try XCTUnwrap(DuoFlickLayout(containerWidth: width, preferredPanelWidth: 320, minimumCenterGap: requestedGap))
                XCTAssertGreaterThanOrEqual(layout.panelWidth, 250)
                XCTAssertLessThanOrEqual(layout.panelWidth, 320)
                XCTAssertGreaterThanOrEqual(layout.centerGap, 0)
                XCTAssertEqual(layout.panelWidth * 2 + layout.centerGap + layout.edgeInset * 2, width, accuracy: 0.001)
            }
        }
    }

    func test_extremePreferencesCannotCreateOverlappingPanels() throws {
        for preference: Double in [-1_000, 0, 10_000, .nan, .infinity] {
            let layout = try XCTUnwrap(DuoFlickLayout(containerWidth: 600, preferredPanelWidth: preference, minimumCenterGap: preference))
            XCTAssertGreaterThanOrEqual(layout.panelWidth, 250)
            XCTAssertGreaterThanOrEqual(layout.centerGap, 0)
            XCTAssertEqual(layout.panelWidth * 2 + layout.centerGap + layout.edgeInset * 2, 600, accuracy: 0.001)
        }
    }

    func test_unfoldedHeightDoesNotGrowWithScreenWidthOrOrientation() {
        for width: CGFloat in [600, 760, 1_024] {
            for orientation in [KeyboardOrientation.vertical, .horizontal] {
                let context = KeyboardLayoutContext(containerWidth: width, orientation: orientation, idiom: .phone, duoFlickEnabled: true)
                XCTAssertEqual(Design.keyboardHeight(context: context), 270, accuracy: 0.001)
                XCTAssertGreaterThan(Design.upsideComponentHeight(.supplementaryCandidates, context: context), 0)
            }
        }
        let folded = KeyboardLayoutContext(containerWidth: 390, orientation: .vertical, idiom: .phone, duoFlickEnabled: true)
        XCTAssertEqual(Design.keyboardHeight(context: folded), CompactFlickLayout.maximumPortraitHeight, accuracy: 0.001)
    }

    @MainActor
    func test_panelsKeepSharedBarHeightAndUsableKeySizes() throws {
        let layout = try XCTUnwrap(DuoFlickLayout(containerWidth: 600, preferredPanelWidth: 320, minimumCenterGap: 240))
        let context = KeyboardLayoutContext(containerWidth: 600, orientation: .vertical, idiom: .phone, duoFlickEnabled: true)
        var design = Custard.flickJapanese.interface.tabDesign(
            interfaceSize: CGSize(width: layout.panelWidth, height: DuoFlickLayout.keyboardHeight),
            layoutContext: context
        )
        design.keySpacing = DuoFlickLayout.keySpacing
        XCTAssertGreaterThanOrEqual(design.keyViewWidth + design.horizontalSpacing / 2, 44)
        XCTAssertGreaterThanOrEqual(design.keyViewHeight, 44)
        XCTAssertEqual(design.keysWidth, layout.panelWidth, accuracy: 0.001)
        XCTAssertEqual(design.horizontalSpacing, 8)
        XCTAssertEqual(design.verticalSpacing, 8)
        XCTAssertEqual(Design.keyboardBarHeight(interfaceHeight: DuoFlickLayout.keyboardHeight, context: context), 44)
        XCTAssertEqual(design.keysHeight + 44 + 12, DuoFlickLayout.keyboardHeight, accuracy: 0.001)
    }

    @MainActor
    func test_compactPanelsKeepTheSameKeySizesInBothOrientations() throws {
        let layout = try XCTUnwrap(DuoFlickLayout(containerWidth: 760, preferredPanelWidth: 0, minimumCenterGap: 16))
        for orientation in [KeyboardOrientation.vertical, .horizontal] {
            let context = KeyboardLayoutContext(containerWidth: 760, orientation: orientation, idiom: .phone, duoFlickEnabled: true)
            var design = Custard.flickJapanese.interface.tabDesign(
                interfaceSize: CGSize(width: layout.panelWidth, height: DuoFlickLayout.keyboardHeight),
                layoutContext: context
            )
            design.keySpacing = DuoFlickLayout.keySpacing
            XCTAssertEqual(design.keyViewWidth, 66.6, accuracy: 0.001)
            XCTAssertEqual(design.keyViewHeight, 47.5, accuracy: 0.001)
            XCTAssertEqual(design.keysWidth, 365, accuracy: 0.001)
        }
    }
}
