import Foundation

public struct MoteChatContextInput: Equatable, Sendable {
    public let leftText: String
    public let centerText: String
    public let rightText: String

    public init(leftText: String, centerText: String, rightText: String) {
        self.leftText = leftText
        self.centerText = centerText
        self.rightText = rightText
    }

    public static let empty = MoteChatContextInput(leftText: "", centerText: "", rightText: "")
}

@MainActor
public protocol MoteRuntimeAPIProviding {
    func fetchAskUserQuestions(chatContext: MoteChatContextInput) async throws -> [MoteAskUserQuestion]
    func generateReplyChips(chatContext: MoteChatContextInput, answers: [Int: String]) async throws -> [String]
}

public enum MoteRuntimeAPIError: LocalizedError {
    case missingConfiguration
    case invalidRequest
    case invalidResponse
    case serverError(statusCode: Int)
    case timeout

    public var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return "API接続先が設定されていません。"
        case .invalidRequest:
            return "リクエストの作成に失敗しました。"
        case .invalidResponse:
            return "AI応答の形式が不正です。"
        case let .serverError(statusCode):
            return "AIサーバーでエラーが発生しました (HTTP \(statusCode))。"
        case .timeout:
            return "AI応答がタイムアウトしました。"
        }
    }
}

public struct MoteRuntimeAPIClient: MoteRuntimeAPIProviding {
    private let configuration: Configuration

    public init(bundle: Bundle = .main, userDefaults: UserDefaults = .standard) {
        self.configuration = Configuration.resolve(bundle: bundle, userDefaults: userDefaults)
    }

    public func fetchAskUserQuestions(chatContext: MoteChatContextInput) async throws -> [MoteAskUserQuestion] {
        let endpoint = try configuration.askUserEndpoint()
        let requestBody = AskUserRequest(chat_context: .fromInput(chatContext))
        let response: AskUserResponse = try await postJSON(to: endpoint, body: requestBody)

        let questions = response.questions.enumerated().map { index, question in
            MoteAskUserQuestion(
                index: index,
                text: question.question,
                options: question.options.map {
                    MoteAskUserOption(label: $0.label, value: $0.value)
                }
            )
        }
        guard questions.count == 3, questions.allSatisfy({ $0.options.count == 3 }) else {
            throw MoteRuntimeAPIError.invalidResponse
        }
        return questions
    }

    public func generateReplyChips(chatContext: MoteChatContextInput, answers: [Int: String]) async throws -> [String] {
        let endpoint = try configuration.replyEndpoint()
        let sortedAnswers = answers.sorted(by: { $0.key < $1.key })
        let requestBody = ReplyRequest(
            chat_context: .fromInput(chatContext),
            user_responses: Dictionary(uniqueKeysWithValues: sortedAnswers.map { (String($0.key), $0.value) }),
            today_date: Self.dateFormatter.string(from: Date())
        )
        let response: ReplyResponse = try await postJSON(to: endpoint, body: requestBody)
        let chips = response.chips.map(\.text).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard (2...5).contains(chips.count) else {
            throw MoteRuntimeAPIError.invalidResponse
        }
        return chips
    }

    private func postJSON<Body: Encodable, Response: Decodable>(to url: URL, body: Body) async throws -> Response {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = configuration.timeoutSeconds
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let error as URLError where error.code == .timedOut {
            throw MoteRuntimeAPIError.timeout
        } catch {
            throw error
        }

        guard let http = response as? HTTPURLResponse else {
            throw MoteRuntimeAPIError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw MoteRuntimeAPIError.serverError(statusCode: http.statusCode)
        }

        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            throw MoteRuntimeAPIError.invalidResponse
        }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

private extension MoteRuntimeAPIClient {
    struct Configuration {
        let askUserURLString: String?
        let replyURLString: String?
        let baseURLString: String?
        let askUserPath: String
        let replyPath: String
        let timeoutSeconds: TimeInterval

        static func resolve(bundle: Bundle, userDefaults: UserDefaults) -> Self {
            let askUserURL = sanitized(
                userDefaults.string(forKey: "mote_api_ask_user_url")
                    ?? bundle.object(forInfoDictionaryKey: "MoteAPIAskUserURL") as? String
            )
            let replyURL = sanitized(
                userDefaults.string(forKey: "mote_api_reply_url")
                    ?? bundle.object(forInfoDictionaryKey: "MoteAPIReplyURL") as? String
            )
            let baseURL = sanitized(
                userDefaults.string(forKey: "mote_api_base_url")
                    ?? bundle.object(forInfoDictionaryKey: "MoteAPIBaseURL") as? String
            )
            let askPath = sanitized(
                userDefaults.string(forKey: "mote_api_ask_user_path")
                    ?? (bundle.object(forInfoDictionaryKey: "MoteAPIAskUserPath") as? String)
            )
                ?? "/api/mote/ask-user"
            let replyPath = sanitized(
                userDefaults.string(forKey: "mote_api_reply_path")
                    ?? (bundle.object(forInfoDictionaryKey: "MoteAPIReplyPath") as? String)
            )
                ?? "/api/mote/reply"

            return .init(
                askUserURLString: askUserURL,
                replyURLString: replyURL,
                baseURLString: baseURL,
                askUserPath: askPath,
                replyPath: replyPath,
                timeoutSeconds: 10
            )
        }

        func askUserEndpoint() throws -> URL {
            try resolveURL(absoluteURL: askUserURLString, path: askUserPath)
        }

        func replyEndpoint() throws -> URL {
            try resolveURL(absoluteURL: replyURLString, path: replyPath)
        }

        private func resolveURL(absoluteURL: String?, path: String) throws -> URL {
            if let absoluteURL, let url = URL(string: absoluteURL) {
                return url
            }
            guard let baseURLString, let baseURL = URL(string: baseURLString) else {
                throw MoteRuntimeAPIError.missingConfiguration
            }
            let normalizedPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
            return baseURL.appendingPathComponent(normalizedPath)
        }

        private static func sanitized(_ value: String?) -> String? {
            guard let value else { return nil }
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            guard !(trimmed.hasPrefix("$(") && trimmed.hasSuffix(")")) else {
                return nil
            }
            return trimmed
        }
    }

    struct AskUserRequest: Encodable {
        let chat_context: ChatContext
    }

    struct ReplyRequest: Encodable {
        let chat_context: ChatContext
        let user_responses: [String: String]
        let today_date: String
    }

    struct ChatContext: Codable {
        struct Message: Codable {
            let speaker: String
            let text: String
            let date_label: String?
            let time: String?
        }

        let chat_detected: Bool
        let app: String
        let messages: [Message]
        let last_speaker: String?
        let last_message: String?

        static func fromInput(_ input: MoteChatContextInput) -> Self {
            let merged = [input.leftText, input.centerText, input.rightText]
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: "\n")

            guard !merged.isEmpty else {
                return .init(
                    chat_detected: false,
                    app: "unknown",
                    messages: [],
                    last_speaker: nil,
                    last_message: nil
                )
            }

            return .init(
                chat_detected: true,
                app: "LINE",
                messages: [
                    .init(speaker: "partner", text: merged, date_label: nil, time: nil)
                ],
                last_speaker: "partner",
                last_message: merged
            )
        }
    }

    struct AskUserResponse: Decodable {
        struct Question: Decodable {
            struct Option: Decodable {
                let label: String
                let value: String
            }

            let question: String
            let options: [Option]
        }

        let questions: [Question]
    }

    struct ReplyResponse: Decodable {
        struct Chip: Decodable {
            let text: String
        }

        let chips: [Chip]
    }
}
