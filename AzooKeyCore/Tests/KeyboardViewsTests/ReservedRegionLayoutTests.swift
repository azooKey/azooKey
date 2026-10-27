import Foundation
@testable import KeyboardViews
import SwiftUIUtils
import XCTest

final class ReservedRegionLayoutTests: XCTestCase {
    func test_barKeepsAllControlsInOneUnobstructedRectangle() {
        let bounds = CGRect(x: 0, y: 0, width: 760, height: 56)
        let fold = CGRect(x: 360, y: -20, width: 40, height: 100)
        XCTAssertEqual(AvailableLayoutRegion.largest(in: bounds, avoiding: [fold]), CGRect(x: 0, y: 0, width: 360, height: 56))
    }

    func test_multipleAndOverlappingRegionsDoNotCoverControls() {
        let bounds = CGRect(x: 0, y: 0, width: 1_024, height: 214)
        let obstacles = [
            CGRect(x: 500, y: -50, width: 30, height: 400),
            CGRect(x: 900, y: 0, width: 200, height: 60),
            CGRect(x: 510, y: 0, width: 30, height: 300),
        ]
        let frame = AvailableLayoutRegion.largest(in: bounds, avoiding: obstacles)
        XCTAssertTrue(bounds.contains(frame))
        assertSafe([frame], obstacles: obstacles)
    }

    func test_invalidAndOutsideRegionsAreIgnored() {
        let bounds = CGRect(x: 0, y: 0, width: 760, height: 56)
        let regions = [
            CGRect.null, CGRect.infinite, .zero,
            CGRect(x: CGFloat.nan, y: 0, width: 50, height: 56),
            CGRect(x: 800, y: 0, width: 20, height: 56),
        ]
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
