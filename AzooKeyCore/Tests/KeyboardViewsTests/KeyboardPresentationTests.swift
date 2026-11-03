@testable import KeyboardViews
import UIKit
import XCTest

final class KeyboardPresentationTests: XCTestCase {
    func test_scenePortraitWinsEvenWhenAnInputWindowIsWiderThanItIsTall() {
        let presentation = KeyboardPresentation(sceneSize: CGSize(width: 466, height: 270), interfaceOrientation: .portrait)
        XCTAssertEqual(presentation.orientation, .vertical)
    }

    func test_unknownSceneOrientationUsesSceneDimensionsOrTheLastKnownOrientation() {
        XCTAssertEqual(KeyboardPresentation(sceneSize: CGSize(width: 466, height: 678), interfaceOrientation: .unknown).orientation, .vertical)
        let unattached = KeyboardPresentation(sceneSize: .zero, interfaceOrientation: .unknown, fallbackOrientation: .horizontal)
        XCTAssertEqual(unattached.orientation, .horizontal)
    }

}
