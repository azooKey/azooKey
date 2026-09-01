@testable import KeyboardViews
import XCTest

final class TabDependentDesignTests: XCTestCase {
    private let interfaceSize = CGSize(width: 1_000, height: 300)

    private func design(
        horizontalKeyCount: CGFloat = 10,
        verticalKeyCount: CGFloat = 4,
        orientation: KeyboardOrientation
    ) -> TabDependentDesign {
        TabDependentDesign(
            width: horizontalKeyCount,
            height: verticalKeyCount,
            interfaceSize: interfaceSize,
            layoutContext: KeyboardLayoutContext(
                containerWidth: interfaceSize.width,
                orientation: orientation,
                idiom: .phone
            )
        )
    }

    func test_horizontalSizingKeepsTenKeyRatiosForLargerLayouts() {
        for orientation in [KeyboardOrientation.vertical, .horizontal] {
            let tenKeyDesign = design(horizontalKeyCount: 10, orientation: orientation)
            let twentyKeyDesign = design(horizontalKeyCount: 20, orientation: orientation)

            XCTAssertEqual(
                tenKeyDesign.keyViewWidth * 10,
                twentyKeyDesign.keyViewWidth * 20,
                accuracy: 0.001
            )
            XCTAssertEqual(
                tenKeyDesign.horizontalSpacing * 9,
                twentyKeyDesign.horizontalSpacing * 19,
                accuracy: 0.001
            )
            XCTAssertEqual(tenKeyDesign.keysWidth, twentyKeyDesign.keysWidth, accuracy: 0.001)
        }
    }

    func test_horizontalSizingPreservesExistingFormulaBelowTenKeys() {
        let verticalDesign = design(horizontalKeyCount: 5, orientation: .vertical)
        let horizontalDesign = design(horizontalKeyCount: 5, orientation: .horizontal)
        let keyCount: CGFloat = 5
        let verticalKeyWidth = interfaceSize.width / keyCount * (5 / (5.1 + keyCount / 10))
        let verticalSpacing = (interfaceSize.width - verticalKeyWidth * keyCount) / (keyCount - 1)
            * ((5 + keyCount) / (7.5 + keyCount))
        let horizontalKeyWidth = interfaceSize.width / keyCount * (10 / (10.2 + keyCount * 0.28))
        let horizontalSpacing = (interfaceSize.width - horizontalKeyWidth * keyCount) / (keyCount - 1)
            * ((8 + keyCount) / (10 + keyCount * 1.3))

        XCTAssertEqual(verticalDesign.keyViewWidth, verticalKeyWidth, accuracy: 0.001)
        XCTAssertEqual(verticalDesign.horizontalSpacing, verticalSpacing, accuracy: 0.001)
        XCTAssertEqual(horizontalDesign.keyViewWidth, horizontalKeyWidth, accuracy: 0.001)
        XCTAssertEqual(horizontalDesign.horizontalSpacing, horizontalSpacing, accuracy: 0.001)
    }

    @MainActor func test_verticalSizingKeepsFourKeyRatiosForLargerLayouts() {
        for orientation in [KeyboardOrientation.vertical, .horizontal] {
            let fourKeyDesign = design(verticalKeyCount: 4, orientation: orientation)
            let eightKeyDesign = design(verticalKeyCount: 8, orientation: orientation)

            XCTAssertEqual(
                fourKeyDesign.keyViewHeight * 4,
                eightKeyDesign.keyViewHeight * 8,
                accuracy: 0.001
            )
            XCTAssertEqual(
                fourKeyDesign.verticalSpacing * 3,
                eightKeyDesign.verticalSpacing * 7,
                accuracy: 0.001
            )
        }
    }

    func test_verticalSpacingPreservesExistingFormulaUpToFourKeys() {
        let verticalDesign = design(verticalKeyCount: 3, orientation: .vertical)
        let horizontalDesign = design(verticalKeyCount: 3, orientation: .horizontal)

        XCTAssertEqual(verticalDesign.verticalSpacing, interfaceSize.width / 50, accuracy: 0.001)
        XCTAssertEqual(horizontalDesign.verticalSpacing, interfaceSize.width / 107, accuracy: 0.001)
    }
}
