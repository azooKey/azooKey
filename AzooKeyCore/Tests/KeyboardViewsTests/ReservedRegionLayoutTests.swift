import Foundation
@testable import KeyboardViews
import SwiftUIUtils
import XCTest

final class ReservedRegionLayoutTests: XCTestCase {
    func test_flatDisplayKeepsNativeReferenceGeometry() throws {
        let layout = try XCTUnwrap(DuoFlickLayout(containerWidth: 760, preferredPanelWidth: 0, minimumCenterGap: 16))
        XCTAssertEqual(layout.panelFrames(keyAreaHeight: 214, avoiding: []), [
            CGRect(x: 7, y: 0, width: 365, height: 214),
            CGRect(x: 388, y: 0, width: 365, height: 214),
        ])
    }

    func test_manualShorterHeightKeepsBothPanelsWhenUnobstructed() throws {
        let layout = try XCTUnwrap(DuoFlickLayout(containerWidth: 760, preferredPanelWidth: 0, minimumCenterGap: 16))
        let frames = layout.panelFrames(keyAreaHeight: 170, avoiding: [])
        XCTAssertEqual(frames.count, 2)
        XCTAssertTrue(frames.allSatisfy { $0.height == 170 })
    }

    func test_invalidHeightDoesNotCreateTouchablePanels() throws {
        let layout = try XCTUnwrap(DuoFlickLayout(containerWidth: 760, preferredPanelWidth: 0, minimumCenterGap: 16))
        for height: CGFloat in [0, -1, .nan, .infinity] {
            XCTAssertTrue(layout.panelFrames(keyAreaHeight: height, avoiding: []).isEmpty)
        }
    }

    func test_verticalFoldExpandsTheGapWithoutAddingSystemMarginsAgain() throws {
        let layout = try XCTUnwrap(DuoFlickLayout(containerWidth: 760, preferredPanelWidth: 0, minimumCenterGap: 16))
        let fold = CGRect(x: 360, y: -50, width: 40, height: 400)
        let frames = layout.panelFrames(keyAreaHeight: 214, avoiding: [fold])
        XCTAssertEqual(frames.count, 2)
        XCTAssertEqual(frames[0].maxX, fold.minX)
        XCTAssertEqual(frames[1].minX, fold.maxX)
        XCTAssertEqual(frames[0].minX, 7)
        XCTAssertEqual(frames[1].maxX, 753)
    }

    func test_cameraOcclusionIsClippedToTheLocalKeyArea() throws {
        let layout = try XCTUnwrap(DuoFlickLayout(containerWidth: 1_024, preferredPanelWidth: 0, minimumCenterGap: 16))
        let camera = CGRect(x: 950, y: -25, width: 100, height: 75)
        let frames = layout.panelFrames(keyAreaHeight: 214, avoiding: [camera])
        XCTAssertEqual(frames.count, 2)
        assertSafe(frames, obstacles: [camera])
        XCTAssertEqual(frames[1].maxX, 950)
    }

    func test_offCenterFoldFallsBackToOneCompleteUsablePanel() throws {
        let layout = try XCTUnwrap(DuoFlickLayout(containerWidth: 760, preferredPanelWidth: 0, minimumCenterGap: 16))
        let fold = CGRect(x: 200, y: -20, width: 40, height: 300)
        let frames = layout.panelFrames(keyAreaHeight: 214, avoiding: [fold])
        XCTAssertEqual(frames.count, 1)
        XCTAssertGreaterThanOrEqual(frames[0].width, 250)
        assertSafe(frames, obstacles: [fold])
    }

    func test_foldAboveKeyboardDoesNotConsumeKeyboardSpace() throws {
        let layout = try XCTUnwrap(DuoFlickLayout(containerWidth: 760, preferredPanelWidth: 0, minimumCenterGap: 16))
        XCTAssertEqual(layout.panelFrames(keyAreaHeight: 214, avoiding: [CGRect(x: 0, y: -50, width: 760, height: 30)]),
                       layout.panelFrames(keyAreaHeight: 214, avoiding: []))
    }

    func test_barKeepsAllControlsInOneUnobstructedRectangle() {
        let bounds = CGRect(x: 0, y: 0, width: 760, height: 56)
        let fold = CGRect(x: 360, y: -20, width: 40, height: 100)
        XCTAssertEqual(AvailableLayoutRegion.largest(in: bounds, avoiding: [fold]), CGRect(x: 0, y: 0, width: 360, height: 56))
    }

    func test_multipleAndOverlappingRegionsDoNotCoverControls() {
        let bounds = CGRect(x: 0, y: 0, width: 1_024, height: 214)
        let obstacles = [CGRect(x: 500, y: -50, width: 30, height: 400),
                         CGRect(x: 900, y: 0, width: 200, height: 60),
                         CGRect(x: 510, y: 0, width: 30, height: 300)]
        let frame = AvailableLayoutRegion.largest(in: bounds, avoiding: obstacles)
        XCTAssertTrue(bounds.contains(frame))
        assertSafe([frame], obstacles: obstacles)
    }

    func test_invalidAndOutsideRegionsAreIgnored() {
        let bounds = CGRect(x: 0, y: 0, width: 760, height: 56)
        let regions = [CGRect.null, CGRect.infinite, .zero,
                       CGRect(x: CGFloat.nan, y: 0, width: 50, height: 56),
                       CGRect(x: 800, y: 0, width: 20, height: 56)]
        XCTAssertEqual(AvailableLayoutRegion.largest(in: bounds, avoiding: regions), bounds)
        XCTAssertEqual(AvailableLayoutRegion.largest(in: .zero, avoiding: []), .zero)
    }

    func test_horizontalFoldSelectsAFullWidthAreaInsteadOfCrossingTheFold() {
        let bounds = CGRect(x: 0, y: 0, width: 760, height: 500)
        let fold = CGRect(x: -10, y: 200, width: 780, height: 40)
        XCTAssertEqual(AvailableLayoutRegion.largest(in: bounds, avoiding: [fold]), CGRect(x: 0, y: 240, width: 760, height: 260))
    }

    func test_fullyCoveredBoundsHaveNoInteractionArea() {
        let bounds = CGRect(x: 0, y: 0, width: 760, height: 56)
        XCTAssertEqual(AvailableLayoutRegion.largest(in: bounds, avoiding: [bounds]), .zero)
    }

    private func assertSafe(_ frames: [CGRect], obstacles: [CGRect], file: StaticString = #filePath, line: UInt = #line) {
        for frame in frames {
            XCTAssertGreaterThan(frame.width, 0, file: file, line: line)
            XCTAssertGreaterThan(frame.height, 0, file: file, line: line)
            for obstacle in obstacles {
                let overlap = frame.intersection(obstacle)
                XCTAssertTrue(overlap.isNull || overlap.isEmpty, "Control overlaps reserved region", file: file, line: line)
            }
        }
    }
}
