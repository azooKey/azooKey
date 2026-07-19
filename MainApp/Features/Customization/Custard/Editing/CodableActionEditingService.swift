import AzooKeyUtils
import CustardKit
import KeyboardViews
import SwiftUI

enum CodableActionEditingService {
    static func makeEditingActions(from actions: [CodableActionData]) -> [EditingCodableActionData] {
        actions.map(EditingCodableActionData.init(data:))
    }

    static func serialize(_ actions: [EditingCodableActionData]) -> [CodableActionData] {
        actions.map(\.data)
    }

    static func normalized(_ scanItem: ScanItem) -> ScanItem {
        ScanItem(targets: Array(scanItem.targets.uniqued()), direction: scanItem.direction)
    }

    static func replacementDictionary(
        from pairs: [CodableActionReplacementPair]
    ) -> [String: String] {
        Dictionary(
            pairs.uniqued().map { (key: $0.first, value: $0.second) },
            uniquingKeysWith: { first, _ in first }
        )
    }

    static func stringArrayDescription(_ array: [String]) -> String {
        array.map { $0 == "\n" ? "改行" : "'\($0)'" }.joined(separator: ", ")
    }
}

struct CodableActionReplacementPair: Equatable, Hashable {
    var first: String
    var second: String
}

extension CharacterForm {
    var label: LocalizedStringKey {
        switch self {
        case .hiragana: "ひらがな"
        case .katakana: "カタカナ"
        case .halfwidthKatakana: "半角カタカナ"
        case .lowercase: "小文字"
        case .uppercase: "大文字"
        }
    }
}

extension CodableActionData {
    var hasAssociatedValue: Bool {
        switch self {
        case .input, .directInput, .moveCursor, .delete:
            false
        case .smartDelete, .replaceLastCharacters, .replaceDefault, .smartMoveCursor,
             .moveTab, .launchApplication, .selectCandidate, .completeCharacterForm:
            true
        case .enableResizingMode, .complete, .smartDeleteDefault, .toggleCapsLockState,
             .toggleCursorBar, .toggleTabBar, .dismissKeyboard, .paste:
            false
        }
    }

    var label: LocalizedStringKey {
        switch self {
        case let .input(value):
            if value == "\n" {
                return "改行を入力"
            }
            return "「\(value)」を入力"
        case let .directInput(value):
            return "「\(value)」を直接入力"
        case let .moveCursor(value):
            return "\(String(value))文字分カーソルを移動"
        case let .smartMoveCursor(value):
            return "\(CodableActionEditingService.stringArrayDescription(value.targets))の隣までカーソルを移動"
        case let .delete(value):
            return "\(String(value))文字削除"
        case let .smartDelete(value):
            return "\(CodableActionEditingService.stringArrayDescription(value.targets))の隣まで削除"
        case .paste:
            return "ペーストする"
        case .moveTab:
            return "タブの移動"
        case .replaceLastCharacters:
            return "末尾の文字を置換"
        case let .selectCandidate(selection):
            return switch selection {
            case .first: "最初の候補を選択"
            case .last: "最後の候補を選択"
            case let .offset(value): "\(value)個隣の候補を選択"
            case let .exact(value): "\(value)番目の候補を選択"
            }
        case .complete:
            return "確定"
        case .completeCharacterForm:
            return "文字種で入力を確定"
        case .replaceDefault:
            return "特殊な置換"
        case .smartDeleteDefault:
            return "文頭まで削除"
        case .toggleCapsLockState:
            return "Caps lockのモードの切り替え"
        case .toggleCursorBar:
            return "カーソルバーの切り替え"
        case .toggleTabBar:
            return "タブバーの切り替え"
        case .dismissKeyboard:
            return "キーボードを閉じる"
        case .enableResizingMode:
            return "片手モードをオンにする"
        case let .launchApplication(value):
            switch value.scheme {
            case .azooKey:
                return "azooKey本体アプリを開く"
            case .shortcuts:
                return "ショートカットを実行する"
            }
        }
    }
}

extension TabData {
    var label: LocalizedStringKey {
        switch self {
        case let .system(tab):
            switch tab {
            case .user_japanese:
                return "日本語(設定に合わせる)"
            case .user_english:
                return "英語(設定に合わせる)"
            case .flick_japanese:
                return "日本語(フリック入力)"
            case .flick_english:
                return "英語(フリック入力)"
            case .flick_numbersymbols:
                return "記号と数字(フリック入力)"
            case .qwerty_japanese:
                return "日本語(ローマ字入力)"
            case .qwerty_english:
                return "英語(ローマ字入力)"
            case .qwerty_numbers:
                return "数字(ローマ字入力)"
            case .qwerty_symbols:
                return "記号(ローマ字入力)"
            case .last_tab:
                return "最後に表示していたタブ"
            case .clipboard_history_tab:
                return "クリップボードの履歴"
            case .emoji_tab:
                return "絵文字"
            }
        case let .custom(identifier):
            return LocalizedStringKey(identifier)
        }
    }
}
