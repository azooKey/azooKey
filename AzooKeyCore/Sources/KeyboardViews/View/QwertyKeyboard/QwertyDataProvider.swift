//
//  VerticalQwertyKeyboardModel.swift
//  Keyboard
//
//  Created by ensan on 2020/09/18.
//  Copyright © 2020 ensan. All rights reserved.
//

import Foundation
import enum CustardKit.TabData

struct QwertyDataProvider<Extension: ApplicationSpecificKeyboardViewExtension> {
    @MainActor static func tabKeys() -> (languageKey: any QwertyKeyModelProtocol<Extension>, numbersKey: any QwertyKeyModelProtocol<Extension>, symbolsKey: any QwertyKeyModelProtocol<Extension>, changeKeyboardKey: any QwertyKeyModelProtocol<Extension>) {
        let preferredLanguage = Extension.SettingProvider.preferredLanguage
        let languageKey: any QwertyKeyModelProtocol<Extension>
        let first = preferredLanguage.first
        if let second = preferredLanguage.second {
            languageKey = QwertySwitchLanguageKeyModel(languages: (first, second))
        } else {
            let targetTab: TabData = switch first {
            case .en_US:
                .system(.user_english)
            case .ja_JP:
                .system(.user_japanese)
            case .none, .el_GR:
                .system(.user_japanese)
            }
            languageKey = QwertyFunctionalKeyModel(labelType: .text(first.symbol), pressActions: [.moveTab(targetTab)], longPressActions: .none, needSuggestView: false)
        }

        let numbersKey: any QwertyKeyModelProtocol<Extension> = QwertyFunctionalKeyModel(labelType: .image("textformat.123"), pressActions: [.moveTab(.system(.qwerty_numbers))], longPressActions: .init(start: [.setTabBar(.toggle)]))
        let symbolsKey: any QwertyKeyModelProtocol<Extension> = QwertyFunctionalKeyModel(labelType: .text("#+="), pressActions: [.moveTab(.system(.qwerty_symbols))], longPressActions: .init(start: [.setTabBar(.toggle)]))
        let changeKeyboardKey: any QwertyKeyModelProtocol<Extension> = if let second = preferredLanguage.second {
            QwertyConditionalKeyModel(needSuggestView: false, unpressedKeyBackground: .special) { states in
                if SemiStaticStates.shared.needsInputModeSwitchKey {
                    // 地球儀キーが必要な場合
                    return switch states.tabManager.existentialTab() {
                    case .qwerty_abc:
                        // 英語ではシフトを押したら地球儀キーを表示
                        // leftbottom以外のケースでもこちらを表示する
                        if shiftBehaviorPreference != .leftbottom || (states.boolStates.isShifted || states .boolStates.isCapsLocked) {
                            QwertyChangeKeyboardKeyModel()
                        } else {
                            numbersKey
                        }
                    default:
                        QwertyChangeKeyboardKeyModel()
                    }
                } else {
                    // 普通のキーで良い場合
                    let targetTab: TabData = switch second {
                    case .en_US:
                        .system(.user_english)
                    case .ja_JP, .none, .el_GR:
                        .system(.user_japanese)
                    }
                    return switch states.tabManager.existentialTab() {
                    case .qwerty_hira:
                        symbolsKey
                    case .qwerty_abc:
                        // 英語ではシフトを押したら#+=キーを表示
                        // leftbottom以外のケースでもこちらを表示する
                        if shiftBehaviorPreference != .leftbottom || (states.boolStates.isShifted || states .boolStates.isCapsLocked) {
                            symbolsKey
                        } else {
                            numbersKey
                        }
                    case .qwerty_numbers, .qwerty_symbols:
                        QwertyFunctionalKeyModel(labelType: .text(second.symbol), pressActions: [.moveTab(targetTab)])
                    default:
                        QwertyFunctionalKeyModel(labelType: .image("arrowtriangle.left.and.line.vertical.and.arrowtriangle.right"), pressActions: [.setCursorBar(.toggle)])
                    }
                }
            }
        } else {
            QwertyConditionalKeyModel(needSuggestView: false, unpressedKeyBackground: .special) { _ in
                if SemiStaticStates.shared.needsInputModeSwitchKey {
                    // 地球儀キーが必要な場合
                    QwertyChangeKeyboardKeyModel()
                } else {
                    QwertyFunctionalKeyModel(labelType: .image("arrowtriangle.left.and.line.vertical.and.arrowtriangle.right"), pressActions: [.setCursorBar(.toggle)])
                }
            }
        }
        return (
            languageKey: languageKey,
            numbersKey: numbersKey,
            symbolsKey: symbolsKey,
            changeKeyboardKey: changeKeyboardKey
        )
    }

    private enum ShiftBehaviorPreference {
        /// Version 2.2.3から導入。シフトキーは左下に配置
        ///  - 2.2.3以降に初めてシフトキーを使い始めた人はデフォルトでこちら
        ///  - iOS 18以降は全員こちら
        case leftbottom
        /// Version 2.2で導入したが、不評なので挙動を変える予定
        ///  - 2.2.3より前に初めてシフトキーを使い始めた人はこちら
        ///  - ただしiOS 18以降ではこのオプションを削除する
        case left
        /// シフトは使わない（デフォルト）
        case off
    }

    @MainActor
    private static var shiftBehaviorPreference: ShiftBehaviorPreference {
        if #available(iOS 18, *) {
            if Extension.SettingProvider.useShiftKey {
                .leftbottom
            } else {
                .off
            }
        } else {
            if Extension.SettingProvider.useShiftKey {
                if Extension.SettingProvider.keepDeprecatedShiftKeyBehavior {
                    .left
                } else {
                    .leftbottom
                }
            } else {
                .off
            }
        }
    }

    @MainActor static func spaceKey() -> any QwertyKeyModelProtocol<Extension> {
        Extension.SettingProvider.useNextCandidateKey ? QwertyNextCandidateKeyModel() : QwertySpaceKeyModel()
    }

    // 横に並べる
    @MainActor static var numberKeyboard: [QwertyPositionSpecifier: any QwertyKeyModelProtocol<Extension>] {
        var keys: [QwertyPositionSpecifier: any QwertyKeyModelProtocol<Extension>] = [
            .init(x: 0, y: 0): QwertyKeyModel(
                labelType: .text("1"),
                pressActions: [.input("1")],
                variationsModel: QwertyVariationsModel([
                    (label: .text("1"), actions: [.input("1")] ),
                    (label: .text("１"), actions: [.input("１")] ),
                    (label: .text("一"), actions: [.input("一")] ),
                    (label: .text("①"), actions: [.input("①")] ),
                ], direction: .right)
            ),
            .init(x: 1, y: 0): QwertyKeyModel(
                labelType: .text("2"),
                pressActions: [.input("2")],
                variationsModel: QwertyVariationsModel([
                    (label: .text("2"), actions: [.input("2")] ),
                    (label: .text("２"), actions: [.input("２")] ),
                    (label: .text("二"), actions: [.input("二")] ),
                    (label: .text("②"), actions: [.input("②")] ),
                ], direction: .right)
            ),
            .init(x: 2, y: 0): QwertyKeyModel(
                labelType: .text("3"),
                pressActions: [.input("3")],
                variationsModel: QwertyVariationsModel([
                    (label: .text("3"), actions: [.input("3")] ),
                    (label: .text("３"), actions: [.input("３")] ),
                    (label: .text("三"), actions: [.input("三")] ),
                    (label: .text("③"), actions: [.input("③")] ),
                ])
            ),
            .init(x: 3, y: 0): QwertyKeyModel(
                labelType: .text("4"),
                pressActions: [.input("4")],
                variationsModel: QwertyVariationsModel([
                    (label: .text("4"), actions: [.input("4")] ),
                    (label: .text("４"), actions: [.input("４")] ),
                    (label: .text("四"), actions: [.input("四")] ),
                    (label: .text("④"), actions: [.input("④")] ),
                ])
            ),
            .init(x: 4, y: 0): QwertyKeyModel(
                labelType: .text("5"),
                pressActions: [.input("5")],
                variationsModel: QwertyVariationsModel([
                    (label: .text("5"), actions: [.input("5")] ),
                    (label: .text("５"), actions: [.input("５")] ),
                    (label: .text("五"), actions: [.input("五")] ),
                    (label: .text("⑤"), actions: [.input("⑤")] ),
                ])
            ),
            .init(x: 5, y: 0): QwertyKeyModel(
                labelType: .text("6"),
                pressActions: [.input("6")],
                variationsModel: QwertyVariationsModel([
                    (label: .text("6"), actions: [.input("6")] ),
                    (label: .text("６"), actions: [.input("６")] ),
                    (label: .text("六"), actions: [.input("六")] ),
                    (label: .text("⑥"), actions: [.input("⑥")] ),
                ])
            ),
            .init(x: 6, y: 0): QwertyKeyModel(
                labelType: .text("7"),
                pressActions: [.input("7")],
                variationsModel: QwertyVariationsModel([
                    (label: .text("7"), actions: [.input("7")] ),
                    (label: .text("７"), actions: [.input("７")] ),
                    (label: .text("七"), actions: [.input("七")] ),
                    (label: .text("⑦"), actions: [.input("⑦")] ),
                ])
            ),
            .init(x: 7, y: 0): QwertyKeyModel(
                labelType: .text("8"),
                pressActions: [.input("8")],
                variationsModel: QwertyVariationsModel([
                    (label: .text("8"), actions: [.input("8")] ),
                    (label: .text("８"), actions: [.input("８")] ),
                    (label: .text("八"), actions: [.input("八")] ),
                    (label: .text("⑧"), actions: [.input("⑧")] ),
                ])
            ),
            .init(x: 8, y: 0): QwertyKeyModel(
                labelType: .text("9"),
                pressActions: [.input("9")],
                variationsModel: QwertyVariationsModel([
                    (label: .text("9"), actions: [.input("9")] ),
                    (label: .text("９"), actions: [.input("９")] ),
                    (label: .text("九"), actions: [.input("九")] ),
                    (label: .text("⑨"), actions: [.input("⑨")] ),
                ], direction: .left)
            ),
            .init(x: 9, y: 0): QwertyKeyModel(
                labelType: .text("0"),
                pressActions: [.input("0")],
                variationsModel: QwertyVariationsModel([
                    (label: .text("0"), actions: [.input("0")] ),
                    (label: .text("０"), actions: [.input("０")] ),
                    (label: .text("〇"), actions: [.input("〇")] ),
                    (label: .text("⓪"), actions: [.input("⓪")] ),
                ], direction: .left)
            ),

            .init(x: 0, y: 1): QwertyKeyModel(labelType: .text("-"), pressActions: [.input("-")]),
            .init(x: 1, y: 1): QwertyKeyModel(
                labelType: .text("/"),
                pressActions: [.input("/")],
                variationsModel: QwertyVariationsModel([
                    (label: .text("/"), actions: [.input("/")] ),
                    (label: .text("\\"), actions: [.input("\\")] ),
                ])
            ),
            .init(x: 2, y: 1): QwertyKeyModel(
                labelType: .text(":"),
                pressActions: [.input(":")],
                variationsModel: QwertyVariationsModel([
                    (label: .text(":"), actions: [.input(":")] ),
                    (label: .text("："), actions: [.input("：")] ),
                    (label: .text(";"), actions: [.input(";")] ),
                    (label: .text("；"), actions: [.input("；")] ),
                ])
            ),
            .init(x: 3, y: 1): QwertyKeyModel(
                labelType: .text("@"),
                pressActions: [.input("@")],
                variationsModel: QwertyVariationsModel([
                    (label: .text("@"), actions: [.input("@")] ),
                    (label: .text("＠"), actions: [.input("＠")] ),
                ])
            ),
            .init(x: 4, y: 1): QwertyKeyModel(labelType: .text("("), pressActions: [.input("(")]),
            .init(x: 5, y: 1): QwertyKeyModel(labelType: .text(")"), pressActions: [.input(")")]),
            .init(x: 6, y: 1): QwertyKeyModel(
                labelType: .text("「"),
                pressActions: [.input("「")],
                variationsModel: QwertyVariationsModel([
                    (label: .text("「"), actions: [.input("「")] ),
                    (label: .text("『"), actions: [.input("『")] ),
                    (label: .text("【"), actions: [.input("【")] ),
                    (label: .text("（"), actions: [.input("（")] ),
                    (label: .text("《"), actions: [.input("《")] ),
                ])
            ),
            .init(x: 7, y: 1): QwertyKeyModel(
                labelType: .text("」"),
                pressActions: [.input("」")],
                variationsModel: QwertyVariationsModel([
                    (label: .text("」"), actions: [.input("」")] ),
                    (label: .text("』"), actions: [.input("』")] ),
                    (label: .text("】"), actions: [.input("】")] ),
                    (label: .text("）"), actions: [.input("）")] ),
                    (label: .text("》"), actions: [.input("》")] ),
                ])
            ),
            .init(x: 8, y: 1): QwertyKeyModel(
                labelType: .text("¥"),
                pressActions: [.input("¥")],
                variationsModel: QwertyVariationsModel([
                    (label: .text("¥"), actions: [.input("¥")] ),
                    (label: .text("￥"), actions: [.input("￥")] ),
                    (label: .text("$"), actions: [.input("$")] ),
                    (label: .text("＄"), actions: [.input("＄")] ),
                    (label: .text("€"), actions: [.input("€")] ),
                    (label: .text("₿"), actions: [.input("₿")] ),
                    (label: .text("£"), actions: [.input("£")] ),
                    (label: .text("¤"), actions: [.input("¤")] ),
                ], direction: .left)
            ),
            .init(x: 9, y: 1): QwertyKeyModel(
                labelType: .text("&"),
                pressActions: [.input("&")],
                variationsModel: QwertyVariationsModel([
                    (label: .text("&"), actions: [.input("&")]),
                    (label: .text("＆"), actions: [.input("＆")]),
                ], direction: .left)
            ),
            .init(x: 0, y: 2, width: 1.4): Self.tabKeys().symbolsKey,
            // 1.25...8.75までの領域を渡す
            .init(x: 8.6, y: 2, width: 1.4): QwertyFunctionalKeyModel.delete,

            .init(x: 0, y: 3, width: 1.4): Self.tabKeys().languageKey,
            .init(x: 1.4, y: 3, width: 1.4): Self.tabKeys().changeKeyboardKey,
            .init(x: 2.8, y: 3, width: 4.4): Self.spaceKey(),
            .init(x: 7.2, y: 3, width: 2.8): QwertyEnterKeyModel.shared,
        ]
        let customKeys = Extension.SettingProvider.numberTabCustomKeysSetting.compiled(extension: Extension.self)
        for (i, item) in customKeys.enumerated() {
            // 1.5 ... 8.5の7キー分のスペースを利用できる
            let x = 1.5 + Double(i) / Double(customKeys.count) * 7
            let y = 2.0
            let width = 7 / Double(customKeys.count)
            keys[.init(x: x, y: y, width: width)] = item
        }
        return keys
    }
    // 横に並べる
    @MainActor static func symbolsKeyboard() -> [QwertyPositionSpecifier: any QwertyKeyModelProtocol<Extension>] {[
        .init(x: 0, y: 0): QwertyKeyModel(
            labelType: .text("["),
            pressActions: [.input("[")],
            variationsModel: QwertyVariationsModel([
                (label: .text("["), actions: [.input("[")]),
                (label: .text("［"), actions: [.input("［")]),
            ], direction: .right)
        ),
        .init(x: 1, y: 0): QwertyKeyModel(
            labelType: .text("]"),
            pressActions: [.input("]")],
            variationsModel: QwertyVariationsModel([
                (label: .text("]"), actions: [.input("]")]),
                (label: .text("］"), actions: [.input("］")]),
            ])
        ),
        .init(x: 2, y: 0): QwertyKeyModel(
            labelType: .text("{"),
            pressActions: [.input("{")],
            variationsModel: QwertyVariationsModel([
                (label: .text("{"), actions: [.input("{")]),
                (label: .text("｛"), actions: [.input("｛")]),
            ])
        ),
        .init(x: 3, y: 0): QwertyKeyModel(
            labelType: .text("}"),
            pressActions: [.input("}")],
            variationsModel: QwertyVariationsModel([
                (label: .text("}"), actions: [.input("}")]),
                (label: .text("｝"), actions: [.input("｝")]),
            ])
        ),
        .init(x: 4, y: 0): QwertyKeyModel(
            labelType: .text("#"),
            pressActions: [.input("#")],
            variationsModel: QwertyVariationsModel([
                (label: .text("#"), actions: [.input("#")]),
                (label: .text("＃"), actions: [.input("＃")]),
            ])
        ),
        .init(x: 5, y: 0): QwertyKeyModel(
            labelType: .text("%"),
            pressActions: [.input("%")],
            variationsModel: QwertyVariationsModel([
                (label: .text("%"), actions: [.input("%")]),
                (label: .text("％"), actions: [.input("％")]),
            ])
        ),
        .init(x: 6, y: 0): QwertyKeyModel(
            labelType: .text("^"),
            pressActions: [.input("^")],
            variationsModel: QwertyVariationsModel([
                (label: .text("^"), actions: [.input("^")]),
                (label: .text("＾"), actions: [.input("＾")]),
            ])
        ),
        .init(x: 7, y: 0): QwertyKeyModel(
            labelType: .text("*"),
            pressActions: [.input("*")],
            variationsModel: QwertyVariationsModel([
                (label: .text("*"), actions: [.input("*")]),
                (label: .text("＊"), actions: [.input("＊")]),
            ])
        ),
        .init(x: 8, y: 0): QwertyKeyModel(
            labelType: .text("+"),
            pressActions: [.input("+")],
            variationsModel: QwertyVariationsModel([
                (label: .text("+"), actions: [.input("+")]),
                (label: .text("＋"), actions: [.input("＋")]),
                (label: .text("±"), actions: [.input("±")]),
            ])
        ),
        .init(x: 9, y: 0): QwertyKeyModel(
            labelType: .text("="),
            pressActions: [.input("=")],
            variationsModel: QwertyVariationsModel([
                (label: .text("="), actions: [.input("=")]),
                (label: .text("＝"), actions: [.input("＝")]),
                (label: .text("≡"), actions: [.input("≡")]),
                (label: .text("≒"), actions: [.input("≒")]),
                (label: .text("≠"), actions: [.input("≠")]),
            ], direction: .left)
        ),

        .init(x: 0, y: 1): QwertyKeyModel(labelType: .text("_"), pressActions: [.input("_")]),
        .init(x: 1, y: 1): QwertyKeyModel(
            labelType: .text("\\"),
            pressActions: [.input("\\")],
            variationsModel: QwertyVariationsModel([
                (label: .text("/"), actions: [.input("/")] ),
                (label: .text("\\"), actions: [.input("\\")] ),
            ])
        ),
        .init(x: 2, y: 1): QwertyKeyModel(
            labelType: .text(";"),
            pressActions: [.input(";")],
            variationsModel: QwertyVariationsModel([
                (label: .text(":"), actions: [.input(":")] ),
                (label: .text("："), actions: [.input("：")] ),
                (label: .text(";"), actions: [.input(";")] ),
                (label: .text("；"), actions: [.input("；")] ),
            ])
        ),
        .init(x: 3, y: 1): QwertyKeyModel(
            labelType: .text("|"),
            pressActions: [.input("|")],
            variationsModel: QwertyVariationsModel([
                (label: .text("|"), actions: [.input("|")] ),
                (label: .text("｜"), actions: [.input("｜")] ),
            ])
        ),
        .init(x: 4, y: 1): QwertyKeyModel(
            labelType: .text("<"),
            pressActions: [.input("<")],
            variationsModel: QwertyVariationsModel([
                (label: .text("<"), actions: [.input("<")]),
                (label: .text("＜"), actions: [.input("＜")]),
            ])
        ),
        .init(x: 5, y: 1): QwertyKeyModel(
            labelType: .text(">"),
            pressActions: [.input(">")],
            variationsModel: QwertyVariationsModel([
                (label: .text(">"), actions: [.input(">")]),
                (label: .text("＞"), actions: [.input("＞")]),
            ])
        ),
        .init(x: 6, y: 1): QwertyKeyModel(
            labelType: .text("\""),
            pressActions: [.input("\"")],
            variationsModel: QwertyVariationsModel([
                (label: .text("\""), actions: [.input("\"")]),
                (label: .text("＂"), actions: [.input("＂")]),
                (label: .text("“"), actions: [.input("“")]),
                (label: .text("”"), actions: [.input("”")]),
            ])
        ),
        .init(x: 7, y: 1): QwertyKeyModel(
            labelType: .text("'"),
            pressActions: [.input("'")],
            variationsModel: QwertyVariationsModel([
                (label: .text("'"), actions: [.input("'")]),
                (label: .text("`"), actions: [.input("`")]),
            ])
        ),
        .init(x: 8, y: 1): QwertyKeyModel(
            labelType: .text("$"),
            pressActions: [.input("$")],
            variationsModel: QwertyVariationsModel([
                (label: .text("$"), actions: [.input("$")]),
                (label: .text("＄"), actions: [.input("＄")]),
            ])
        ),
        .init(x: 9, y: 1): QwertyKeyModel(
            labelType: .text("€"),
            pressActions: [.input("€")],
            variationsModel: QwertyVariationsModel([
                (label: .text("¥"), actions: [.input("¥")] ),
                (label: .text("￥"), actions: [.input("￥")] ),
                (label: .text("$"), actions: [.input("$")] ),
                (label: .text("＄"), actions: [.input("＄")] ),
                (label: .text("€"), actions: [.input("€")] ),
                (label: .text("₿"), actions: [.input("₿")] ),
                (label: .text("£"), actions: [.input("£")] ),
                (label: .text("¤"), actions: [.input("¤")] ),
            ], direction: .left)
        ),
        .init(x: 0, y: 2, width: 1.4): Self.tabKeys().numbersKey,
        .init(x: 1.5 + 7 / 5 * 0, y: 2, width: 7 / 5): QwertyKeyModel(
            labelType: .text("."),
            pressActions: [.input(".")],
            variationsModel: QwertyVariationsModel([
                (label: .text("。"), actions: [.input("。")] ),
                (label: .text("."), actions: [.input(".")] ),
            ]),
            ),
        .init(x: 1.5 + 7 / 5 * 1, y: 2, width: 7 / 5): QwertyKeyModel(
            labelType: .text(","),
            pressActions: [.input(",")],
            variationsModel: QwertyVariationsModel([
                (label: .text("、"), actions: [.input("、")] ),
                (label: .text(","), actions: [.input(",")] ),
            ]),
            ),
        .init(x: 1.5 + 7 / 5 * 2, y: 2, width: 7 / 5): QwertyKeyModel(
            labelType: .text("?"),
            pressActions: [.input("?")],
            variationsModel: QwertyVariationsModel([
                (label: .text("？"), actions: [.input("？")] ),
                (label: .text("?"), actions: [.input("?")] ),
            ]),
            ),
        .init(x: 1.5 + 7 / 5 * 3, y: 2, width: 7 / 5): QwertyKeyModel(
            labelType: .text("!"),
            pressActions: [.input("!")],
            variationsModel: QwertyVariationsModel([
                (label: .text("！"), actions: [.input("！")] ),
                (label: .text("!"), actions: [.input("!")] ),
            ]),
            ),
        .init(x: 1.5 + 7 / 5 * 4, y: 2, width: 7 / 5): QwertyKeyModel(labelType: .text("…"), pressActions: [.input("…")]),
        .init(x: 8.6, y: 2, width: 1.4): QwertyFunctionalKeyModel.delete,

        .init(x: 0, y: 3, width: 1.4): Self.tabKeys().languageKey,
        .init(x: 1.4, y: 3, width: 1.4): Self.tabKeys().changeKeyboardKey,
        .init(x: 2.8, y: 3, width: 4.4): Self.spaceKey(),
        .init(x: 7.2, y: 3, width: 2.8): QwertyEnterKeyModel.shared,
    ]}

    // 横に並べる
    @MainActor static func hiraKeyboard() -> [QwertyPositionSpecifier: any QwertyKeyModelProtocol<Extension>] {[
        .init(x: 0, y: 0): QwertyKeyModel(labelType: .text("q"), pressActions: [.input("q")]),
        .init(x: 1, y: 0): QwertyKeyModel(labelType: .text("w"), pressActions: [.input("w")]),
        .init(x: 2, y: 0): QwertyKeyModel(labelType: .text("e"), pressActions: [.input("e")]),
        .init(x: 3, y: 0): QwertyKeyModel(labelType: .text("r"), pressActions: [.input("r")]),
        .init(x: 4, y: 0): QwertyKeyModel(labelType: .text("t"), pressActions: [.input("t")]),
        .init(x: 5, y: 0): QwertyKeyModel(labelType: .text("y"), pressActions: [.input("y")]),
        .init(x: 6, y: 0): QwertyKeyModel(labelType: .text("u"), pressActions: [.input("u")]),
        .init(x: 7, y: 0): QwertyKeyModel(labelType: .text("i"), pressActions: [.input("i")]),
        .init(x: 8, y: 0): QwertyKeyModel(labelType: .text("o"), pressActions: [.input("o")]),
        .init(x: 9, y: 0): QwertyKeyModel(labelType: .text("p"), pressActions: [.input("p")]),
        .init(x: 0, y: 1): QwertyKeyModel(labelType: .text("a"), pressActions: [.input("a")]),
        .init(x: 1, y: 1): QwertyKeyModel(labelType: .text("s"), pressActions: [.input("s")]),
        .init(x: 2, y: 1): QwertyKeyModel(labelType: .text("d"), pressActions: [.input("d")]),
        .init(x: 3, y: 1): QwertyKeyModel(labelType: .text("f"), pressActions: [.input("f")]),
        .init(x: 4, y: 1): QwertyKeyModel(labelType: .text("g"), pressActions: [.input("g")]),
        .init(x: 5, y: 1): QwertyKeyModel(labelType: .text("h"), pressActions: [.input("h")]),
        .init(x: 6, y: 1): QwertyKeyModel(labelType: .text("j"), pressActions: [.input("j")]),
        .init(x: 7, y: 1): QwertyKeyModel(labelType: .text("k"), pressActions: [.input("k")]),
        .init(x: 8, y: 1): QwertyKeyModel(labelType: .text("l"), pressActions: [.input("l")]),
        .init(x: 9, y: 1): QwertyKeyModel(
            labelType: .text("ー"),
            pressActions: [.input("ー")],
            variationsModel: QwertyVariationsModel(
                [
                    (label: .text("ー"), actions: [.input("ー")]),
                    (label: .text("。"), actions: [.input("。")]),
                    (label: .text("、"), actions: [.input("、")]),
                    (label: .text("！"), actions: [.input("！")]),
                    (label: .text("？"), actions: [.input("？")]),
                    (label: .text("・"), actions: [.input("・")]),
                ],
                direction: .left
            )
        ),

        .init(x: 0, y: 2, width: 1.4): Self.tabKeys().languageKey,
        .init(x: 1.5, y: 2): QwertyKeyModel(labelType: .text("z"), pressActions: [.input("z")]),
        .init(x: 2.5, y: 2): QwertyKeyModel(labelType: .text("x"), pressActions: [.input("x")]),
        .init(x: 3.5, y: 2): QwertyKeyModel(labelType: .text("c"), pressActions: [.input("c")]),
        .init(x: 4.5, y: 2): QwertyKeyModel(labelType: .text("v"), pressActions: [.input("v")]),
        .init(x: 5.5, y: 2): QwertyKeyModel(labelType: .text("b"), pressActions: [.input("b")]),
        .init(x: 6.5, y: 2): QwertyKeyModel(labelType: .text("n"), pressActions: [.input("n")]),
        .init(x: 7.5, y: 2): QwertyKeyModel(labelType: .text("m"), pressActions: [.input("m")]),
        .init(x: 8.6, y: 2, width: 1.4): QwertyFunctionalKeyModel.delete,

        .init(x: 0, y: 3, width: 1.4): Self.tabKeys().numbersKey,
        .init(x: 1.4, y: 3, width: 1.4): Self.tabKeys().changeKeyboardKey,
        .init(x: 2.8, y: 3, width: 4.4): Self.spaceKey(),
        .init(x: 7.2, y: 3, width: 2.8): QwertyEnterKeyModel.shared,

    ]}

    // 横に並べる
    @MainActor static func abcKeyboard() -> [QwertyPositionSpecifier: any QwertyKeyModelProtocol<Extension>] {
        var keys: [QwertyPositionSpecifier: any QwertyKeyModelProtocol<Extension>] = [
            .init(x: 0, y: 0): QwertyKeyModel(labelType: .text("q"), pressActions: [.input("q")]),
            .init(x: 1, y: 0): QwertyKeyModel(labelType: .text("w"), pressActions: [.input("w")]),
            .init(x: 2, y: 0): QwertyKeyModel(labelType: .text("e"), pressActions: [.input("e")]),
            .init(x: 3, y: 0): QwertyKeyModel(labelType: .text("r"), pressActions: [.input("r")]),
            .init(x: 4, y: 0): QwertyKeyModel(labelType: .text("t"), pressActions: [.input("t")]),
            .init(x: 5, y: 0): QwertyKeyModel(labelType: .text("y"), pressActions: [.input("y")]),
            .init(x: 6, y: 0): QwertyKeyModel(labelType: .text("u"), pressActions: [.input("u")]),
            .init(x: 7, y: 0): QwertyKeyModel(labelType: .text("i"), pressActions: [.input("i")]),
            .init(x: 8, y: 0): QwertyKeyModel(labelType: .text("o"), pressActions: [.input("o")]),
            .init(x: 9, y: 0): QwertyKeyModel(labelType: .text("p"), pressActions: [.input("p")]),

            .init(x: 0, y: 2, width: 1.4): Self.tabKeys().languageKey,
            .init(x: 1.5, y: 2): QwertyKeyModel(labelType: .text("z"), pressActions: [.input("z")]),
            .init(x: 2.5, y: 2): QwertyKeyModel(labelType: .text("x"), pressActions: [.input("x")]),
            .init(x: 3.5, y: 2): QwertyKeyModel(labelType: .text("c"), pressActions: [.input("c")]),
            .init(x: 4.5, y: 2): QwertyKeyModel(labelType: .text("v"), pressActions: [.input("v")]),
            .init(x: 5.5, y: 2): QwertyKeyModel(labelType: .text("b"), pressActions: [.input("b")]),
            .init(x: 6.5, y: 2): QwertyKeyModel(labelType: .text("n"), pressActions: [.input("n")]),
            .init(x: 7.5, y: 2): QwertyKeyModel(labelType: .text("m"), pressActions: [.input("m")]),
            .init(x: 8.6, y: 2, width: 1.4): QwertyFunctionalKeyModel.delete,
            // left, offの場合は単にnumbersKeyを表示し、leftbottomの場合はシフトキーをこの位置に表示する
            .init(x: 0, y: 3, width: 1.4): {switch shiftBehaviorPreference {
            case .left, .off: Self.tabKeys().numbersKey
            case .leftbottom: QwertyShiftKeyModel()
            }}(),
            .init(x: 1.4, y: 3, width: 1.4): Self.tabKeys().changeKeyboardKey,
            .init(x: 2.8, y: 3, width: 4.4): Self.spaceKey(),
            .init(x: 7.2, y: 3, width: 2.8): QwertyEnterKeyModel.shared,
        ]

        // offの場合は一番右にAaキーを、leftの場合は一番左にShiftキーを、leftbottomの場合は一番右にピリオドキーを置く
        let core: [any QwertyKeyModelProtocol<Extension>] = [
            QwertyKeyModel(labelType: .text("a"), pressActions: [.input("a")]),
            QwertyKeyModel(labelType: .text("s"), pressActions: [.input("s")]),
            QwertyKeyModel(labelType: .text("d"), pressActions: [.input("d")]),
            QwertyKeyModel(labelType: .text("f"), pressActions: [.input("f")]),
            QwertyKeyModel(labelType: .text("g"), pressActions: [.input("g")]),
            QwertyKeyModel(labelType: .text("h"), pressActions: [.input("h")]),
            QwertyKeyModel(labelType: .text("j"), pressActions: [.input("j")]),
            QwertyKeyModel(labelType: .text("k"), pressActions: [.input("k")]),
            QwertyKeyModel(labelType: .text("l"), pressActions: [.input("l")]),
        ]
        let keys_1 = switch shiftBehaviorPreference {
        case .leftbottom:
            core + [QwertyKeyModel(
                labelType: .text("."),
                pressActions: [.input(".")],
                variationsModel: QwertyVariationsModel(
                    [
                        (label: .text("."), actions: [.input(".")]),
                        (label: .text(","), actions: [.input(",")]),
                        (label: .text("!"), actions: [.input("!")]),
                        (label: .text("?"), actions: [.input("?")]),
                        (label: .text("'"), actions: [.input("'")]),
                        (label: .text("\""), actions: [.input("\"")]),
                    ],
                    direction: .left
                )
            ), ]
        case .left:
            [QwertyShiftKeyModel.shared] + core
        case .off:
            core + [QwertyAaKeyModel.shared]
        }
        for (i, key) in keys_1.enumerated() {
            keys[.init(x: Double(i), y: 1)] = key
        }
        return keys
    }
}
