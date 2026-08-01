@testable import CustardKit
import XCTest

final class GridFitPositionSpecifierTests: XCTestCase {
    private let bounds = GridFitPositionSpecifier(
        x: 0,
        y: 0,
        width: 5,
        height: 4
    )

    func testIntersectsWhenFullyInsideBounds() {
        XCTAssertTrue(
            GridFitPositionSpecifier(x: 1, y: 1).intersects(bounds)
        )
    }

    func testIntersectsWhenPartiallyOutsideBounds() {
        XCTAssertTrue(
            GridFitPositionSpecifier(
                x: -0.5,
                y: 3.5,
                width: 1,
                height: 1
            ).intersects(bounds)
        )
    }

    func testDoesNotIntersectWhenFullyOutsideBounds() {
        XCTAssertFalse(
            GridFitPositionSpecifier(x: 5, y: 0).intersects(bounds)
        )
        XCTAssertFalse(
            GridFitPositionSpecifier(x: -1, y: 0).intersects(bounds)
        )
        XCTAssertFalse(
            GridFitPositionSpecifier(x: 0, y: 4).intersects(bounds)
        )
        XCTAssertFalse(
            GridFitPositionSpecifier(x: 0, y: -1).intersects(bounds)
        )
    }
}
