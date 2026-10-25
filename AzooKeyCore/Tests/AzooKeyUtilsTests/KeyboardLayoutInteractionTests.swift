import AzooKeyUtils
@testable import KeyboardViews
import SwiftUI
import UIKit
import XCTest

@MainActor
final class KeyboardLayoutInteractionTests: XCTestCase {
    private struct CandidateMock: ResultViewItemData {
        let inputable = true
        let text: String
        var label: ResultViewItemLabelStyle { .text(text) }
        #if DEBUG
        func getDebugInformation() -> String { text }
        #endif
    }

    private func makeStates() -> VariableStates {
        VariableStates(
            interfaceWidth: 760,
            orientation: .vertical,
            clipboardHistoryManagerConfig: ClipboardHistoryManagerConfig(),
            tabManagerConfig: TabManagerConfig(),
            userDefaults: UserDefaults(suiteName: "KeyboardLayoutInteractionTests.\(UUID().uuidString)")!,
            layoutIdiom: .phone
        )
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
