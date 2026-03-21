import Combine
import Foundation

public struct MoteAskUserOption: Equatable, Sendable {
    public let label: String
    public let value: String

    public init(label: String, value: String) {
        self.label = label
        self.value = value
    }
}

public struct MoteAskUserQuestion: Equatable, Sendable {
    public let index: Int
    public let text: String
    public let options: [MoteAskUserOption]

    public init(index: Int, text: String, options: [MoteAskUserOption]) {
        self.index = index
        self.text = text
        self.options = options
    }
}

public enum MoteRuntimeScreen: Equatable, Sendable {
    case keyboard
    case askUser
    case loading
    case stage
    case fullText
}

public enum MoteBottomTab: Equatable, Sendable {
    case moteAI
    case keyboard
    case fullText
}

public enum MoteBottomTabResult: Equatable, Sendable {
    case keepUpside
    case closeUpside
}

@MainActor
public final class MoteRuntimeState: ObservableObject {
    @Published public private(set) var screen: MoteRuntimeScreen = .keyboard
    @Published public private(set) var isProcessing = false
    @Published public private(set) var askUserQuestions: [MoteAskUserQuestion] = []
    @Published public private(set) var askUserAnswers: [Int: String] = [:]
    @Published public private(set) var currentQuestionIndex = 0
    @Published public private(set) var generatedChips: [String] = []
    @Published public private(set) var tappedChipHistory: [String] = []

    public private(set) var flowTask: Task<Void, Never>?

    public init() {}

    deinit {
        flowTask?.cancel()
    }

    public var currentQuestion: MoteAskUserQuestion? {
        guard askUserQuestions.indices.contains(currentQuestionIndex) else {
            return nil
        }
        return askUserQuestions[currentQuestionIndex]
    }

    public var canOpenFullText: Bool {
        !generatedChips.isEmpty && screen != .askUser && screen != .loading
    }

    public var selectedBottomTab: MoteBottomTab? {
        switch screen {
        case .askUser:
            return .moteAI
        case .keyboard, .stage:
            return .keyboard
        case .fullText:
            return .fullText
        case .loading:
            return nil
        }
    }

    public func startAskUserFlow() {
        guard !isProcessing else { return }
        guard screen != .askUser else { return }

        flowTask?.cancel()
        flowTask = nil

        generatedChips = []
        tappedChipHistory = []
        askUserQuestions = []
        askUserAnswers = [:]
        currentQuestionIndex = 0

        isProcessing = true
        screen = .loading

        flowTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(nanoseconds: 200_000_000)
                try Task.checkCancellation()
            } catch {
                return
            }
            self?.showAskUserQuestions()
        }
    }

    public func selectAskUserOption(_ value: String) {
        guard screen == .askUser else { return }
        guard askUserQuestions.indices.contains(currentQuestionIndex) else { return }

        askUserAnswers[currentQuestionIndex] = value
        if currentQuestionIndex >= askUserQuestions.count - 1 {
            startReplyGeneration()
        } else {
            currentQuestionIndex += 1
        }
    }

    public func handleBottomTabTap(_ tab: MoteBottomTab) -> MoteBottomTabResult {
        switch tab {
        case .moteAI:
            startAskUserFlow()
            return .keepUpside
        case .keyboard:
            if screen == .askUser || screen == .loading {
                cancelAskUserFlowAndDiscardTemporaryState()
            }
            if generatedChips.isEmpty {
                screen = .keyboard
                return .closeUpside
            }
            screen = .stage
            return .keepUpside
        case .fullText:
            guard canOpenFullText else { return .keepUpside }
            screen = .fullText
            return .keepUpside
        }
    }

    public func recordChipTap(_ text: String) {
        tappedChipHistory.append(text)
    }

    public func returnToStageFromFullTextSelection() {
        guard !generatedChips.isEmpty else {
            screen = .keyboard
            return
        }
        screen = .stage
    }

    private func cancelAskUserFlowAndDiscardTemporaryState() {
        flowTask?.cancel()
        flowTask = nil
        isProcessing = false
        askUserQuestions = []
        askUserAnswers = [:]
        currentQuestionIndex = 0
    }

    private func showAskUserQuestions() {
        guard !Task.isCancelled else { return }

        askUserQuestions = Self.defaultQuestions()
        askUserAnswers = [:]
        currentQuestionIndex = 0
        isProcessing = false
        flowTask = nil
        screen = .askUser
    }

    private func startReplyGeneration() {
        flowTask?.cancel()
        flowTask = nil
        isProcessing = true
        screen = .loading

        let answers = askUserAnswers
        flowTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(nanoseconds: 250_000_000)
                try Task.checkCancellation()
            } catch {
                return
            }
            self?.finishReplyGeneration(answers: answers)
        }
    }

    private func finishReplyGeneration(answers: [Int: String]) {
        guard !Task.isCancelled else { return }

        let first = answers[0] ?? "state_concrete"
        let second = answers[1] ?? "act_today"
        let third = answers[2] ?? "thanks_first"

        generatedChips = [
            "ありがとう、まず状況を共有するね。",
            "次の動きは \(humanReadablePlan(from: second)) で進めるよ。",
            "最後に \(humanReadableCare(from: third)) を添えるね。"
        ]
        _ = first

        isProcessing = false
        flowTask = nil
        screen = .stage
    }

    private func humanReadablePlan(from value: String) -> String {
        switch value {
        case "act_tomorrow":
            return "明日対応"
        case "propose_alternative":
            return "代替案の提案"
        default:
            return "今日対応"
        }
    }

    private func humanReadableCare(from value: String) -> String {
        switch value {
        case "reduce_burden":
            return "負担軽減の提案"
        case "ask_confirmation":
            return "確認質問"
        default:
            return "謝意"
        }
    }

    private static func defaultQuestions() -> [MoteAskUserQuestion] {
        [
            MoteAskUserQuestion(
                index: 0,
                text: "まず伝えるべき事実はどれですか？",
                options: [
                    MoteAskUserOption(label: "今の状況を具体的に伝える", value: "state_concrete"),
                    MoteAskUserOption(label: "時間の見通しを伝える", value: "time_estimate"),
                    MoteAskUserOption(label: "未確定であることを伝える", value: "state_uncertain")
                ]
            ),
            MoteAskUserQuestion(
                index: 1,
                text: "次の行動として近いものは？",
                options: [
                    MoteAskUserOption(label: "今日中に対応する", value: "act_today"),
                    MoteAskUserOption(label: "明日対応する", value: "act_tomorrow"),
                    MoteAskUserOption(label: "代替案を提案する", value: "propose_alternative")
                ]
            ),
            MoteAskUserQuestion(
                index: 2,
                text: "相手への配慮として含める要素は？",
                options: [
                    MoteAskUserOption(label: "謝意を先に伝える", value: "thanks_first"),
                    MoteAskUserOption(label: "負担軽減の提案をする", value: "reduce_burden"),
                    MoteAskUserOption(label: "確認質問を添える", value: "ask_confirmation")
                ]
            )
        ]
    }
}
