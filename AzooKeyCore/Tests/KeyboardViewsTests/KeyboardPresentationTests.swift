@testable import KeyboardViews
import UIKit
import XCTest

final class KeyboardPresentationTests: XCTestCase {
    func test_scenePortraitWinsEvenWhenAnInputWindowIsWiderThanItIsTall() {
        let presentation = KeyboardPresentation(sceneSize: CGSize(width: 466, height: 270), interfaceOrientation: .portrait)
        XCTAssertEqual(presentation.orientation, .vertical)
    }

    func test_closedPortraitAndLandscapeBothUseOnePanel() {
        let portrait = KeyboardPresentation(sceneSize: CGSize(width: 466, height: 678), interfaceOrientation: .portrait)
        XCTAssertEqual(portrait.orientation, .vertical)
        XCTAssertFalse(portrait.allowsDuoFlickPanels)
        let landscape = KeyboardPresentation(sceneSize: CGSize(width: 678, height: 466), interfaceOrientation: .landscapeLeft)
        XCTAssertEqual(landscape.orientation, .horizontal)
        XCTAssertFalse(landscape.allowsDuoFlickPanels)
    }

    func test_unfoldedSceneAllowsBothPanelsInEitherOrientation() {
        let portrait = KeyboardPresentation(sceneSize: CGSize(width: 669, height: 952), interfaceOrientation: .portrait)
        let landscape = KeyboardPresentation(sceneSize: CGSize(width: 952, height: 669), interfaceOrientation: .landscapeRight)
        XCTAssertTrue(portrait.allowsDuoFlickPanels)
        XCTAssertTrue(landscape.allowsDuoFlickPanels)
    }

    func test_unknownSceneOrientationUsesSceneDimensionsOrTheLastKnownOrientation() {
        XCTAssertEqual(KeyboardPresentation(sceneSize: CGSize(width: 466, height: 678), interfaceOrientation: .unknown).orientation, .vertical)
        let unattached = KeyboardPresentation(sceneSize: .zero, interfaceOrientation: .unknown, fallbackOrientation: .horizontal)
        XCTAssertEqual(unattached.orientation, .horizontal)
        XCTAssertTrue(unattached.allowsDuoFlickPanels)
    }

    func test_compactHostWindowDoesNotEnableSplitFromWidthAlone() {
        let presentation = KeyboardPresentation(sceneSize: CGSize(width: 952, height: 400), interfaceOrientation: .landscapeRight)
        XCTAssertFalse(presentation.allowsDuoFlickPanels)
    }
}
