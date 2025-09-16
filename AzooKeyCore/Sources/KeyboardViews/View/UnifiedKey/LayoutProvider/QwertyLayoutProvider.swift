import CustardKit
import Foundation

struct QwertyLayoutProvider<Extension: ApplicationSpecificKeyboardViewExtension> {
    enum ShiftBehaviorPreference {
        case left
        case leftbottom
        case off
    }
    @MainActor private static func spaceKey() -> any UnifiedKeyModelProtocol<Extension> {
        Extension.SettingProvider.useNextCandidateKey
            ? QwertyNextCandidateKeyModel<Extension>()
            : QwertySpaceKeyModel<Extension>()
    }
    @MainActor static func shiftBehaviorPreference() -> ShiftBehaviorPreference {
        if #available(iOS 18, *) {
            // iOS 18+ uses new behavior: bottom-left shift when enabled
            return Extension.SettingProvider.useShiftKey ? .leftbottom : .off
        } else {
            if Extension.SettingProvider.useShiftKey {
                return Extension.SettingProvider.keepDeprecatedShiftKeyBehavior ? .left : .leftbottom
            } else {
                return .off
            }
        }
    }
    @MainActor private static func tabKeys() -> (
        languageKey: any UnifiedKeyModelProtocol<Extension>,
        numbersKey: any UnifiedKeyModelProtocol<Extension>,
        symbolsKey: any UnifiedKeyModelProtocol<Extension>,
        changeKeyboardKey: any UnifiedKeyModelProtocol<Extension>
    ) {
        // language key
        let languageKey: any UnifiedKeyModelProtocol<Extension> = QwertyLanguageSwitchKeyModel<Extension>(languages: (.ja_JP, .en_US))
        // numbers key
        let numbersKey: any UnifiedKeyModelProtocol<Extension> = QwertyGeneralKeyModel(
            labelType: .image("textformat.123"),
            pressActions: { _ in [.moveTab(.system(.qwerty_numbers))] },
            longPressActions: { _ in .init(start: [.setTabBar(.toggle)]) },
            variations: [], direction: .right, showsTapBubble: false, role: .special
        )
        // symbols key
        let symbolsKey: any UnifiedKeyModelProtocol<Extension> = QwertyGeneralKeyModel(
            labelType: .text("#+="),
            pressActions: { _ in [.moveTab(.system(.qwerty_symbols))] },
            longPressActions: { _ in .init(start: [.setTabBar(.toggle)]) },
            variations: [], direction: .right, showsTapBubble: false, role: .special
        )
        // change keyboard key (dynamic)
        let changeKeyboardKey: any UnifiedKeyModelProtocol<Extension> = QwertyDynamicChangeKeyModel<Extension>()
        return (languageKey, numbersKey, symbolsKey, changeKeyboardKey)
    }
    @MainActor static var numberKeyboard: [UnifiedPositionSpecifier: any UnifiedKeyModelProtocol<Extension>] {
        func uniKey(label: KeyLabelType, press: [ActionType], vars: [QwertyVariationsModel.VariationElement], dir: VariationsViewDirection = .center, showsBubble: Bool = true, role: QwertyGeneralKeyModel<Extension>.UnpressedRole = .normal) -> any UnifiedKeyModelProtocol<Extension> {
            QwertyGeneralKeyModel<Extension>(
                labelType: label,
                pressActions: { _ in press },
                longPressActions: { _ in .none },
                variations: vars,
                direction: dir,
                showsTapBubble: showsBubble,
                role: role
            )
        }
        func v(_ s: String) -> QwertyVariationsModel.VariationElement { .init(label: .text(s), actions: [.input(s)]) }
        var dict: [UnifiedPositionSpecifier: any UnifiedKeyModelProtocol<Extension>] = [:]
        // Top row: 1..0 with common variations
        dict[.init(x: 0, y: 0)] = uniKey(label: .text("1"), press: [.input("1")], vars: [v("1"), v("１"), v("一"), v("①")], dir: .right)
        dict[.init(x: 1, y: 0)] = uniKey(label: .text("2"), press: [.input("2")], vars: [v("2"), v("２"), v("二"), v("②")], dir: .right)
        dict[.init(x: 2, y: 0)] = uniKey(label: .text("3"), press: [.input("3")], vars: [v("3"), v("３"), v("三"), v("③")])
        dict[.init(x: 3, y: 0)] = uniKey(label: .text("4"), press: [.input("4")], vars: [v("4"), v("４"), v("四"), v("④")])
        dict[.init(x: 4, y: 0)] = uniKey(label: .text("5"), press: [.input("5")], vars: [v("5"), v("５"), v("五"), v("⑤")])
        dict[.init(x: 5, y: 0)] = uniKey(label: .text("6"), press: [.input("6")], vars: [v("6"), v("６"), v("六"), v("⑥")])
        dict[.init(x: 6, y: 0)] = uniKey(label: .text("7"), press: [.input("7")], vars: [v("7"), v("７"), v("七"), v("⑦")])
        dict[.init(x: 7, y: 0)] = uniKey(label: .text("8"), press: [.input("8")], vars: [v("8"), v("８"), v("八"), v("⑧")])
        dict[.init(x: 8, y: 0)] = uniKey(label: .text("9"), press: [.input("9")], vars: [v("9"), v("９"), v("九"), v("⑨")], dir: .left)
        dict[.init(x: 9, y: 0)] = uniKey(label: .text("0"), press: [.input("0")], vars: [v("0"), v("０"), v("〇"), v("⓪")], dir: .left)

        // 2nd row (legacy parity)
        dict[.init(x: 0, y: 1)] = uniKey(label: .text("-"), press: [.input("-")], vars: [])
        dict[.init(x: 1, y: 1)] = uniKey(label: .text("/"), press: [.input("/")], vars: [v("/"), v("\\")])
        dict[.init(x: 2, y: 1)] = uniKey(label: .text(":"), press: [.input(":")], vars: [v(":"), v("："), v(";"), v("；")])
        dict[.init(x: 3, y: 1)] = uniKey(label: .text("@"), press: [.input("@")], vars: [v("@"), v("＠")])
        dict[.init(x: 4, y: 1)] = uniKey(label: .text("("), press: [.input("(")], vars: [])
        dict[.init(x: 5, y: 1)] = uniKey(label: .text(")"), press: [.input(")")], vars: [])
        dict[.init(x: 6, y: 1)] = uniKey(label: .text("「"), press: [.input("「")], vars: [v("「"), v("『"), v("【"), v("（"), v("《")])
        dict[.init(x: 7, y: 1)] = uniKey(label: .text("」"), press: [.input("」")], vars: [v("」"), v("』"), v("】"), v("）"), v("》")])
        dict[.init(x: 8, y: 1)] = uniKey(label: .text("¥"), press: [.input("¥")], vars: [v("¥"), v("￥"), v("$"), v("＄"), v("€"), v("₿"), v("£"), v("¤")], dir: .left)
        dict[.init(x: 9, y: 1)] = uniKey(label: .text("&"), press: [.input("&")], vars: [v("&"), v("＆")], dir: .left)

        // 3rd row: symbols key + punctuation cluster + delete
        dict[.init(x: 0, y: 2, width: 1.4)] = tabKeys().symbolsKey
        // Middle cluster: custom keys if provided (variable count), otherwise fixed 5-slot defaults
        do {
            let defaults = [
                (name: ".", actions: [ActionType.input(".")], vars: [".", ",", "!", "?", "'", "\""] as [String]),
                (name: ",", actions: [ActionType.input(",")], vars: [] as [String]),
                (name: "?", actions: [ActionType.input("?")], vars: [] as [String]),
                (name: "!", actions: [ActionType.input("!")], vars: [] as [String]),
                (name: "…", actions: [ActionType.input("…")], vars: [] as [String]),
            ]
            let custom = Extension.SettingProvider.numberTabCustomKeysSetting.keys
            if !custom.isEmpty {
                let count = custom.count
                let w = 7.0 / Double(count)
                for (i, k) in custom.enumerated() {
                    let x = 1.5 + Double(i) * w
                    let vars = k.longpresses.map { QwertyVariationsModel.VariationElement(label: .text($0.name), actions: $0.actions.map { $0.actionType }) }
                    dict[.init(x: x, y: 2, width: w)] = QwertyGeneralKeyModel(
                        labelType: .text(k.name),
                        pressActions: { _ in k.actions.map { $0.actionType } },
                        longPressActions: { _ in .none },
                        variations: vars,
                        direction: .center,
                        showsTapBubble: !vars.isEmpty,
                        role: .normal
                    )
                }
            } else {
                for (i, d) in defaults.enumerated() {
                    let x = 1.5 + Double(i) * (7.0 / 5.0)
                    let vars = d.vars.map { QwertyVariationsModel.VariationElement(label: .text($0), actions: [.input($0)]) }
                    dict[.init(x: x, y: 2, width: 7.0 / 5.0)] = QwertyGeneralKeyModel(
                        labelType: .text(d.name),
                        pressActions: { _ in d.actions },
                        longPressActions: { _ in .none },
                        variations: vars,
                        direction: .center,
                        showsTapBubble: !vars.isEmpty,
                        role: .normal
                    )
                }
            }
        }
        dict[.init(x: 8.6, y: 2, width: 1.4, height: 1)] = QwertyGeneralKeyModel<Extension>(
            labelType: .image("delete.left"),
            pressActions: { _ in [.delete(1)] },
            longPressActions: { _ in .init(repeat: [.delete(1)]) },
            variations: [], direction: .right, showsTapBubble: false, role: .special
        )

        // 4th row: bottom controls (language and dynamic change)
        let tabs = tabKeys()
        dict[.init(x: 0, y: 3, width: 1.4)] = tabs.languageKey
        dict[.init(x: 1.4, y: 3, width: 1.4)] = tabs.changeKeyboardKey
        dict[.init(x: 2.8, y: 3, width: 4.4)] = spaceKey()
        dict[.init(x: 7.2, y: 3, width: 2.8)] = UnifiedEnterKeyModel<Extension>(textSize: .small)

        return dict
    }

    @MainActor static func hiraKeyboard() -> [UnifiedPositionSpecifier: any UnifiedKeyModelProtocol<Extension>] {
        func key(_ x: Double, _ y: Double, _ t: String) -> (UnifiedPositionSpecifier, any UnifiedKeyModelProtocol<Extension>) {
            (.init(x: x, y: y), QwertyGeneralKeyModel(labelType: .text(t), pressActions: { _ in [.input(t)] }, longPressActions: { _ in .none }, variations: [], direction: .right, showsTapBubble: true, role: .normal))
        }
        func barKey() -> any UnifiedKeyModelProtocol<Extension> {
            QwertyGeneralKeyModel(
                labelType: .text("ー"),
                pressActions: { _ in [.input("ー")] },
                longPressActions: { _ in .none },
                variations: [
                    .init(label: .text("ー"), actions: [.input("ー")]),
                    .init(label: .text("。"), actions: [.input("。")]),
                    .init(label: .text("、"), actions: [.input("、")]),
                    .init(label: .text("！"), actions: [.input("！")]),
                    .init(label: .text("？"), actions: [.input("？")]),
                    .init(label: .text("・"), actions: [.input("・")]),
                ],
                direction: .left,
                showsTapBubble: true,
                role: .normal
            )
        }
        var dict: [UnifiedPositionSpecifier: any UnifiedKeyModelProtocol<Extension>] = [:]
        // Row 0
        for (i, c) in ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"].enumerated() {
            let (pos, mdl) = key(Double(i), 0, c)
            dict[pos] = mdl
        }
        // Row 1 letters + bar key at end
        for (i, c) in ["a", "s", "d", "f", "g", "h", "j", "k", "l"].enumerated() {
            let (pos, mdl) = key(Double(i), 1, c)
            dict[pos] = mdl
        }
        dict[.init(x: 9, y: 1)] = barKey()

        // Row 2: language key at left, then letters, and delete
        let tabs = tabKeys()
        dict[.init(x: 0, y: 2, width: 1.4)] = tabs.languageKey
        for (i, c) in ["z", "x", "c", "v", "b", "n", "m"].enumerated() {
            let (pos, mdl) = key(1.5 + Double(i), 2, c)
            dict[pos] = mdl
        }
        dict[.init(x: 8.6, y: 2, width: 1.4)] = QwertyGeneralKeyModel(
            labelType: .image("delete.left"), pressActions: { _ in [.delete(1)] }, longPressActions: { _ in .init(repeat: [.delete(1)]) }, variations: [], direction: .right, showsTapBubble: false, role: .special
        )

        // Row 3: hiragana layout never shows Shift; always numbers key at left
        dict[.init(x: 0, y: 3, width: 1.4)] = tabs.numbersKey
        dict[.init(x: 1.4, y: 3, width: 1.4)] = tabs.changeKeyboardKey
        dict[.init(x: 2.8, y: 3, width: 4.4)] = spaceKey()
        dict[.init(x: 7.2, y: 3, width: 2.8)] = UnifiedEnterKeyModel<Extension>(textSize: .small)
        return dict
    }

    @MainActor static func abcKeyboard() -> [UnifiedPositionSpecifier: any UnifiedKeyModelProtocol<Extension>] {
        func key(_ x: Double, _ y: Double, _ t: String) -> (UnifiedPositionSpecifier, any UnifiedKeyModelProtocol<Extension>) {
            (.init(x: x, y: y), QwertyGeneralKeyModel(labelType: .text(t), pressActions: { _ in [.input(t)] }, longPressActions: { _ in .none }, variations: [], direction: .right, showsTapBubble: true, role: .normal))
        }
        func dotKey() -> any UnifiedKeyModelProtocol<Extension> {
            QwertyGeneralKeyModel(
                labelType: .text("."),
                pressActions: { _ in [.input(".")] },
                longPressActions: { _ in .none },
                variations: [
                    .init(label: .text("."), actions: [.input(".")]),
                    .init(label: .text(","), actions: [.input(",")]),
                    .init(label: .text("!"), actions: [.input("!")]),
                    .init(label: .text("?"), actions: [.input("?")]),
                    .init(label: .text("'"), actions: [.input("'")]),
                    .init(label: .text("\""), actions: [.input("\"")]),
                ],
                direction: .left,
                showsTapBubble: true,
                role: .normal
            )
        }

        var dict: [UnifiedPositionSpecifier: any UnifiedKeyModelProtocol<Extension>] = [:]
        // Row 0
        for (i, c) in ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"].enumerated() {
            let (pos, mdl) = key(Double(i), 0, c)
            dict[pos] = mdl
        }
        // Row 1 core letters
        let core = ["a", "s", "d", "f", "g", "h", "j", "k", "l"].enumerated()
        switch shiftBehaviorPreference() {
        case .leftbottom:
            // No shift on row1; place core letters and dot key at end
            for (i, c) in core {
                let (pos, mdl) = key(Double(i), 1, c)
                dict[pos] = mdl
            }
            dict[.init(x: 9, y: 1)] = dotKey()
        case .left:
            dict[.init(x: 0, y: 1)] = QwertyShiftKeyModel<Extension>()
            for (i, c) in core {
                let (pos, mdl) = key(Double(i + 1), 1, c)
                dict[pos] = mdl
            }
        case .off:
            for (i, c) in core {
                let (pos, mdl) = key(Double(i), 1, c)
                dict[pos] = mdl
            }
            dict[.init(x: 9, y: 1)] = QwertyAaKeyModel<Extension>()
        }
        // Row 2: language key at left, then letters, and delete
        let tabsAbc = tabKeys()
        dict[.init(x: 0, y: 2, width: 1.4)] = tabsAbc.languageKey
        for (i, c) in ["z", "x", "c", "v", "b", "n", "m"].enumerated() {
            let (pos, mdl) = key(1.5 + Double(i), 2, c)
            dict[pos] = mdl
        }
        dict[.init(x: 8.6, y: 2, width: 1.4)] = QwertyGeneralKeyModel(
            labelType: .image("delete.left"),
            pressActions: { _ in [.delete(1)] },
            longPressActions: { _ in .init(repeat: [.delete(1)]) },
            variations: [], direction: .right, showsTapBubble: false, role: .special
        )
        // Row 3: numbers or shift at left, and dynamic change key next
        switch shiftBehaviorPreference() {
        case .leftbottom:
            dict[.init(x: 0, y: 3, width: 1.4)] = QwertyShiftKeyModel<Extension>()
        default:
            dict[.init(x: 0, y: 3, width: 1.4)] = tabsAbc.numbersKey
        }
        dict[.init(x: 1.4, y: 3, width: 1.4)] = tabsAbc.changeKeyboardKey
        dict[.init(x: 2.8, y: 3, width: 4.4)] = spaceKey()
        dict[.init(x: 7.2, y: 3, width: 2.8)] = UnifiedEnterKeyModel<Extension>(textSize: .small)
        return dict
    }

    @MainActor static func symbolsKeyboard() -> [UnifiedPositionSpecifier: any UnifiedKeyModelProtocol<Extension>] {
        func uni(_ x: Double, _ y: Double, _ label: String, vars: [String] = [], dir: VariationsViewDirection = .right) -> (UnifiedPositionSpecifier, any UnifiedKeyModelProtocol<Extension>) {
            let v = vars.map { QwertyVariationsModel.VariationElement(label: .text($0), actions: [.input($0)]) }
            return (.init(x: x, y: y), QwertyGeneralKeyModel(labelType: .text(label), pressActions: { _ in [.input(label)] }, longPressActions: { _ in .none }, variations: v, direction: dir, showsTapBubble: !v.isEmpty, role: .normal))
        }
        var dict: [UnifiedPositionSpecifier: any UnifiedKeyModelProtocol<Extension>] = [:]
        // Row 0
        for (i, spec) in [
            ("[", ["［"]), ("]", ["］"]), ("{", ["｛"]), ("}", ["｝"]), ("#", ["＃"]), ("%", ["％"]), ("^", ["＾"]), ("*", ["＊"]), ("+", ["＋", "±"]), ("=", ["＝", "≡", "≒", "≠"])].enumerated() {
            let (pos, mdl) = uni(Double(i), 0, spec.0, vars: spec.1, dir: i == 9 ? .left : .right)
            dict[pos] = mdl
        }
        // Row 1
        let row1 = [
            (0.0, "_", []), (1.0, "\\", ["/", "\\"]), (2.0, ";", [":", "：", ";", "；"]), (3.0, "|", ["｜"]), (4.0, "<", ["＜"]), (5.0, ">", ["＞"]), (6.0, "\"", ["＂", "“", "”"]), (7.0, "'", ["`"]), (8.0, "$", ["＄"]), (9.0, "€", ["¥", "￥", "$", "＄", "€", "₿", "£", "¤"]) ]
        for item in row1 {
            let (pos, mdl) = uni(item.0, 1, item.1, vars: item.2, dir: item.0 == 9.0 ? .left : .right)
            dict[pos] = mdl
        }
        // Row 2: numbers key at left, then fixed 5-slot punctuation cluster with width 7/5
        let tabs = tabKeys()
        dict[.init(x: 0, y: 2, width: 1.4)] = tabs.numbersKey
        let punctSpecs: [(String, [String])] = [
            (".", ["。", "."]),
            (",", ["、", ","]),
            ("?", ["？", "?"]),
            ("!", ["！", "!"]),
            ("…", []),
        ]
        for (i, spec) in punctSpecs.enumerated() {
            let x = 1.5 + Double(i) * (7.0 / 5.0)
            let vars = spec.1.map { QwertyVariationsModel.VariationElement(label: .text($0), actions: [.input($0)]) }
            dict[.init(x: x, y: 2, width: 7.0 / 5.0)] = QwertyGeneralKeyModel(labelType: .text(spec.0), pressActions: { _ in [.input(spec.0)] }, longPressActions: { _ in .none }, variations: vars, direction: .center, showsTapBubble: !vars.isEmpty, role: .normal)
        }
        dict[.init(x: 8.6, y: 2, width: 1.4)] = QwertyGeneralKeyModel(labelType: .image("delete.left"), pressActions: { _ in [.delete(1)] }, longPressActions: { _ in .init(repeat: [.delete(1)]) }, variations: [], direction: .right, showsTapBubble: false, role: .special)
        // Row 3
        dict[.init(x: 0, y: 3, width: 1.4)] = tabs.languageKey
        dict[.init(x: 1.4, y: 3, width: 1.4)] = tabs.changeKeyboardKey
        dict[.init(x: 2.8, y: 3, width: 4.4)] = spaceKey()
        dict[.init(x: 7.2, y: 3, width: 2.8)] = UnifiedEnterKeyModel<Extension>()
        return dict
    }
}
