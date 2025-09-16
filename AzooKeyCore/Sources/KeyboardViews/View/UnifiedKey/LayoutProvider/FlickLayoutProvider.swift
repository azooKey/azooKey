import CustardKit
import Foundation
import SwiftUI
import enum KanaKanjiConverterModule.KeyboardLanguage

struct FlickLayoutProvider<Extension: ApplicationSpecificKeyboardViewExtension> {

    // MARK: - Helpers
    @MainActor private static func unifiedFromSetting(_ data: KeyFlickSetting.SettingData, color: FlickCustomKeyModel<Extension>.ColorRole = .special) -> any UnifiedKeyModelProtocol<Extension> {
        let map = data.flick.mapValues { UnifiedVariation(label: $0.labelType, pressActions: $0.pressActions, longPressActions: $0.longPressActions) }
        return FlickCustomKeyModel<Extension>(
            labelType: data.labelType,
            pressActions: data.actions,
            longPressActions: data.longpressActions,
            flick: map,
            showsTapBubble: false,
            colorRole: color
        )
    }

    @MainActor private static func customKey(center: String, left: String? = nil, top: String? = nil, right: String? = nil, bottom: String? = nil, color: UnifiedGeneralKeyModel<Extension>.ColorRole = .normal) -> any UnifiedKeyModelProtocol<Extension> {
        var map: [FlickDirection: UnifiedVariation] = [:]
        if let left { map[.left] = UnifiedVariation(label: .text(left), pressActions: [.input(left)]) }
        if let top { map[.top] = UnifiedVariation(label: .text(top), pressActions: [.input(top)]) }
        if let right { map[.right] = UnifiedVariation(label: .text(right), pressActions: [.input(right)]) }
        if let bottom { map[.bottom] = UnifiedVariation(label: .text(bottom), pressActions: [.input(bottom)]) }
        return UnifiedGeneralKeyModel<Extension>(
            labelType: .text(center),
            pressActions: [.input(center)],
            longPressActions: .none,
            flick: map,
            linearVariations: [],
            linearDirection: .center,
            showsTapBubble: false,
            colorRole: color
        )
    }

    @MainActor private static func customKey(label: KeyLabelType, center: String, left: String? = nil, top: String? = nil, right: String? = nil, bottom: String? = nil, color: UnifiedGeneralKeyModel<Extension>.ColorRole = .normal) -> any UnifiedKeyModelProtocol<Extension> {
        var map: [FlickDirection: UnifiedVariation] = [:]
        if let left { map[.left] = UnifiedVariation(label: .text(left), pressActions: [.input(left)]) }
        if let top { map[.top] = UnifiedVariation(label: .text(top), pressActions: [.input(top)]) }
        if let right { map[.right] = UnifiedVariation(label: .text(right), pressActions: [.input(right)]) }
        if let bottom { map[.bottom] = UnifiedVariation(label: .text(bottom), pressActions: [.input(bottom)]) }
        return UnifiedGeneralKeyModel<Extension>(
            labelType: label,
            pressActions: [.input(center)],
            longPressActions: .none,
            flick: map,
            linearVariations: [],
            linearDirection: .center,
            showsTapBubble: false,
            colorRole: color
        )
    }

    @MainActor private static func tabKeys() -> [any UnifiedKeyModelProtocol<Extension>] {
        [
            unifiedFromSetting(Extension.SettingProvider.symbolsTabFlickCustomKey.compiled()),
            unifiedFromSetting(Extension.SettingProvider.abcTabFlickCustomKey.compiled()),
            unifiedFromSetting(Extension.SettingProvider.hiraTabFlickCustomKey.compiled()),
            FlickChangeKeyboardKeyModel<Extension>(),
        ]
    }

    @MainActor private static func functionalKeys() -> [any UnifiedKeyModelProtocol<Extension>] {
        // delete with left-flick smoothDelete
        let delete: any UnifiedKeyModelProtocol<Extension> = UnifiedGeneralKeyModel<Extension>(
            labelType: .image("delete.left"),
            pressActions: [.delete(1)],
            longPressActions: .init(repeat: [.delete(1)]),
            flick: [
                .left: UnifiedVariation(label: .image("xmark"), pressActions: [.smoothDelete])
            ],
            linearVariations: [],
            linearDirection: .center,
            showsTapBubble: false,
            colorRole: .special
        )

        let spaceOrNext: any UnifiedKeyModelProtocol<Extension> = Extension.SettingProvider.useNextCandidateKey
            ? FlickNextCandidateKeyModel<Extension>()
            : FlickSpaceKeyModel<Extension>()

        let enter = UnifiedEnterKeyModel<Extension>(textSize: .large)
        return [delete, spaceOrNext, enter]
    }

    // MARK: - Public layout
    @MainActor static var hiraKeyboard: [UnifiedPositionSpecifier: any UnifiedKeyModelProtocol<Extension>] {
        let columns: [[any UnifiedKeyModelProtocol<Extension>]] = [
            // 1st column (tabs)
            tabKeys(),
            // 2nd column
            [
                customKey(center: "あ", left: "い", top: "う", right: "え", bottom: "お"),
                customKey(center: "た", left: "ち", top: "つ", right: "て", bottom: "と"),
                customKey(center: "ま", left: "み", top: "む", right: "め", bottom: "も"),
                FlickKogakiKeyModel<Extension>(),
            ],
            // 3rd column
            [
                customKey(center: "か", left: "き", top: "く", right: "け", bottom: "こ"),
                customKey(center: "な", left: "に", top: "ぬ", right: "ね", bottom: "の"),
                customKey(center: "や", left: "「", top: "ゆ", right: "」", bottom: "よ"),
                customKey(center: "わ", left: "を", top: "ん", right: "ー"),
            ],
            // 4th column
            [
                customKey(center: "さ", left: "し", top: "す", right: "せ", bottom: "そ"),
                customKey(center: "は", left: "ひ", top: "ふ", right: "へ", bottom: "ほ"),
                customKey(center: "ら", left: "り", top: "る", right: "れ", bottom: "ろ"),
                FlickKanaSymbolsKeyModel<Extension>(),
            ],
            // 5th column (functional)
            functionalKeys(),
        ]

        var dict: [UnifiedPositionSpecifier: any UnifiedKeyModelProtocol<Extension>] = [:]
        for (x, col) in columns.enumerated() {
            for (y, model) in col.enumerated() {
                let height: CGFloat = (x == 4 && y == 2) ? 2 : 1
                let pos = UnifiedPositionSpecifier(x: CGFloat(x), y: CGFloat(y), width: 1, height: height)
                dict[pos] = model
            }
        }
        return dict
    }

    // MARK: - ABC layout
    @MainActor static var abcKeyboard: [UnifiedPositionSpecifier: any UnifiedKeyModelProtocol<Extension>] {
        let columns: [[any UnifiedKeyModelProtocol<Extension>]] = [
            // 1st column (tabs)
            tabKeys(),
            // 2nd column
            [
                customKey(label: .text("@#/&_"), center: "@", left: "#", top: "/", right: "&", bottom: "_"),
                customKey(label: .text("GHI"), center: "g", left: "h", top: "i"),
                customKey(label: .text("PQRS"), center: "p", left: "q", top: "r", right: "s"),
                FlickAaKeyModel<Extension>(),
            ],
            // 3rd column
            [
                customKey(label: .text("ABC"), center: "a", left: "b", top: "c"),
                customKey(label: .text("JKL"), center: "j", left: "k", top: "l"),
                customKey(label: .text("TUV"), center: "t", left: "u", top: "v"),
                customKey(label: .text("'\"()"), center: "'", left: "\"", top: "(", right: ")"),
            ],
            // 4th column
            [
                customKey(label: .text("DEF"), center: "d", left: "e", top: "f"),
                customKey(label: .text("MNO"), center: "m", left: "n", top: "o"),
                customKey(label: .text("WXYZ"), center: "w", left: "x", top: "y", right: "z"),
                customKey(label: .text(".,?!"), center: ".", left: ",", top: "?", right: "!"),
            ],
            // 5th column (functional)
            functionalKeys(),
        ]

        var dict: [UnifiedPositionSpecifier: any UnifiedKeyModelProtocol<Extension>] = [:]
        for (x, col) in columns.enumerated() {
            for (y, model) in col.enumerated() {
                let height: CGFloat = (x == 4 && y == 2) ? 2 : 1
                let pos = UnifiedPositionSpecifier(x: CGFloat(x), y: CGFloat(y), width: 1, height: height)
                dict[pos] = model
            }
        }
        return dict
    }

    // MARK: - Number/Symbols layout
    @MainActor static var numberKeyboard: [UnifiedPositionSpecifier: any UnifiedKeyModelProtocol<Extension>] {
        let columns: [[any UnifiedKeyModelProtocol<Extension>]] = [
            // 1st column (tabs)
            tabKeys(),
            // 2nd column
            [
                customKey(label: .symbols(["1", "☆", "♪", "→"]), center: "1", left: "☆", top: "♪", right: "→"),
                customKey(label: .symbols(["4", "○", "＊", "・"]), center: "4", left: "○", top: "＊", right: "・"),
                customKey(label: .symbols(["7", "「", "」", ":"]), center: "7", left: "「", top: "」", right: ":"),
                customKey(label: .text("()[]"), center: "(", left: ")", top: "[", right: "]"),
            ],
            // 3rd column
            [
                customKey(label: .symbols(["2", "¥", "$", "€"]), center: "2", left: "¥", top: "$", right: "€"),
                customKey(label: .symbols(["5", "+", "×", "÷"]), center: "5", left: "+", top: "×", right: "÷"),
                customKey(label: .symbols(["8", "〒", "々", "〆"]), center: "8", left: "〒", top: "々", right: "〆"),
                customKey(label: .symbols(["0", "〜", "…"]), center: "0", left: "〜", top: "…"),
            ],
            // 4th column
            [
                customKey(label: .symbols(["3", "%", "°", "#"]), center: "3", left: "%", top: "°", right: "#"),
                customKey(label: .symbols(["6", "<", "=", ">"]), center: "6", left: "<", top: "=", right: ">"),
                customKey(label: .symbols(["9", "^", "|", "\\"]), center: "9", left: "^", top: "|", right: "\\"),
                customKey(label: .text(".,-/"), center: ".", left: ",", top: "-", right: "/"),
            ],
            // 5th column (functional)
            functionalKeys(),
        ]

        var dict: [UnifiedPositionSpecifier: any UnifiedKeyModelProtocol<Extension>] = [:]
        for (x, col) in columns.enumerated() {
            for (y, model) in col.enumerated() {
                let height: CGFloat = (x == 4 && y == 2) ? 2 : 1
                let pos = UnifiedPositionSpecifier(x: CGFloat(x), y: CGFloat(y), width: 1, height: height)
                dict[pos] = model
            }
        }
        return dict
    }
}
