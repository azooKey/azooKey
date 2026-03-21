import KeyboardViews
import XCTest

@MainActor
final class MoteRuntimeStateTests: XCTestCase {
    func testKeyboardTabCancelsAskUserAndClearsTemporaryState() async {
        let state = MoteRuntimeState()

        state.startAskUserFlow()
        await waitUntil("ask-user should be shown") {
            state.screen == .askUser
        }

        state.selectAskUserOption("state_concrete")
        XCTAssertEqual(state.currentQuestionIndex, 1)
        XCTAssertEqual(state.askUserAnswers[0], "state_concrete")

        let result = state.handleBottomTabTap(.keyboard)

        XCTAssertEqual(result, .closeUpside)
        XCTAssertEqual(state.screen, .keyboard)
        XCTAssertEqual(state.askUserQuestions, [])
        XCTAssertEqual(state.askUserAnswers, [:])
        XCTAssertEqual(state.currentQuestionIndex, 0)
        XCTAssertFalse(state.isProcessing)
        XCTAssertNil(state.flowTask)
    }

    func testChipTapHistoryKeepsTapOrder() async {
        let state = MoteRuntimeState()

        state.startAskUserFlow()
        await waitUntil("ask-user should be shown") {
            state.screen == .askUser
        }

        state.selectAskUserOption("state_concrete")
        state.selectAskUserOption("act_today")
        state.selectAskUserOption("thanks_first")

        await waitUntil("stage should be shown after reply generation") {
            state.screen == .stage && !state.generatedChips.isEmpty
        }

        let chips = state.generatedChips
        XCTAssertGreaterThanOrEqual(chips.count, 2)

        state.recordChipTap(chips[1])
        state.recordChipTap(chips[0])

        XCTAssertEqual(state.tappedChipHistory, [chips[1], chips[0]])
    }

    func testFullTextIsSelectionSurfaceAndReturnsToStage() async {
        let state = MoteRuntimeState()

        state.startAskUserFlow()
        await waitUntil("ask-user should be shown") {
            state.screen == .askUser
        }

        state.selectAskUserOption("state_concrete")
        state.selectAskUserOption("act_today")
        state.selectAskUserOption("thanks_first")

        await waitUntil("stage should be shown") {
            state.screen == .stage && state.canOpenFullText
        }

        let openResult = state.handleBottomTabTap(.fullText)
        XCTAssertEqual(openResult, .keepUpside)
        XCTAssertEqual(state.screen, .fullText)

        state.returnToStageFromFullTextSelection()
        XCTAssertEqual(state.screen, .stage)
    }

    private func waitUntil(
        _ message: String,
        timeoutNanoseconds: UInt64 = 2_000_000_000,
        pollNanoseconds: UInt64 = 20_000_000,
        condition: @escaping () -> Bool
    ) async {
        let deadline = DispatchTime.now().uptimeNanoseconds + timeoutNanoseconds
        while DispatchTime.now().uptimeNanoseconds < deadline {
            if condition() {
                return
            }
            try? await Task.sleep(nanoseconds: pollNanoseconds)
        }
        XCTFail(message)
    }
}
