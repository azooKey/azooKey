import XCTest

@MainActor
final class DuoAdaptationUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    override func tearDown() async throws {
        XCUIDevice.shared.orientation = .portrait
    }

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(ja)", "-AppleLocale", "ja_JP"]
        app.launch()
        if app.buttons["手順を見る"].waitForExistence(timeout: 5) {
            app.buttons["手順を見る"].tap()
            for _ in 0..<6 where !app.buttons["閉じる"].isHittable { app.swipeUp() }
            app.buttons["閉じる"].tap()
        }
        return app
    }

    private func openFlickEditor(_ app: XCUIApplication) {
        app.descendants(matching: .any)["設定"].firstMatch.tap()
        let configure = app.buttons["flick-custom-key-settings"]
        for _ in 0..<8 where !configure.isHittable { app.swipeUp() }
        XCTAssertTrue(configure.isHittable)
        configure.tap()
        let leftKey = app.descendants(matching: .any)["flick-key-left"].firstMatch
        XCTAssertTrue(leftKey.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["flick-editor-direction"].exists)
        leftKey.tap()
        XCTAssertTrue(app.textFields["flick-editor-label"].waitForExistence(timeout: 5))
    }

    private func rotate(_ orientation: UIDeviceOrientation, app: XCUIApplication) {
        XCUIDevice.shared.orientation = orientation
        let landscape = orientation == .landscapeLeft || orientation == .landscapeRight
        let settled = NSPredicate { _, _ in
            let frame = app.windows.firstMatch.frame
            return (frame.width > frame.height) == landscape
        }
        let expectation = XCTNSPredicateExpectation(predicate: settled, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 5), .completed)
    }

    func test_settingsDestinationSurvivesRotation() {
        let app = launchApp()
        openFlickEditor(app)
        for orientation in [UIDeviceOrientation.landscapeLeft, .landscapeRight, .portrait] {
            rotate(orientation, app: app)
            let label = app.textFields["flick-editor-label"]
            scrollToLabel(label, app: app)
            XCTAssertGreaterThan(label.frame.width, 0)
            XCTAssertTrue(app.frame.contains(label.frame))
            let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            screenshot.name = "Duo-editor-\(orientation.rawValue)"
            screenshot.lifetime = .keepAlways
            add(screenshot)
        }
    }

    func test_flickEditorKeepsSelectionAndTextAcrossRotation() {
        let app = launchApp()
        openFlickEditor(app)
        let label = app.textFields["flick-editor-label"]
        scrollToLabel(label, app: app)
        let initialValue = fieldText(label)
        let editedValue = initialValue == "duo-layout-check" ? "duo-layout-check-2" : "duo-layout-check"
        replaceText(label, with: editedValue)
        XCTAssertEqual(fieldText(label), editedValue)
        label.typeText("\n")
        XCTAssertEqual(fieldText(label), editedValue)
        rotate(.landscapeLeft, app: app)
        scrollToLabel(label, app: app)
        XCTAssertEqual(fieldText(label), editedValue)
        rotate(.portrait, app: app)
        scrollToLabel(label, app: app)
        XCTAssertEqual(fieldText(label), editedValue)
        replaceText(label, with: initialValue)
        XCTAssertEqual(fieldText(label), initialValue)
    }

    private func scrollToLabel(_ label: XCUIElement, app: XCUIApplication) {
        let form = app.descendants(matching: .any)["flick-editor-form"].firstMatch
        for _ in 0..<8 where !(label.exists && label.isHittable) {
            let start = form.coordinate(withNormalizedOffset: CGVector(dx: 0.75, dy: 0.7))
            let end = form.coordinate(withNormalizedOffset: CGVector(dx: 0.75, dy: 0.45))
            start.press(forDuration: 0.1, thenDragTo: end)
        }
        XCTAssertTrue(label.waitForExistence(timeout: 5))
        XCTAssertTrue(label.isHittable)
    }

    private func fieldText(_ field: XCUIElement) -> String {
        let value = field.value as? String ?? ""
        return value == field.placeholderValue ? "" : value
    }

    private func replaceText(_ field: XCUIElement, with text: String) {
        field.tap()
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: fieldText(field).count + 1))
        if !text.isEmpty { field.typeText(text) }
    }
}
