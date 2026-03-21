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
    case fallback
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
    @Published public private(set) var fallbackMessage: String?

    public private(set) var flowTask: Task<Void, Never>?

    private let apiClient: any MoteRuntimeAPIProviding
    private var latestChatContext: MoteChatContextInput = .empty

    public init(apiClient: any MoteRuntimeAPIProviding = MoteRuntimeAPIClient()) {
        self.apiClient = apiClient
    }

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
        case .askUser, .loading, .fallback:
            return .moteAI
        case .keyboard, .stage:
            return .keyboard
        case .fullText:
            return .fullText
        }
    }

    public func startAskUserFlow(chatContext: MoteChatContextInput = .empty) {
        guard !isProcessing else { return }
        guard screen != .askUser else { return }

        latestChatContext = chatContext

        flowTask?.cancel()
        flowTask = nil

        generatedChips = []
        tappedChipHistory = []
        askUserQuestions = []
        askUserAnswers = [:]
        currentQuestionIndex = 0
        fallbackMessage = nil

        isProcessing = true
        screen = .loading

        flowTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let questions = try await self.apiClient.fetchAskUserQuestions(chatContext: chatContext)
                try Task.checkCancellation()
                self.showAskUserQuestions(questions)
            } catch is CancellationError {
                return
            } catch {
                self.showFallback(message: error.localizedDescription)
            }
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

    public func handleBottomTabTap(_ tab: MoteBottomTab, chatContext: MoteChatContextInput = .empty) -> MoteBottomTabResult {
        switch tab {
        case .moteAI:
            startAskUserFlow(chatContext: chatContext)
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

    public func retryFromFallback(chatContext: MoteChatContextInput = .empty) {
        startAskUserFlow(chatContext: chatContext)
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
        fallbackMessage = nil
    }

    private func showAskUserQuestions(_ questions: [MoteAskUserQuestion]) {
        guard questions.count == 3, questions.allSatisfy({ $0.options.count == 3 }) else {
            showFallback(message: MoteRuntimeAPIError.invalidResponse.localizedDescription)
            return
        }

        askUserQuestions = questions
        askUserAnswers = [:]
        currentQuestionIndex = 0
        isProcessing = false
        flowTask = nil
        fallbackMessage = nil
        screen = .askUser
    }

    private func startReplyGeneration() {
        flowTask?.cancel()
        flowTask = nil
        isProcessing = true
        screen = .loading
        fallbackMessage = nil

        let answers = askUserAnswers
        let chatContext = latestChatContext
        flowTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let chips = try await self.apiClient.generateReplyChips(chatContext: chatContext, answers: answers)
                try Task.checkCancellation()
                self.finishReplyGeneration(chips: chips)
            } catch is CancellationError {
                return
            } catch {
                self.showFallback(message: error.localizedDescription)
            }
        }
    }

    private func finishReplyGeneration(chips: [String]) {
        guard (2...5).contains(chips.count) else {
            showFallback(message: MoteRuntimeAPIError.invalidResponse.localizedDescription)
            return
        }

        generatedChips = chips
        isProcessing = false
        flowTask = nil
        screen = .stage
    }

    private func showFallback(message: String) {
        isProcessing = false
        flowTask = nil
        fallbackMessage = message
        screen = .fallback
    }
}
