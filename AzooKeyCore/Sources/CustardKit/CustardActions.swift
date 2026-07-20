import Foundation

/// - Tab specifier
public enum TabData: Hashable, Sendable {
    /// - tabs prepared by default
    case system(SystemTab)
    /// - tabs made as custom tabs.
    case custom(String)

    /// - system tabs
    public enum SystemTab: String, Codable, Hashable, Sendable {
        /// japanese input tab. the layout and input style depends on user's setting
        case user_japanese

        /// english input tab. the layout and input style depends on user's setting
        case user_english

        /// flick japanese input tab
        case flick_japanese

        /// flick enlgish input tab
        case flick_english

        /// flick number and symbols input tab
        case flick_numbersymbols

        /// qwerty japanese input tab
        case qwerty_japanese

        /// qwerty english input tab
        case qwerty_english

        /// qwerty number input tab
        case qwerty_numbers

        /// qwerty symbols input tab
        case qwerty_symbols

        /// the last tab
        case last_tab

        /// clipboard history tab
        case clipboard_history_tab

        /// emoji tab
        case emoji_tab

        public init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(String.self)
            var key = rawValue[...]
            // For debug build compatibility
            if key.hasPrefix("__") {
                key = key.dropFirst(2)
            }
            if let value = Self(rawValue: String(key)) {
                self = value
                return
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "unknown system tab: \(rawValue)")
        }
    }
}

public struct ScanItem: Hashable, Sendable {
    public init(targets: [String], direction: ScanItem.Direction) {
        self.targets = targets
        self.direction = direction
    }

    public var targets: [String]
    public var direction: Direction

    public enum Direction: String, Codable, Sendable {
        case forward
        case backward
    }
}

public struct LaunchItem: Hashable, Sendable {
    public init(scheme: LaunchableApplication, target: String) {
        self.scheme = scheme
        self.target = target
    }

    public var scheme: LaunchableApplication
    public var target: String

    public enum LaunchableApplication: String, Codable, Sendable {
        case azooKey
        case shortcuts
    }
}

public enum CandidateSelection: Codable, Hashable, Sendable {
    case first
    case last
    case offset(Int)
    case exact(Int)
}

public extension CandidateSelection {
    private enum CodingKeys: CodingKey {
        case type, value
    }

    private enum ValueType: String, Codable {
        case first, last, offset, exact
    }

    private var valueType: ValueType {
        switch self {
        case .first: .first
        case .last: .last
        case .offset: .offset
        case .exact: .exact
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.valueType, forKey: .type)
        switch self {
        case .first, .last:
            break
        case let .exact(value), let .offset(value):
            try container.encode(value, forKey: .value)

        }
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let valueType = try container.decode(ValueType.self, forKey: .type)
        switch valueType {
        case .first:
            self = .first
        case .last:
            self = .last
        case .offset:
            let value = try container.decode(Int.self, forKey: .value)
            self = .offset(value)
        case .exact:
            let value = try container.decode(Int.self, forKey: .value)
            self = .exact(value)
        }
    }
}

public struct ReplaceBehavior: Hashable, Sendable {
    public init(type: ReplaceBehavior.ReplaceType, fallbacks: [ReplaceBehavior.ReplaceType] = []) {
        self.type = type
        self.fallbacks = fallbacks
    }

    public static let `default` = Self(type: .default, fallbacks: [])
    public enum ReplaceType: String, Codable, Hashable, Sendable {
        /// デフォルト。
        /// - a→A→a
        /// - あ→ぁ→あ
        /// - は→ば→ぱ→は
        /// - つ→っ→づ→つ
        case `default`
        /// 濁点化のみ行う
        case dakuten
        /// 半濁点化のみ行う
        case handakuten
        /// 小書き化のみ行う
        case kogaki
    }
    /// 置換の振る舞い
    public var type: ReplaceType
    /// 置換が行われなかった場合、次に試す置換
    public var fallbacks: [ReplaceType]
}

public enum CharacterForm: String, Codable, Hashable, Sendable {
    case hiragana
    case katakana
    case halfwidthKatakana = "halfwidth_katakana"
    case uppercase
    case lowercase
}

/// - アクション
/// - actions done in key pressing
public enum CodableActionData: Codable, Hashable, Sendable {
    /// - input action specified character
    case input(String)

    /// - input text directly without joining the current composition
    case directInput(String)

    /// - input action specified character
    /// - note: WIP. This action can be removed at any time.
    case paste

    /// - exchange character "あ→ぁ", "は→ば", "a→A"
    case replaceDefault(ReplaceBehavior)

    /// - replace string at the trailing of cursor following to specified table
    case replaceLastCharacters([String: String])

    /// - delete action specified count of characters
    case delete(Int)

    /// - delete to beginning of the sentence
    case smartDeleteDefault

    /// - delete to the ` direction` until `target` appears in the direction of travel..
    /// - if `target` is `[".", ","]`, `direction` is `.backward`, and current text is `I love this. But |she likes`, after the action, the text become `I love this.|she likes`.
    case smartDelete(ScanItem = .init(targets: Self.scanTargets, direction: .forward))

    /// - select candidate to complete
    case selectCandidate(CandidateSelection)

    /// - convert character form then complete current inputting words
    case completeCharacterForm([CharacterForm])

    /// - complete current inputting words
    case complete

    /// - move cursor  specified count forward. when you specify negative number, the cursor moves backword
    case moveCursor(Int)

    /// - move cursor to the ` direction` until `target` appears in the direction of travel..
    /// - if `target` is `[".", ","]`, `direction` is `.backward`, and current text is `I love this. But |she likes`, after the action, the text become `I love this.| But she likes`.
    case smartMoveCursor(ScanItem = .init(targets: Self.scanTargets, direction: .forward))

    /// - move to specified tab
    case moveTab(TabData)

    /// - enable keyboard resizing mode
    case enableResizingMode

    /// - toggle show or not show the cursor move bar
    case toggleCursorBar

    /// - toggle capslock or not
    case toggleCapsLockState

    /// - toggle show or not show the tab bar
    case toggleTabBar

    /// - dismiss keyboard
    case dismissKeyboard

    /// - launch apps
    case launchApplication(LaunchItem)

    public static let scanTargets = ["、", "。", "！", "？", ".", ",", "．", "，", "\n"]
}

public extension CodableActionData {
    private enum CodingKeys: CodingKey {
        case type
        case text
        case count
        case table
        case tab_type, identifier
        case direction, targets
        case scheme_type, target
        case selection
        case replace_type, fallbacks
        case forms
    }

    private enum ValueType: String, Codable {
        case direct_input
        case input
        case paste
        case replace_default
        case replace_last_characters
        case delete
        case smart_delete
        case smart_delete_default
        case select_candidate
        case complete_character_form
        case complete
        case move_cursor
        case smart_move_cursor
        case move_tab
        case enable_resizing_mode
        case toggle_cursor_bar
        case toggle_tab_bar
        case toggle_caps_lock_state
        case dismiss_keyboard
        case launch_application
        // This case is left for debug build compatibility.
        case __paste
    }

    private var key: ValueType {
        switch self {
        case .directInput: return .direct_input
        case .selectCandidate: return .select_candidate
        case .completeCharacterForm: return .complete_character_form
        case .complete: return .complete
        case .delete: return .delete
        case .dismissKeyboard: return .dismiss_keyboard
        case .input: return .input
        case .launchApplication: return .launch_application
        case .moveCursor: return .move_cursor
        case .moveTab: return .move_tab
        case .replaceDefault: return .replace_default
        case .replaceLastCharacters: return .replace_last_characters
        case .smartDelete: return .smart_delete
        case .smartDeleteDefault: return .smart_delete_default
        case .smartMoveCursor: return .smart_move_cursor
        case .enableResizingMode: return .enable_resizing_mode
        case .toggleCapsLockState: return .toggle_caps_lock_state
        case .toggleCursorBar: return .toggle_cursor_bar
        case .toggleTabBar: return .toggle_tab_bar
        case .paste: return .paste
        }
    }

    private struct CodableTabArgument {
        internal init(tab: TabData) {
            self.tab = tab
        }
        private var tab: TabData

        private enum TabType: String, Codable {
            case custom, system
        }

        func containerEncode(container: inout KeyedEncodingContainer<CodingKeys>) throws {
            switch tab {
            case .system:
                try container.encode(TabType.system, forKey: .tab_type)
            case .custom:
                try container.encode(TabType.custom, forKey: .tab_type)
            }
            switch tab {
            case let .system(value as any Encodable),
                 let .custom(value as any Encodable):
                try value.containerEncode(container: &container, key: .identifier)
            }
        }

        static func containerDecode(container: KeyedDecodingContainer<CodingKeys>) throws -> TabData {
            let type = try container.decode(TabType.self, forKey: .tab_type)
            switch type {
            case .system:
                let tab = try container.decode(TabData.SystemTab.self, forKey: .identifier)
                return .system(tab)
            case .custom:
                let tab = try container.decode(String.self, forKey: .identifier)
                return .custom(tab)
            }
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.key, forKey: .type)
        switch self {
        case let .input(value):
            try container.encode(value, forKey: .text)
        case let .directInput(value):
            try container.encode(value, forKey: .text)
        case let .replaceDefault(value):
            // デフォルト値以外の場合のみ明示的にエンコード
            if value.type != .default {
                try container.encode(value.type, forKey: .replace_type)
            }
            if !value.fallbacks.isEmpty {
                try container.encode(value.fallbacks, forKey: .fallbacks)
            }
        case let .replaceLastCharacters(value):
            try container.encode(value, forKey: .table)
        case let .delete(value), let .moveCursor(value):
            try container.encode(value, forKey: .count)
        case let .smartDelete(value), let .smartMoveCursor(value):
            try container.encode(value.direction, forKey: .direction)
            try container.encode(value.targets, forKey: .targets)
        case let .launchApplication(value):
            try container.encode(value.scheme, forKey: .scheme_type)
            try container.encode(value.target, forKey: .target)
        case let .selectCandidate(value):
            try container.encode(value, forKey: .selection)
        case let .completeCharacterForm(value):
            try container.encode(value, forKey: .forms)
        case let .moveTab(value):
            try CodableTabArgument(tab: value).containerEncode(container: &container)
        case .dismissKeyboard, .enableResizingMode, .toggleTabBar, .toggleCursorBar, .toggleCapsLockState, .complete, .smartDeleteDefault, .paste: break
        }
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let valueType = try container.decode(ValueType.self, forKey: .type)
        switch valueType {
        case .direct_input:
            let value = try container.decode(String.self, forKey: .text)
            self = .directInput(value)
        case .input:
            let value = try container.decode(String.self, forKey: .text)
            self = .input(value)
        case .replace_default:
            let replaceType = try container.decodeIfPresent(ReplaceBehavior.ReplaceType.self, forKey: .replace_type) ?? .default
            let fallbacks = try container.decodeIfPresent([ReplaceBehavior.ReplaceType].self, forKey: .fallbacks) ?? []
            self = .replaceDefault(.init(type: replaceType, fallbacks: fallbacks))
        case .replace_last_characters:
            let value = try container.decode([String: String].self, forKey: .table)
            self = .replaceLastCharacters(value)
        case .delete:
            let value = try container.decode(Int.self, forKey: .count)
            self = .delete(value)
        case .smart_delete_default:
            self = .smartDeleteDefault
        case .smart_delete:
            let direction = try container.decode(ScanItem.Direction.self, forKey: .direction)
            let targets = try container.decode([String].self, forKey: .targets)
            self = .smartDelete(.init(targets: targets, direction: direction))
        case .select_candidate:
            let selection = try container.decode(CandidateSelection.self, forKey: .selection)
            self = .selectCandidate(selection)
        case .complete_character_form:
            let forms = try container.decode([CharacterForm].self, forKey: .forms)
            self = .completeCharacterForm(forms)
        case .complete:
            self = .complete
        case .move_cursor:
            let value = try container.decode(Int.self, forKey: .count)
            self = .moveCursor(value)
        case .smart_move_cursor:
            let direction = try container.decode(ScanItem.Direction.self, forKey: .direction)
            let targets = try container.decode([String].self, forKey: .targets)
            self = .smartMoveCursor(.init(targets: targets, direction: direction))
        case .move_tab:
            let value = try CodableTabArgument.containerDecode(container: container)
            self = .moveTab(value)
        case .enable_resizing_mode:
            self = .enableResizingMode
        case .toggle_cursor_bar:
            self = .toggleCursorBar
        case .toggle_caps_lock_state:
            self = .toggleCapsLockState
        case .toggle_tab_bar:
            self = .toggleTabBar
        case .dismiss_keyboard:
            self = .dismissKeyboard
        case .launch_application:
            let scheme = try container.decode(LaunchItem.LaunchableApplication.self, forKey: .scheme_type)
            let target = try container.decode(String.self, forKey: .target)
            self = .launchApplication(.init(scheme: scheme, target: target))
        case .__paste, .paste:
            self = .paste
        }
    }
}

public struct CodableLongpressActionData: Codable, Equatable, Hashable, Sendable {
    public enum LongpressDuration: String, Codable, Hashable, Sendable {
        /// 通常の長押し操作には`normal`を推奨する
        case normal
        /// 長押しを利用する意図が通常タッチとの区別に過ぎず、押し判定自体は軽量であるべき場合は`light`を推奨する
        case light
    }
    public static let none = CodableLongpressActionData()
    public init(duration: LongpressDuration = .normal, start: [CodableActionData] = [], repeat: [CodableActionData] = []) {
        self.start = start
        self.repeat = `repeat`
        self.duration = duration
    }

    public var duration: LongpressDuration
    public var start: [CodableActionData]
    public var `repeat`: [CodableActionData]

    private enum CodingKeys: CodingKey {
        case duration
        case start
        case `repeat`
    }

    public init(from decoder: any Decoder) throws {
        let container: KeyedDecodingContainer<CodableLongpressActionData.CodingKeys> = try decoder.container(keyedBy: CodableLongpressActionData.CodingKeys.self)

        self.duration = try container.decodeIfPresent(CodableLongpressActionData.LongpressDuration.self, forKey: CodableLongpressActionData.CodingKeys.duration) ?? .normal
        self.start = try container.decode([CodableActionData].self, forKey: CodableLongpressActionData.CodingKeys.start)
        self.repeat = try container.decode([CodableActionData].self, forKey: CodableLongpressActionData.CodingKeys.repeat)

    }
}
