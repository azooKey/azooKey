@testable import KeyboardViews
import XCTest

final class VariationsViewDirectionTests: XCTestCase {
    func test_automaticUsesRightAtLeadingEdge() {
        XCTAssertEqual(
            VariationsViewDirection.automatic(
                position: .init(x: 0, y: 0),
                variationCount: 4,
                horizontalKeyCount: 10
            ),
            .right
        )
    }

    func test_automaticUsesLeftAtTrailingEdge() {
        XCTAssertEqual(
            VariationsViewDirection.automatic(
                position: .init(x: 9, y: 0),
                variationCount: 4,
                horizontalKeyCount: 10
            ),
            .left
        )
    }

    func test_automaticUsesCenterWhenVariationsFit() {
        XCTAssertEqual(
            VariationsViewDirection.automatic(
                position: .init(x: 4, y: 0),
                variationCount: 4,
                horizontalKeyCount: 10
            ),
            .center
        )
    }

    func test_automaticAccountsForWideKeys() {
        XCTAssertEqual(
            VariationsViewDirection.automatic(
                position: .init(x: 7.2, y: 0, width: 2.8),
                variationCount: 6,
                horizontalKeyCount: 10
            ),
            .left
        )
    }

    func test_automaticMinimizesOverflowWhenNoDirectionFits() {
        XCTAssertEqual(
            VariationsViewDirection.automatic(
                position: .init(x: 0, y: 0),
                variationCount: 12,
                horizontalKeyCount: 10
            ),
            .right
        )
        XCTAssertEqual(
            VariationsViewDirection.automatic(
                position: .init(x: 4.5, y: 0),
                variationCount: 12,
                horizontalKeyCount: 10
            ),
            .center
        )
    }
}
