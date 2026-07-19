import CustardKit

public extension Custard {
    static let qwertyJapanese = DefaultQwertyCustards.japanese
    static let qwertyEnglish = DefaultQwertyCustards.english
    static let qwertyNumbers = DefaultQwertyCustards.numbers
    static let qwertySymbols = DefaultQwertyCustards.symbols
}

private enum DefaultQwertyCustards {
    /// 標準QWERTYの横幅を20分割した整数グリッドで表現する。
    private static let layout = CustardInterfaceLayout.gridFit(
        .init(rowCount: 20, columnCount: 4)
    )

    static var japanese: Custard {
        var keys = letterKeys(
            secondRowTrailingKey: inputKey(
                "ー",
                variations: ["ー", "。", "、", "！", "？", "・"]
            )
        )
        keys[position(0, 2, width: 3)] = .system(.qwertyLanguageSwitch)
        addThirdRowLetters(to: &keys)
        addBottomRow(
            to: &keys,
            leadingKey: tabKey(
                label: .systemImage("textformat.123"),
                destination: .qwerty_numbers
            ),
            spaceLabel: "空白"
        )
        return custard(
            identifier: "japanese_qwerty",
            displayName: "日本語QWERTY",
            language: .ja_JP,
            inputStyle: .roman2kana,
            keys: keys
        )
    }

    static var english: Custard {
        var keys = letterKeys(secondRowTrailingKey: .system(.upperLower))
        keys[position(0, 2, width: 3)] = .system(.qwertyLanguageSwitch)
        addThirdRowLetters(to: &keys)
        addBottomRow(
            to: &keys,
            leadingKey: tabKey(
                label: .systemImage("textformat.123"),
                destination: .qwerty_numbers
            ),
            spaceLabel: "space"
        )
        return custard(
            identifier: "english_qwerty",
            displayName: "英語QWERTY",
            language: .en_US,
            inputStyle: .direct,
            keys: keys
        )
    }

    static var numbers: Custard {
        var keys: [CustardKeyPositionSpecifier: CustardInterfaceKey] = [:]
        let numberVariations = [
            ["1", "１", "一", "①"],
            ["2", "２", "二", "②"],
            ["3", "３", "三", "③"],
            ["4", "４", "四", "④"],
            ["5", "５", "五", "⑤"],
            ["6", "６", "六", "⑥"],
            ["7", "７", "七", "⑦"],
            ["8", "８", "八", "⑧"],
            ["9", "９", "九", "⑨"],
            ["0", "０", "〇", "⓪"],
        ]
        for (index, variations) in numberVariations.enumerated() {
            keys[position(index * 2, 0)] = inputKey(
                variations[0],
                variations: variations
            )
        }

        let secondRow: [(String, [String])] = [
            ("-", []),
            ("/", ["/", "\\"]),
            (":", [":", "：", ";", "；"]),
            ("@", ["@", "＠"]),
            ("(", []),
            (")", []),
            ("「", ["「", "『", "【", "（", "《"]),
            ("」", ["」", "』", "】", "）", "》"]),
            ("¥", ["¥", "￥", "$", "＄", "€", "₿", "£", "¤"]),
            ("&", ["&", "＆"]),
        ]
        for (index, item) in secondRow.enumerated() {
            keys[position(index * 2, 1)] = inputKey(
                item.0,
                variations: item.1
            )
        }

        keys[position(0, 2, width: 3)] = tabKey(
            label: .text("#+="),
            destination: .qwerty_symbols
        )
        let punctuation: [(String, [String])] = [
            ("。", ["。", "."]),
            ("、", ["、", ","]),
            ("？", ["？", "?"]),
            ("！", ["！", "!"]),
            ("・", ["・", "…"]),
        ]
        for (item, geometry) in zip(punctuation, punctuationGeometry) {
            keys[position(geometry.x, 2, width: geometry.width)] = inputKey(
                item.0,
                variations: item.1
            )
        }
        keys[position(17, 2, width: 3)] = deleteKey

        addBottomRow(
            to: &keys,
            leadingKey: .system(.qwertyLanguageSwitch),
            spaceLabel: "空白"
        )
        return custard(
            identifier: "numbers_qwerty",
            displayName: "数字QWERTY",
            language: .none,
            inputStyle: .direct,
            keys: keys
        )
    }

    static var symbols: Custard {
        var keys: [CustardKeyPositionSpecifier: CustardInterfaceKey] = [:]
        let firstRow: [(String, [String])] = [
            ("[", ["［"]),
            ("]", ["］"]),
            ("{", ["｛"]),
            ("}", ["｝"]),
            ("#", ["＃"]),
            ("%", ["％"]),
            ("^", ["＾"]),
            ("*", ["＊"]),
            ("+", ["＋", "±"]),
            ("=", ["＝", "≡", "≒", "≠"]),
        ]
        for (index, item) in firstRow.enumerated() {
            keys[position(index * 2, 0)] = inputKey(
                item.0,
                variations: item.1
            )
        }

        let secondRow: [(String, [String])] = [
            ("_", []),
            ("\\", ["/", "\\"]),
            (";", [":", "：", ";", "；"]),
            ("|", ["｜"]),
            ("<", ["＜"]),
            (">", ["＞"]),
            ("\"", ["＂", "“", "”"]),
            ("'", ["`"]),
            ("$", ["＄"]),
            ("€", ["¥", "￥", "$", "＄", "€", "₿", "£", "¤"]),
        ]
        for (index, item) in secondRow.enumerated() {
            keys[position(index * 2, 1)] = inputKey(
                item.0,
                variations: item.1
            )
        }

        keys[position(0, 2, width: 3)] = tabKey(
            label: .systemImage("textformat.123"),
            destination: .qwerty_numbers
        )
        let punctuation: [(String, [String])] = [
            (".", ["。", "."]),
            (",", ["、", ","]),
            ("?", ["？", "?"]),
            ("!", ["！", "!"]),
            ("…", []),
        ]
        for (item, geometry) in zip(punctuation, punctuationGeometry) {
            keys[position(geometry.x, 2, width: geometry.width)] = inputKey(
                item.0,
                variations: item.1
            )
        }
        keys[position(17, 2, width: 3)] = deleteKey

        addBottomRow(
            to: &keys,
            leadingKey: .system(.qwertyLanguageSwitch),
            spaceLabel: "空白"
        )
        return custard(
            identifier: "symbols_qwerty",
            displayName: "記号QWERTY",
            language: .none,
            inputStyle: .direct,
            keys: keys
        )
    }

    private static func custard(
        identifier: String,
        displayName: String,
        language: CustardLanguage,
        inputStyle: CustardInputStyle,
        keys: [CustardKeyPositionSpecifier: CustardInterfaceKey]
    ) -> Custard {
        Custard(
            identifier: identifier,
            language: language,
            input_style: inputStyle,
            metadata: .init(
                custard_version: .v1_2,
                display_name: displayName
            ),
            interface: .init(
                keyStyle: .pcStyle,
                keyLayout: layout,
                keys: keys
            )
        )
    }

    private static func letterKeys(
        secondRowTrailingKey: CustardInterfaceKey
    ) -> [CustardKeyPositionSpecifier: CustardInterfaceKey] {
        var keys: [CustardKeyPositionSpecifier: CustardInterfaceKey] = [:]
        for (index, letter) in ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"].enumerated() {
            keys[position(index * 2, 0)] = inputKey(letter)
        }
        for (index, letter) in ["a", "s", "d", "f", "g", "h", "j", "k", "l"].enumerated() {
            keys[position(index * 2, 1)] = inputKey(letter)
        }
        keys[position(18, 1)] = secondRowTrailingKey
        return keys
    }

    private static func addThirdRowLetters(
        to keys: inout [CustardKeyPositionSpecifier: CustardInterfaceKey]
    ) {
        for (index, letter) in ["z", "x", "c", "v", "b", "n", "m"].enumerated() {
            keys[position(3 + index * 2, 2)] = inputKey(letter)
        }
        keys[position(17, 2, width: 3)] = deleteKey
    }

    private static func addBottomRow(
        to keys: inout [CustardKeyPositionSpecifier: CustardInterfaceKey],
        leadingKey: CustardInterfaceKey,
        spaceLabel: String
    ) {
        keys[position(0, 3, width: 3)] = leadingKey
        keys[position(3, 3, width: 3)] = .system(.changeKeyboard)
        keys[position(6, 3, width: 8)] = spaceKey(label: spaceLabel)
        keys[position(14, 3, width: 6)] = .system(.enter)
    }

    private static func inputKey(
        _ input: String,
        variations: [String] = []
    ) -> CustardInterfaceKey {
        .custom(
            .init(
                design: .init(label: .text(input), color: .normal),
                press_actions: [.input(input)],
                longpress_actions: .none,
                variations: variations.map { variation in
                    .init(
                        type: .longpressVariation,
                        key: .init(
                            design: .init(label: .text(variation)),
                            press_actions: [.input(variation)],
                            longpress_actions: .none
                        )
                    )
                }
            )
        )
    }

    private static func tabKey(
        label: CustardKeyLabelStyle,
        destination: TabData.SystemTab
    ) -> CustardInterfaceKey {
        .custom(
            .init(
                design: .init(label: label, color: .special),
                press_actions: [.moveTab(.system(destination))],
                longpress_actions: .init(start: [.toggleTabBar]),
                variations: []
            )
        )
    }

    private static func spaceKey(label: String) -> CustardInterfaceKey {
        .custom(
            .init(
                design: .init(label: .text(label), color: .normal),
                press_actions: [.input(" ")],
                longpress_actions: .init(start: [.toggleCursorBar]),
                variations: []
            )
        )
    }

    private static var deleteKey: CustardInterfaceKey {
        .custom(
            .init(
                design: .init(
                    label: .systemImage("delete.left"),
                    color: .special
                ),
                press_actions: [.delete(1)],
                longpress_actions: .init(repeat: [.delete(1)]),
                variations: []
            )
        )
    }

    private static let punctuationGeometry: [(x: Int, width: Int)] = [
        (3, 3),
        (6, 3),
        (9, 2),
        (11, 3),
        (14, 3),
    ]

    private static func position(
        _ x: Int,
        _ y: Int,
        width: Int = 2
    ) -> CustardKeyPositionSpecifier {
        .gridFit(
            .init(
                x: x,
                y: y,
                width: width
            )
        )
    }
}
