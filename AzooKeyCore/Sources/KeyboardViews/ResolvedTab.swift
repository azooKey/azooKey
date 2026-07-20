import CustardKit
import Foundation
import KanaKanjiConverterModule

public enum ResolvedTab: Equatable {
    case standard(TabData.SystemTab)
    case custard(Custard)
    case clipboardHistory
    case emoji

    var inputStyle: InputStyle {
        switch self {
        case .standard(.qwerty_japanese):
            .roman2kana
        case let .custard(custard):
            switch custard.input_style {
            case .direct:
                .direct
            case .roman2kana:
                .roman2kana
            }
        case .standard, .clipboardHistory, .emoji:
            .direct
        }
    }

    var language: KeyboardLanguage? {
        switch self {
        case let .standard(tab):
            switch tab {
            case .flick_japanese, .qwerty_japanese:
                .ja_JP
            case .flick_english, .qwerty_english:
                .en_US
            case .flick_numbersymbols, .qwerty_numbers, .qwerty_symbols:
                nil
            case .user_japanese,
                 .user_english,
                 .last_tab,
                 .clipboard_history_tab,
                 .emoji_tab:
                preconditionFailure("\(tab) is not a standard keyboard")
            }
        case let .custard(custard):
            switch custard.language {
            case .ja_JP:
                .ja_JP
            case .en_US:
                .en_US
            case .el_GR:
                .el_GR
            case .undefined:
                nil
            case .none:
                KeyboardLanguage.none
            }
        case .clipboardHistory, .emoji:
            KeyboardLanguage.none
        }
    }

    public var replacementTarget:
        [ConverterBehaviorSemantics.ReplacementTarget] {
        if case .emoji = self {
            [.emoji]
        } else {
            []
        }
    }
}
