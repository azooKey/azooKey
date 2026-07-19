import CustardKit

public extension Custard {
    static let qwertyJapanese = DefaultQwertyCustards.japanese
    static let qwertyEnglish = DefaultQwertyCustards.english
    static let qwertyNumbers = DefaultQwertyCustards.numbers
    static let qwertySymbols = DefaultQwertyCustards.symbols
}

private enum DefaultQwertyCustards {
    /// Custardのgrid-fitは整数座標のみ対応するため、標準QWERTYの小数座標を2倍して近似する。
    private static let horizontalScale = 2.0
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
        keys[position(0, 2, width: 1.4)] = languageKey(
            primary: "日",
            secondary: "英",
            destination: .user_english
        )
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
        keys[position(0, 2, width: 1.4)] = languageKey(
            primary: "英",
            secondary: "日",
            destination: .user_japanese
        )
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
            keys[position(Double(index), 0)] = inputKey(
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
            keys[position(Double(index), 1)] = inputKey(
                item.0,
                variations: item.1
            )
        }

        keys[position(0, 2, width: 1.4)] = tabKey(
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
        keys[position(8.6, 2, width: 1.4)] = deleteKey

        addBottomRow(
            to: &keys,
            leadingKey: languageKey(
                primary: "日",
                secondary: "英",
                destination: .user_japanese
            ),
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
            keys[position(Double(index), 0)] = inputKey(
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
            keys[position(Double(index), 1)] = inputKey(
                item.0,
                variations: item.1
            )
        }

        keys[position(0, 2, width: 1.4)] = tabKey(
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
        keys[position(8.6, 2, width: 1.4)] = deleteKey

        addBottomRow(
            to: &keys,
            leadingKey: languageKey(
                primary: "日",
                secondary: "英",
                destination: .user_japanese
            ),
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
            keys[position(Double(index), 0)] = inputKey(letter)
        }
        for (index, letter) in ["a", "s", "d", "f", "g", "h", "j", "k", "l"].enumerated() {
            keys[position(Double(index), 1)] = inputKey(letter)
        }
        keys[position(9, 1)] = secondRowTrailingKey
        return keys
    }

    private static func addThirdRowLetters(
        to keys: inout [CustardKeyPositionSpecifier: CustardInterfaceKey]
    ) {
        for (index, letter) in ["z", "x", "c", "v", "b", "n", "m"].enumerated() {
            keys[position(1.5 + Double(index), 2)] = inputKey(letter)
        }
        keys[position(8.6, 2, width: 1.4)] = deleteKey
    }

    private static func addBottomRow(
        to keys: inout [CustardKeyPositionSpecifier: CustardInterfaceKey],
        leadingKey: CustardInterfaceKey,
        spaceLabel: String
    ) {
        keys[position(0, 3, width: 1.5)] = leadingKey
        keys[position(1.5, 3, width: 1.5)] = .system(.changeKeyboard)
        keys[position(3, 3, width: 4.5)] = spaceKey(label: spaceLabel)
        keys[position(7.5, 3, width: 2.5)] = .system(.enter)
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

    private static func languageKey(
        primary: String,
        secondary: String,
        destination: TabData.SystemTab
    ) -> CustardInterfaceKey {
        .custom(
            .init(
                design: .init(
                    label: .mainAndSub(primary, secondary),
                    color: .special
                ),
                press_actions: [.moveTab(.system(destination))],
                longpress_actions: .none,
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

    private static let punctuationGeometry: [(x: Double, width: Double)] = [
        (1.5, 1.5),
        (3, 1.5),
        (4.5, 1),
        (5.5, 1.5),
        (7, 1.5),
    ]

    private static func position(
        _ x: Double,
        _ y: Int,
        width: Double = 1
    ) -> CustardKeyPositionSpecifier {
        .gridFit(
            .init(
                x: Int((x * horizontalScale).rounded()),
                y: y,
                width: Int((width * horizontalScale).rounded())
            )
        )
    }
}
