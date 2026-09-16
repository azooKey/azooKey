@testable import KeyboardViews
import UIKit
import XCTest

@MainActor
final class KeyPressGestureTests: XCTestCase {
    private final class Touch: UITouch {
        var point = CGPoint(x: 10, y: 20)
        override func location(in view: UIView?) -> CGPoint { point }
    }

    func testTouchDownStartsImmediatelyAndMovesKeepOrigin() throws {
        guard #available(iOS 18.0, *) else { throw XCTSkip("UIKit gesture bridge requires iOS 18") }
        let recognizer = ImmediateKeyGesture.Recognizer()
        let touch = Touch()
        let event = UIEvent()
        var changes: [KeyPressValue] = []
        recognizer.onChanged = { changes.append($0) }
        recognizer.touchesBegan([touch], with: event)
        XCTAssertEqual(changes.count, 1)
        XCTAssertEqual(changes.first?.location, CGPoint(x: 10, y: 20))
        touch.point = CGPoint(x: 30, y: 40)
        recognizer.touchesMoved([touch], with: event)
        XCTAssertEqual(changes.last?.startLocation, CGPoint(x: 10, y: 20))
        XCTAssertEqual(changes.last?.location, CGPoint(x: 30, y: 40))
    }

    func testCancellationDoesNotCommitAndOnlyNotifiesOnce() throws {
        guard #available(iOS 18.0, *) else { throw XCTSkip("UIKit gesture bridge requires iOS 18") }
        let recognizer = ImmediateKeyGesture.Recognizer()
        let touch = Touch()
        let event = UIEvent()
        var endings = 0
        var cancellations = 0
        recognizer.onEnded = { endings += 1 }
        recognizer.onCancelled = { cancellations += 1 }
        recognizer.touchesBegan([touch], with: event)
        recognizer.touchesCancelled([touch], with: event)
        recognizer.reset()
        recognizer.touchesEnded([touch], with: event)
        XCTAssertEqual(endings, 0)
        XCTAssertEqual(cancellations, 1)
    }

    func testResetCancelsActivePressButNotCompletedPress() throws {
        guard #available(iOS 18.0, *) else { throw XCTSkip("UIKit gesture bridge requires iOS 18") }
        let recognizer = ImmediateKeyGesture.Recognizer()
        let touch = Touch()
        let event = UIEvent()
        var endings = 0
        var cancellations = 0
        recognizer.onEnded = { endings += 1 }
        recognizer.onCancelled = { cancellations += 1 }
        recognizer.touchesBegan([touch], with: event)
        recognizer.touchesEnded([touch], with: event)
        recognizer.reset()
        XCTAssertEqual(endings, 1)
        XCTAssertEqual(cancellations, 0)
        let activeRecognizer = ImmediateKeyGesture.Recognizer()
        activeRecognizer.onCancelled = { cancellations += 1 }
        activeRecognizer.touchesBegan([touch], with: event)
        activeRecognizer.reset()
        XCTAssertEqual(cancellations, 1)
    }

    func testAdditionalTouchDoesNotRestartOrCancelTheTrackedPress() throws {
        guard #available(iOS 18.0, *) else { throw XCTSkip("UIKit gesture bridge requires iOS 18") }
        let recognizer = ImmediateKeyGesture.Recognizer()
        let first = Touch(), second = Touch()
        let event = UIEvent()
        var changes = 0
        var endings = 0
        var cancellations = 0
        recognizer.onChanged = { _ in changes += 1 }
        recognizer.onEnded = { endings += 1 }
        recognizer.onCancelled = { cancellations += 1 }
        recognizer.touchesBegan([first], with: event)
        recognizer.touchesBegan([second], with: event)
        recognizer.touchesEnded([second], with: event)
        recognizer.touchesCancelled([second], with: event)
        XCTAssertEqual(changes, 1)
        XCTAssertEqual(endings, 0)
        XCTAssertEqual(cancellations, 0)
        recognizer.touchesEnded([first], with: event)
        XCTAssertEqual(endings, 1)
    }
}
