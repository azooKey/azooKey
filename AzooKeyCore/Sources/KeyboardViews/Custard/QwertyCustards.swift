import CustardKit

public extension Custard {
    static let qwertyJapanese = DefaultQwertyCustards.japanese
    static let qwertyEnglish = DefaultQwertyCustards.english(
        shiftKeyPlacement: .none
    )
    static let qwertyNumbers = DefaultQwertyCustards.numbers(
        customKeys: .defaultValue
    )
    static let qwertySymbols = DefaultQwertyCustards.symbols

    static func qwertyEnglish(useShiftKey: Bool) -> Custard {
        DefaultQwertyCustards.english(
            shiftKeyPlacement: useShiftKey ? .bottom : .none
        )
    }

    static func qwertyEnglish(
        useShiftKey: Bool,
        useDeprecatedShiftKeyBehavior: Bool
    ) -> Custard {
        let shiftKeyPlacement: DefaultQwertyCustards.ShiftKeyPlacement
        if useShiftKey {
            shiftKeyPlacement = useDeprecatedShiftKeyBehavior ? .left : .bottom
        } else {
            shiftKeyPlacement = .none
        }
        return DefaultQwertyCustards.english(
            shiftKeyPlacement: shiftKeyPlacement
        )
    }

    static func qwertyNumbers(customKeys: QwertyCustomKeysValue) -> Custard {
        DefaultQwertyCustards.numbers(customKeys: customKeys)
    }
}

private enum DefaultQwertyCustards {
    enum ShiftKeyPlacement: Equatable {
        case none
        case left
        case bottom
    }

    private static let layout = CustardInterfaceLayout.gridFit(
        .init(rowCount: 10, columnCount: 4)
    )

    static var japanese: Custard {
        var keys = letterKeys(
            secondRowTrailingKey: inputKey(
                "ー",
                variations: ["ー", "。", "、", "！", "？", "・"]
            )
        )
        keys[position(0, 2, width: 1.4)] = .system(.qwertyLanguageSwitch)
        addThirdRowLetters(to: &keys)
        addBottomRow(
            to: &keys,
            leadingKey: tabKey(
                label: .systemImage("textformat.123"),
                destination: .qwerty_numbers
            )
        )
        return custard(
            identifier: "japanese_qwerty",
            displayName: "日本語QWERTY",
            language: .ja_JP,
            inputStyle: .roman2kana,
            keys: keys
        )
    }

    static func english(shiftKeyPlacement: ShiftKeyPlacement) -> Custard {
        let secondRowTrailingKey: CustardInterfaceKey? = if shiftKeyPlacement == .bottom {
            inputKey(
                ".",
                variations: [".", ",", "!", "?", "'", "\""]
            )
        } else if shiftKeyPlacement == .none {
            .system(.upperLower)
        } else {
            nil
        }
        let secondRowLeadingKey: CustardInterfaceKey? =
            shiftKeyPlacement == .left ? .system(.qwertyShift) : nil
        var keys = letterKeys(
            secondRowLeadingKey: secondRowLeadingKey,
            secondRowTrailingKey: secondRowTrailingKey
        )
        keys[position(0, 2, width: 1.4)] = .system(.qwertyLanguageSwitch)
        addThirdRowLetters(to: &keys)
        addBottomRow(
            to: &keys,
            leadingKey: shiftKeyPlacement == .bottom
                ? .system(.qwertyShift)
                : tabKey(
                    label: .systemImage("textformat.123"),
                    destination: .qwerty_numbers
                )
        )
        return custard(
            identifier: "english_qwerty",
            displayName: "英語QWERTY",
            language: .en_US,
            inputStyle: .direct,
            keys: keys
        )
    }

    static func numbers(customKeys: QwertyCustomKeysValue) -> Custard {
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
        let middleKeys = customKeys.keys.isEmpty
            ? QwertyCustomKeysValue.defaultValue.keys
            : customKeys.keys
        let middleKeyWidth = 7.0 / Double(middleKeys.count)
        for (index, key) in middleKeys.enumerated() {
            keys[
                position(
                    1.5 + Double(index) * middleKeyWidth,
                    2,
                    width: middleKeyWidth
                )
            ] = customInputKey(
                label: key.name,
                actions: key.actions,
                variations: key.longpresses
            )
        }
        keys[position(8.6, 2, width: 1.4)] = deleteKey

        addBottomRow(
            to: &keys,
            leadingKey: .system(.qwertyLanguageSwitch)
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
            leadingKey: .system(.qwertyLanguageSwitch)
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
        secondRowLeadingKey: CustardInterfaceKey? = nil,
        secondRowTrailingKey: CustardInterfaceKey? = nil
    ) -> [CustardKeyPositionSpecifier: CustardInterfaceKey] {
        var keys: [CustardKeyPositionSpecifier: CustardInterfaceKey] = [:]
        for (index, letter) in ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"].enumerated() {
            keys[position(Double(index), 0)] = inputKey(letter)
        }
        if let secondRowLeadingKey {
            keys[position(0, 1)] = secondRowLeadingKey
        }
        let secondRowOffset = secondRowLeadingKey == nil ? 0.0 : 1.0
        for (index, letter) in ["a", "s", "d", "f", "g", "h", "j", "k", "l"].enumerated() {
            keys[position(secondRowOffset + Double(index), 1)] = inputKey(letter)
        }
        if let secondRowTrailingKey {
            keys[position(9, 1)] = secondRowTrailingKey
        }
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
        leadingKey: CustardInterfaceKey
    ) {
        keys[position(0, 3, width: 1.4)] = leadingKey
        keys[position(1.4, 3, width: 1.4)] = .system(.qwertyDynamicChange)
        keys[position(2.8, 3, width: 4.4)] = .system(.qwertySpace)
        keys[position(7.2, 3, width: 2.8)] = .system(.enter)
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

    private static func customInputKey(
        label: String,
        actions: [CodableActionData],
        variations: [QwertyVariationKey]
    ) -> CustardInterfaceKey {
        .custom(
            .init(
                design: .init(label: .text(label), color: .normal),
                press_actions: actions,
                longpress_actions: .none,
                variations: variations.map { variation in
                    .init(
                        type: .longpressVariation,
                        key: .init(
                            design: .init(label: .text(variation.name)),
                            press_actions: variation.actions,
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
        (1.5, 1.4),
        (2.9, 1.4),
        (4.3, 1.4),
        (5.7, 1.4),
        (7.1, 1.4),
    ]

    private static func position(
        _ x: Double,
        _ y: Int,
        width: Double = 1
    ) -> CustardKeyPositionSpecifier {
        .gridFit(
            .init(
                x: x,
                y: Double(y),
                width: width
            )
        )
    }
}
