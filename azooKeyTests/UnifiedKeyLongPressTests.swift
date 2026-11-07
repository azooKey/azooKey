import AzooKeyUtils
import CustardKit
@testable import KeyboardViews
import SwiftUI
import UIKit
import XCTest

@MainActor
final class UnifiedKeyLongPressTests: XCTestCase {
    private struct Configuration: ClipboardHistoryManagerConfiguration, TabManagerConfiguration, CustardManagerProtocol {
        enum MissingData: Error { case unavailable }
        var enabled: Bool { false }
        var saveDirectory: URL? { nil }
        var maxCount: Int { 0 }
        var japaneseLayout: LanguageLayout { .flick }
        var englishLayout: LanguageLayout { .qwerty }
        var custardManager: any CustardManagerProtocol { self }
        func custard(identifier: String) throws -> Custard { throw MissingData.unavailable }
        func tabbar(identifier: Int) throws -> TabBarData { throw MissingData.unavailable }
    }

    @MainActor private final class RecordingActions: UserActionManager, @unchecked Sendable {
        struct Reservation {
            let action: LongpressActionType
            let delay: Double
            let onStart: @MainActor () -> Bool
        }
        var reservations: [Reservation] = []
        var inputs: [ActionType] = []

        override func registerActions(_ actions: [ActionType], variableStates: VariableStates) {
            inputs += actions
        }

        override func reserveLongPressAction(_ action: LongpressActionType, taskStartDuration: Double, variableStates: VariableStates, onStart: @escaping @MainActor () -> Bool) {
            reservations.append(.init(action: action, delay: taskStartDuration, onStart: onStart))
        }

        override func registerLongPressActionEnd(_ action: LongpressActionType) {
            reservations.removeAll { $0.action == action }
        }

        // Fire the first input before touch-up, without waiting for another View task.
        func fire(_ reservation: Reservation) {
            guard reservation.onStart() else {
                return
            }
            inputs += reservation.action.start + reservation.action.repeat
        }
    }

    private final class Touch: UITouch {
        var point = CGPoint(x: 100, y: 100)
        override func location(in view: UIView?) -> CGPoint { point }
    }

    @available(iOS 27.0, *)
    @MainActor
    private struct Fixture {
        let window: UIWindow
        let surface: ImmediateKeyGesture.TouchSurface
        let actions: RecordingActions
        let touch = Touch()

        func down() { surface.recognizer.touchesBegan([touch], with: UIEvent()) }
        func move(to point: CGPoint) {
            touch.point = point
            surface.recognizer.touchesMoved([touch], with: UIEvent())
        }
        func up() { surface.recognizer.touchesEnded([touch], with: UIEvent()) }
        func cancel() { surface.recognizer.touchesCancelled([touch], with: UIEvent()) }
        func close() { window.rootViewController = nil; window.isHidden = true }
    }

    @available(iOS 27.0, *)
    private func fixture(flick: Bool, emptyVariation: Bool = false, repeatOnly: Bool = false) async throws -> Fixture {
        let actions = RecordingActions()
        let states = VariableStates(
            interfaceWidth: 320, orientation: .vertical,
            clipboardHistoryManagerConfig: Configuration(),
            tabManagerConfig: Configuration(), userDefaults: UserDefaults(suiteName: UUID().uuidString)!
        )
        let model = UnifiedGeneralKeyModel<AzooKeyKeyboardViewExtension>(
            labelType: .text("か"), pressActions: [.input("か")],
            longPressActions: .init(duration: .light, start: repeatOnly ? [] : [.input("が")], repeat: repeatOnly ? [.delete(1)] : []),
            flick: flick ? [
                .top: .init(label: .text("き"), pressActions: [.input("き")], longPressActions: emptyVariation ? .none : .init(start: [.input("ぎ")])),
                .left: .init(label: .text("く"), pressActions: [.input("く")], longPressActions: .init(start: [.input("ぐ")])),
            ] : [:],
            linearVariations: [], showsTapBubble: false, colorRole: .normal
        )
        let design = TabDependentDesign(width: 5, height: 4, interfaceSize: .init(width: 320, height: 200), layoutContext: .init(containerWidth: 320, orientation: .vertical, idiom: .phone))
        let key = UnifiedGenericKeyView<AzooKeyKeyboardViewExtension>(model: model, tabDesign: design, size: .init(width: 60, height: 40), isSuggesting: .constant(false))
            .environmentObject(states)
            .environment(\.userActionManager, actions)
        let controller = UIHostingController(rootView: key)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 200))
        window.rootViewController = controller
        window.isHidden = false
        controller.view.frame = window.bounds
        controller.view.layoutIfNeeded()
        await Task.yield()
        controller.view.layoutIfNeeded()
        func surfaces(in view: UIView) -> [ImmediateKeyGesture.TouchSurface] {
            view.subviews.flatMap { child in
                (child as? ImmediateKeyGesture.TouchSurface).map { [$0] } ?? surfaces(in: child)
            }
        }
        let surface = try XCTUnwrap(surfaces(in: controller.view).first)
        return Fixture(window: window, surface: surface, actions: actions)
    }

    func testCenterLongPressCannotAlsoCommitTapForFlickOrQwerty() async throws {
        guard #available(iOS 27.0, *) else { throw XCTSkip("UIKit key surface requires iOS 27") }
        for flick in [true, false] {
            let key = try await fixture(flick: flick)
            defer { key.close() }
            key.down()
            let reservation = try XCTUnwrap(key.actions.reservations.first)
            XCTAssertEqual(reservation.delay, 0.125)
            key.actions.fire(reservation)
            key.up()
            XCTAssertEqual(key.actions.inputs, [.input("が")])
            XCTAssertTrue(key.actions.reservations.isEmpty)
        }
    }

    func testTapBeforeLongPressCompletionIsNotLost() async throws {
        guard #available(iOS 27.0, *) else { throw XCTSkip("UIKit key surface requires iOS 27") }
        for flick in [true, false] {
            let key = try await fixture(flick: flick)
            defer { key.close() }
            key.down()
            let reservation = try XCTUnwrap(key.actions.reservations.first)
            key.up()
            // Even an already-queued completion must reject the ended press.
            key.actions.fire(reservation)
            XCTAssertEqual(key.actions.inputs, [.input("か")])
        }
    }

    func testFlickLongPressCannotAlsoCommitVariationTap() async throws {
        guard #available(iOS 27.0, *) else { throw XCTSkip("UIKit key surface requires iOS 27") }
        let key = try await fixture(flick: true)
        defer { key.close() }
        key.down()
        key.move(to: .init(x: 100, y: 0))
        let reservation = try XCTUnwrap(key.actions.reservations.first)
        XCTAssertEqual(reservation.delay, 0.400)
        key.actions.fire(reservation)
        key.up()
        XCTAssertEqual(key.actions.inputs, [.input("ぎ")])
    }

    func testChangingFlickDirectionRejectsOldCompletion() async throws {
        guard #available(iOS 27.0, *) else { throw XCTSkip("UIKit key surface requires iOS 27") }
        let key = try await fixture(flick: true)
        defer { key.close() }
        key.down()
        let center = try XCTUnwrap(key.actions.reservations.first)
        key.move(to: .init(x: 100, y: 0))
        let top = try XCTUnwrap(key.actions.reservations.first)
        key.move(to: .init(x: 0, y: 100))
        key.actions.fire(center)
        key.actions.fire(top)
        XCTAssertTrue(key.actions.inputs.isEmpty)
        key.up()
        XCTAssertEqual(key.actions.inputs, [.input("く")])
    }

    func testEmptyFlickLongPressStillCommitsVariationTap() async throws {
        guard #available(iOS 27.0, *) else { throw XCTSkip("UIKit key surface requires iOS 27") }
        let key = try await fixture(flick: true, emptyVariation: true)
        defer { key.close() }
        key.down()
        key.move(to: .init(x: 100, y: 0))
        key.actions.fire(try XCTUnwrap(key.actions.reservations.first))
        key.up()
        XCTAssertEqual(key.actions.inputs, [.input("き")])
    }

    func testChangingDirectionAfterLongPressStartsNewVariation() async throws {
        guard #available(iOS 27.0, *) else { throw XCTSkip("UIKit key surface requires iOS 27") }
        let key = try await fixture(flick: true)
        defer { key.close() }
        key.down()
        key.move(to: .init(x: 100, y: 0))
        key.actions.fire(try XCTUnwrap(key.actions.reservations.first))
        key.move(to: .init(x: 0, y: 100))
        key.actions.fire(try XCTUnwrap(key.actions.reservations.first))
        key.up()
        XCTAssertEqual(key.actions.inputs, [.input("ぎ"), .input("ぐ")])
    }

    func testRepeatOnlyLongPressSuppressesTap() async throws {
        guard #available(iOS 27.0, *) else { throw XCTSkip("UIKit key surface requires iOS 27") }
        let key = try await fixture(flick: false, repeatOnly: true)
        defer { key.close() }
        key.down()
        key.actions.fire(try XCTUnwrap(key.actions.reservations.first))
        key.up()
        XCTAssertEqual(key.actions.inputs, [.delete(1)])
    }

    func testCancellationRejectsLongPressAndDoesNotCommitTap() async throws {
        guard #available(iOS 27.0, *) else { throw XCTSkip("UIKit key surface requires iOS 27") }
        let key = try await fixture(flick: true)
        defer { key.close() }
        key.down()
        let reservation = try XCTUnwrap(key.actions.reservations.first)
        key.cancel()
        key.actions.fire(reservation)
        XCTAssertTrue(key.actions.inputs.isEmpty)
        XCTAssertTrue(key.actions.reservations.isEmpty)
    }

    func testDismantlingSurfaceRejectsPendingLongPress() async throws {
        guard #available(iOS 27.0, *) else { throw XCTSkip("UIKit key surface requires iOS 27") }
        let key = try await fixture(flick: true)
        defer { key.close() }
        key.down()
        let reservation = try XCTUnwrap(key.actions.reservations.first)
        ImmediateKeyGesture.dismantleUIView(key.surface, coordinator: ())
        key.actions.fire(reservation)
        XCTAssertTrue(key.actions.inputs.isEmpty)
        XCTAssertTrue(key.actions.reservations.isEmpty)
    }
}
