@testable import KeyboardViews
import SwiftUI
import UIKit
import XCTest

@MainActor
final class KeyPressGestureTests: XCTestCase {
    private final class Touch: UITouch {
        var point = CGPoint(x: 10, y: 20)
        override func location(in view: UIView?) -> CGPoint { point }
    }

    func testKeySurfaceOwnsUpperEdgeAndSpacingWithoutCoveringCandidateBar() async throws {
        guard #available(iOS 27.0, *) else { throw XCTSkip("Immediate key surface requires iOS 27") }
        let handlers = KeyPressHandlers(onChanged: { _ in }, onEnded: {})
        let content = VStack(spacing: 0) {
            ScrollView(.horizontal) {
                Button("候補") {}.contextMenu { Button("操作") {} }
            }
            .frame(height: 40)
            .contentShape(Rectangle())
            .padding(.vertical, 6)
            HStack(spacing: 0) {
                ForEach(0..<5) { _ in
                    Color.white
                        .frame(width: 57.142857, height: 40.335135)
                        .modifier(KeyPressGestureModifier(
                            hitSize: CGSize(width: 64, height: 46.735135),
                            flick: handlers, linear: handlers, onCancelled: {}
                        ))
                        .frame(width: 64, height: 46.735135)
                        .contentShape(Rectangle())
                }
            }
            .zIndex(1)
        }
        .frame(width: 320)
        let controller = UIHostingController(rootView: content)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 240))
        window.rootViewController = controller
        window.isHidden = false
        defer { window.isHidden = true }
        controller.view.frame = window.bounds
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        await Task.yield()
        controller.view.layoutIfNeeded()

        func surfaces(in view: UIView) -> [ImmediateKeyGesture.TouchSurface] {
            view.subviews.flatMap { child in
                (child as? ImmediateKeyGesture.TouchSurface).map { [$0] } ?? surfaces(in: child)
            }
        }
        let keys = surfaces(in: controller.view).sorted { $0.convert(.zero, to: window).x < $1.convert(.zero, to: window).x }
        XCTAssertEqual(keys.count, 5)
        let key = try XCTUnwrap(keys.dropFirst().first)
        let frame = key.convert(key.bounds, to: window)
        XCTAssertEqual(frame.width, 64, accuracy: 0.1)
        XCTAssertEqual(frame.height, 46.735135, accuracy: 0.1)
        // Include the upper part lost near the candidate strip, and the spacing
        // outside the painted key. Each point must resolve to this UIKit view.
        for point in [
            CGPoint(x: frame.midX, y: frame.minY + 1),
            CGPoint(x: frame.midX, y: frame.minY + 15),
            CGPoint(x: frame.minX + 1, y: frame.midY),
        ] {
            XCTAssertTrue(window.hitTest(point, with: nil) === key, "\(point)")
        }
        XCTAssertFalse(window.hitTest(CGPoint(x: frame.midX, y: frame.minY - 20), with: nil) is ImmediateKeyGesture.TouchSurface)
        XCTAssertTrue(window.hitTest(CGPoint(x: frame.maxX + 1, y: frame.midY), with: nil) === keys[2])
    }

    func testRemovingSurfaceCancelsPendingPressWithoutCommitting() throws {
        guard #available(iOS 18.0, *) else { throw XCTSkip("UIKit surface requires iOS 18") }
        let surface = ImmediateKeyGesture.TouchSurface()
        var cancellations = 0
        var endings = 0
        surface.recognizer.onCancelled = { cancellations += 1 }
        surface.recognizer.onEnded = { endings += 1 }
        surface.recognizer.touchesBegan([Touch()], with: UIEvent())
        ImmediateKeyGesture.dismantleUIView(surface, coordinator: ())
        ImmediateKeyGesture.dismantleUIView(surface, coordinator: ())
        XCTAssertEqual(cancellations, 1)
        XCTAssertEqual(endings, 0)
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
