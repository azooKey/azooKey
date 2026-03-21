import KeyboardViews
import XCTest

@MainActor
final class MoteRuntimeStateTests: XCTestCase {
    func testKeyboardTabCancelsAskUserAndClearsTemporaryState() async {
        let state = MoteRuntimeState(apiClient: MockMoteRuntimeAPIClient())

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
        let state = MoteRuntimeState(apiClient: MockMoteRuntimeAPIClient())

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
        let state = MoteRuntimeState(apiClient: MockMoteRuntimeAPIClient())

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

    func testAskUserAPIFailureShowsFallbackScreen() async {
        let state = MoteRuntimeState(
            apiClient: MockMoteRuntimeAPIClient(
                askUserResult: .failure(MockMoteRuntimeAPIClient.TestError.network),
                replyResult: .success(Self.testChips)
            )
        )

        state.startAskUserFlow()

        await waitUntil("fallback should be shown") {
            state.screen == .fallback
        }
        XCTAssertFalse(state.isProcessing)
        XCTAssertNotNil(state.fallbackMessage)
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

    private static let testQuestions: [MoteAskUserQuestion] = [
        .init(
            index: 0,
            text: "まず伝えるべき事実はどれですか？",
            options: [
                .init(label: "今の状況を具体的に伝える", value: "state_concrete"),
                .init(label: "時間の見通しを伝える", value: "time_estimate"),
                .init(label: "未確定であることを伝える", value: "state_uncertain")
            ]
        ),
        .init(
            index: 1,
            text: "次の行動として近いものは？",
            options: [
                .init(label: "今日中に対応する", value: "act_today"),
                .init(label: "明日対応する", value: "act_tomorrow"),
                .init(label: "代替案を提案する", value: "propose_alternative")
            ]
        ),
        .init(
            index: 2,
            text: "相手への配慮として含める要素は？",
            options: [
                .init(label: "謝意を先に伝える", value: "thanks_first"),
                .init(label: "負担軽減の提案をする", value: "reduce_burden"),
                .init(label: "確認質問を添える", value: "ask_confirmation")
            ]
        )
    ]

    private static let testChips: [String] = [
        "ありがとう、まず状況を共有するね。",
        "今日中に対応する形で進めるよ。",
        "最後に謝意を添えるね。"
    ]

    private struct MockMoteRuntimeAPIClient: MoteRuntimeAPIProviding {
        enum TestError: Error {
            case network
        }

        let askUserResult: Result<[MoteAskUserQuestion], Error>
        let replyResult: Result<[String], Error>

        init(
            askUserResult: Result<[MoteAskUserQuestion], Error> = .success(MoteRuntimeStateTests.testQuestions),
            replyResult: Result<[String], Error> = .success(MoteRuntimeStateTests.testChips)
        ) {
            self.askUserResult = askUserResult
            self.replyResult = replyResult
        }

        func fetchAskUserQuestions(chatContext: MoteChatContextInput) async throws -> [MoteAskUserQuestion] {
            try askUserResult.get()
        }

        func generateReplyChips(chatContext: MoteChatContextInput, answers: [Int: String]) async throws -> [String] {
            try replyResult.get()
        }
    }
}
