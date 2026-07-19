import KeyboardViews
import XCTest

final class KeyboardLayoutTests: XCTestCase {
    func test_phoneVerticalHeightUsesContainerWidth() {
        let context = KeyboardLayoutContext(
            containerWidth: 390,
            orientation: .vertical,
            idiom: .phone
        )

        XCTAssertEqual(
            Design.keyboardHeight(context: context),
            51 / 74 * 390 + 12,
            accuracy: 0.001
        )
    }

    func test_padVerticalHeightUsesPadRatio() {
        let context = KeyboardLayoutContext(
            containerWidth: 768,
            orientation: .vertical,
            idiom: .pad
        )

        XCTAssertEqual(
            Design.keyboardHeight(context: context),
            15 / 31 * 768 + 12,
            accuracy: 0.001
        )
    }

    func test_narrowPadUsesPhoneVerticalRatio() {
        let context = KeyboardLayoutContext(
            containerWidth: 320,
            orientation: .horizontal,
            idiom: .pad
        )

        XCTAssertEqual(
            Design.keyboardHeight(context: context),
            51 / 74 * 320 + 12,
            accuracy: 0.001
        )
    }

    func test_upsideComponentHeightUsesSameContext() {
        let context = KeyboardLayoutContext(
            containerWidth: 600,
            orientation: .horizontal,
            idiom: .pad
        )
        let baseHeight = Design.keyboardHeight(context: context)
        let expandedHeight = Design.keyboardHeight(
            context: context,
            upsideComponent: .supplementaryCandidates
        )

        XCTAssertEqual(
            Design.upsideComponentHeight(.supplementaryCandidates, context: context),
            expandedHeight - baseHeight,
            accuracy: 0.001
        )
    }
}
