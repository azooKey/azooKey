import AzooKeyUtils
@testable import KeyboardViews
import SwiftUI
import UIKit
import XCTest

@MainActor
final class DuoFlickInteractionTests: XCTestCase {
    private struct CandidateMock: ResultViewItemData {
        let inputable = true
        let text: String
        var label: ResultViewItemLabelStyle { .text(text) }
        #if DEBUG
        func getDebugInformation() -> String { text }
        #endif
    }

    private final class Touch: UITouch {
        var point: CGPoint = .zero
        override func location(in view: UIView?) -> CGPoint { point }
    }

    private final class RecordingActions: UserActionManager, @unchecked Sendable {
        @MainActor var inputs: [String] = []
        @MainActor var states: [ObjectIdentifier] = []

        @MainActor override func registerActions(_ actions: [ActionType], variableStates: VariableStates) {
            for action in actions {
                if case let .input(text, _) = action {
                    inputs.append(text)
                    states.append(ObjectIdentifier(variableStates))
                }
            }
        }
    }

    private func makeStates() -> VariableStates {
        VariableStates(
            interfaceWidth: 760,
            orientation: .vertical,
            clipboardHistoryManagerConfig: ClipboardHistoryManagerConfig(),
            tabManagerConfig: TabManagerConfig(),
            userDefaults: UserDefaults(suiteName: "DuoFlickInteractionTests.\(UUID().uuidString)")!,
            layoutIdiom: .phone,
            duoFlickEnabled: true
        )
    }

    func test_foldingAndUnfoldingWithSameOrientationRecalculatesHeight() {
        let states = makeStates()
        for width: CGFloat in [390, 760, 390, 1_024, 390] {
            states.setContainerWidth(width, orientation: .vertical)
            let expectedHeight = width >= 600 ? DuoFlickLayout.keyboardHeight : 51 / 74 * width + 12
            XCTAssertEqual(states.interfaceSize.height, expectedHeight, accuracy: 0.001)
            XCTAssertEqual(states.interfaceSize.width, width)
        }
    }

    func test_qwertyAndCustomTabsKeepTheirOriginalHeightWhenDuoIsEnabled() {
        let states = makeStates()
        for tab in [KeyboardTab.ExistentialTab.qwerty_abc, .qwerty_hira, .custard(.flickJapanese)] {
            states.setTabForPreview(tab)
            states.setContainerWidth(760, orientation: .vertical)
            XCTAssertFalse(states.layoutContext.duoFlickEnabled)
            XCTAssertEqual(states.interfaceSize.height, 51 / 74 * 760 + 12, accuracy: 0.001)
        }
        states.setTabForPreview(.flick_hira)
        XCTAssertTrue(states.layoutContext.duoFlickEnabled)
        XCTAssertEqual(states.interfaceSize.height, 270, accuracy: 0.001)
    }

    func test_resizePreservesSelectedTabAndCandidates() {
        let states = makeStates()
        states.setTabForPreview(.flick_abc)
        states.resultModel.setResults([CandidateMock(text: "日本語"), CandidateMock(text: "にほんご")])
        let originalTab = states.tabManager.existentialTab()
        let candidates = states.resultModel.results.map(\.candidate.textualRepresentation)
        for (width, orientation) in [(CGFloat(390), KeyboardOrientation.vertical), (1_024, .vertical), (760, .horizontal), (390, .horizontal)] {
            states.setContainerWidth(width, orientation: orientation)
            XCTAssertEqual(states.tabManager.existentialTab(), originalTab)
            XCTAssertEqual(states.resultModel.results.map(\.candidate.textualRepresentation), candidates)
            XCTAssertEqual(states.resultModel.results.count, 2)
        }
    }

    func test_bothThumbsCanFlickIndependentlyIntoOneInputStream() async throws {
        guard #available(iOS 27.0, *) else { throw XCTSkip("UIKit touch surfaces require iOS 27") }
        let states = makeStates()
        states.setTabForPreview(.flick_hira)
        let actions = RecordingActions()
        let previousEnabled = EnableDuoFlick.value
        let previousWidth = DuoFlickPanelWidth.value
        let previousGap = DuoFlickCenterGap.value
        EnableDuoFlick.value = true
        DuoFlickPanelWidth.value = 0
        DuoFlickCenterGap.value = 16
        defer {
            EnableDuoFlick.value = previousEnabled
            DuoFlickPanelWidth.value = previousWidth
            DuoFlickCenterGap.value = previousGap
        }
        states.resultModel.setResults([
            CandidateMock(text: "日本語"), CandidateMock(text: "にほんご"), CandidateMock(text: "ニホンゴ"),
        ])
        let content = KeyboardView<AzooKeyKeyboardViewExtension>(defaultTab: .flick_hira)
            .environmentObject(states)
            .themeEnvironment(AzooKeyTheme.base)
            .environment(\.userActionManager, actions)
            .environment(\.showMessage, false)
        let controller = UIHostingController(rootView: content)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 760, height: DuoFlickLayout.keyboardHeight + Design.keyboardScreenBottomPadding))
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
        let keys = surfaces(in: controller.view)
        XCTAssertEqual(keys.count, 38, "Both complete flick panels must have their own touch surfaces")
        func frame(_ key: ImmediateKeyGesture.TouchSurface) -> CGRect { key.convert(key.bounds, to: window) }
        let firstRowY = try XCTUnwrap(keys.map { frame($0).midY }.min())
        let firstRow = keys.filter { abs(frame($0).midY - firstRowY) < 1 }.sorted { frame($0).midX < frame($1).midX }
        XCTAssertEqual(firstRow.count, 10)
        let leftA = try XCTUnwrap(firstRow.dropFirst().first)
        let rightKa = try XCTUnwrap(firstRow.dropFirst(7).first)
        let keyBoundary = frame(leftA).minY
        XCTAssertFalse(window.hitTest(CGPoint(x: frame(leftA).midX, y: keyBoundary - 1), with: nil) is ImmediateKeyGesture.TouchSurface)
        XCTAssertTrue(window.hitTest(CGPoint(x: frame(leftA).midX, y: keyBoundary + 1), with: nil) === leftA)
        XCTAssertGreaterThanOrEqual(frame(leftA).width, 70)
        XCTAssertGreaterThanOrEqual(frame(leftA).height, 44)
        // UIKit rounds the two sides independently to physical pixels.
        XCTAssertEqual(frame(leftA).width, frame(rightKa).width, accuracy: 1 / window.screen.scale)
        let leftTouch = Touch()
        let rightTouch = Touch()
        leftTouch.point = CGPoint(x: frame(leftA).midX, y: frame(leftA).midY)
        rightTouch.point = CGPoint(x: frame(rightKa).midX, y: frame(rightKa).midY)
        leftA.recognizer.touchesBegan([leftTouch], with: UIEvent())
        rightKa.recognizer.touchesBegan([rightTouch], with: UIEvent())
        leftTouch.point.x -= 35
        rightTouch.point.y -= 35
        leftA.recognizer.touchesMoved([leftTouch], with: UIEvent())
        rightKa.recognizer.touchesMoved([rightTouch], with: UIEvent())
        rightKa.recognizer.touchesEnded([rightTouch], with: UIEvent())
        leftA.recognizer.touchesEnded([leftTouch], with: UIEvent())
        XCTAssertEqual(actions.inputs, ["く", "い"])
        XCTAssertEqual(actions.states, [ObjectIdentifier(states), ObjectIdentifier(states)])

        // Resize while a third finger is down: a moving key must cancel,
        // rather than commit a different character after the fold transition.
        let interruptedTouch = Touch()
        interruptedTouch.point = leftTouch.point
        leftA.recognizer.touchesBegan([interruptedTouch], with: UIEvent())
        states.setContainerWidth(1_024, orientation: .vertical)
        await Task.yield()
        controller.view.layoutIfNeeded()
        await Task.yield()
        controller.view.layoutIfNeeded()
        leftA.recognizer.touchesEnded([interruptedTouch], with: UIEvent())
        XCTAssertEqual(actions.inputs, ["く", "い"])
    }

    func test_shortCandidatesFillTheBarAndLeaveNoDeadGapsBetweenButtons() async throws {
        var frames: [Int: CGRect] = [:]
        let content = HStack(spacing: 0) {
            ForEach(0..<3) { index in
                Button("日") {}
                    .buttonStyle(ResultButtonStyle<AzooKeyKeyboardViewExtension>(height: 26.4, hitHeight: 56))
                    .onGeometryChange(for: CGRect.self) { proxy in
                        proxy.frame(in: .global)
                    } action: { frame in
                        frames[index] = frame
                    }
            }
        }
        .frame(width: 240, height: 56, alignment: .leading)
        .themeEnvironment(AzooKeyTheme.base)
        let controller = UIHostingController(rootView: content)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 240, height: 56))
        window.rootViewController = controller
        window.isHidden = false
        defer { window.isHidden = true }
        controller.view.frame = window.bounds
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        await Task.yield()
        controller.view.layoutIfNeeded()

        for index in 0..<3 {
            let frame = try XCTUnwrap(frames[index])
            XCTAssertGreaterThanOrEqual(frame.width, 44)
            XCTAssertEqual(frame.height, 56, accuracy: 1 / window.screen.scale)
            if index > 0 {
                XCTAssertEqual(frame.minX, try XCTUnwrap(frames[index - 1]).maxX, accuracy: 1 / window.screen.scale)
            }
        }
    }
}
