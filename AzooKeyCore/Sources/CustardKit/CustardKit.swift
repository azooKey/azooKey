//
//  CustardKit.swift
//
//  Created by ensan on 2021/03/13.
//  Copyright © 2021 ensan. All rights reserved.
//

import Foundation

extension Encodable {
    func containerEncode<CodingKeys: CodingKey>(container: inout KeyedEncodingContainer<CodingKeys>, key: CodingKeys) throws {
        try container.encode(self, forKey: key)
    }
}

/// - 変換対象の言語を指定します。
/// - specify language to convert
public enum CustardLanguage: String, Codable, Sendable {
    /// - 英語(アメリカ)に変換します
    /// - convert to American English
    case en_US

    /// - 日本語(共通語)に変換します
    /// - convert to common Japanese
    case ja_JP

    /// - ギリシア語に変換します
    /// - convert to Greek
    case el_GR

    /// - 変換を行いません
    /// - don't convert
    case none

    /// - 特に変換する言語を指定しません
    /// - don't specify
    case undefined
}

/// - 入力方式を指定します。
/// - specify input style
public enum CustardInputStyle: String, Codable, Sendable {
    /// - 入力された文字をそのまま用います
    /// - use inputted characters directly
    case direct

    /// - 入力されたローマ字を仮名に変換して用います
    /// - use roman-kana conversion
    case roman2kana
}

/// - カスタードのバージョンを指定します。
/// - specify custard version
public enum CustardVersion: String, Codable, Sendable {
    case v1_0 = "1.0"
    case v1_1 = "1.1"
    case v1_2 = "1.2"
}

public struct CustardMetadata: Codable, Equatable, Sendable {
    public init(custard_version: CustardVersion, display_name: String) {
        self.custard_version = custard_version
        self.display_name = display_name
    }

    /// version
    public var custard_version: CustardVersion

    /// display name
    /// - used in tab bar
    public var display_name: String
}

public struct Custard: Codable, Equatable, Sendable {
    public init(identifier: String, language: CustardLanguage, input_style: CustardInputStyle, metadata: CustardMetadata, interface: CustardInterface) {
        self.identifier = identifier
        self.language = language
        self.input_style = input_style
        self.metadata = metadata
        self.interface = interface
    }

    /// identifier
    /// - must be unique
    public var identifier: String

    /// language to convert
    public var language: CustardLanguage

    /// input style
    public var input_style: CustardInputStyle

    /// metadata
    public var metadata: CustardMetadata

    /// interface
    public var interface: CustardInterface

    public func write(to url: URL) throws {
        let encoded_data = try JSONEncoder().encode(self)
        try encoded_data.write(to: url)
    }
}

extension Array where Element == Custard {
    public func write(to url: URL) throws {
        let encoded_data = try JSONEncoder().encode(self)
        try encoded_data.write(to: url)
    }
}

/// - インターフェースのキーのスタイルです
/// - style of keys
public enum CustardInterfaceStyle: String, Codable, Sendable {
    /// - フリック可能なキー
    /// - flickable keys
    case tenkeyStyle = "tenkey_style"

    /// - 長押しで他の文字を選べるキー
    /// - keys with variations
    case pcStyle = "pc_style"
}

/// - インターフェースのレイアウトのスタイルです
/// - style of layout
public enum CustardInterfaceLayout: Codable, Equatable, Sendable {
    /// - 画面いっぱいにマス目状で均等に配置されます
    /// - keys are evenly layouted in a grid pattern fitting to the screen
    case gridFit(CustardInterfaceLayoutGridValue)

    /// - はみ出した分はスクロールできる形でマス目状に均等に配置されます
    /// - keys are layouted in a scrollable grid pattern and can be overflown
    case gridScroll(CustardInterfaceLayoutScrollValue)
}

public extension CustardInterfaceLayout {
    private enum CodingKeys: CodingKey {
        case type
        case row_count, column_count
        case direction
    }
    private enum ValueType: String, Codable {
        case grid_fit
        case grid_scroll
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .gridFit(value):
            try container.encode(ValueType.grid_fit, forKey: .type)
            try container.encode(value.rowCount, forKey: .row_count)
            try container.encode(value.columnCount, forKey: .column_count)
        case let .gridScroll(value):
            try container.encode(ValueType.grid_scroll, forKey: .type)
            try container.encode(value.direction, forKey: .direction)
            try container.encode(value.rowCount, forKey: .row_count)
            try container.encode(value.columnCount, forKey: .column_count)
        }
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ValueType.self, forKey: .type)
        let rowCount = try container.decode(Double.self, forKey: .row_count)
        let columnCount = try container.decode(Double.self, forKey: .column_count)
        switch type {
        case .grid_fit:
            self = .gridFit(.init(rowCount: Int(rowCount), columnCount: Int(columnCount)))
        case .grid_scroll:
            let direction = try container.decode(CustardInterfaceLayoutScrollValue.ScrollDirection.self, forKey: .direction)
            self = .gridScroll(.init(direction: direction, rowCount: rowCount, columnCount: columnCount))
        }
    }
}

public struct CustardInterfaceLayoutGridValue: Equatable, Sendable {
    public init(rowCount: Int, columnCount: Int) {
        self.rowCount = rowCount
        self.columnCount = columnCount
    }

    /// - 横方向に配置するキーの数
    /// - number of keys placed horizontally
    public var rowCount: Int
    /// - 縦方向に配置するキーの数
    /// - number of keys placed vertically
    public var columnCount: Int
}

public struct CustardInterfaceLayoutScrollValue: Equatable, Sendable {
    public init(direction: ScrollDirection, rowCount: Double, columnCount: Double) {
        self.direction = direction
        self.rowCount = rowCount
        self.columnCount = columnCount
    }

    /// - スクロールの方向
    /// - direction of scroll
    public var direction: ScrollDirection

    /// - 一列に配置するキーの数
    /// - number of keys in scroll normal direction
    public var rowCount: Double

    /// - 画面内に収まるスクロール方向のキーの数
    /// - number of keys in screen in scroll direction
    public var columnCount: Double

    /// - direction of scroll
    public enum ScrollDirection: String, Codable, Sendable {
        case vertical
        case horizontal
    }
}

/// - 画面内でのキーの位置を決める指定子
/// - the specifier of key's position in screen
public enum CustardKeyPositionSpecifier: Hashable, Sendable {
    /// - gridFitのレイアウトを利用した際のキーの位置指定子
    /// - position specifier when you use grid fit layout
    case gridFit(GridFitPositionSpecifier)

    /// - gridScrollのレイアウトを利用した際のキーの位置指定子
    /// - position specifier when you use grid scroll layout
    case gridScroll(GridScrollPositionSpecifier)
}

/// - gridFitのレイアウトを利用した際のキーの位置指定子に与える値
/// - values in position specifier when you use grid fit layout
public struct GridFitPositionSpecifier: Codable, Hashable, Sendable {
    public init(x: Double, y: Double, width: Double = 1, height: Double = 1) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    /// - 横方向の位置(左をゼロとする)
    /// - horizontal position (leading edge is zero)
    public var x: Double

    /// - 縦方向の位置(上をゼロとする)
    /// - vertical positon (top edge is zero)
    public var y: Double

    public var width: Double
    public var height: Double

    private enum CodingKeys: CodingKey {
        case x, y, width, height
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.x = try container.decode(Double.self, forKey: .x)
        self.y = try container.decode(Double.self, forKey: .y)
        let width = try container.decode(Double.self, forKey: .width)
        let height = try container.decode(Double.self, forKey: .height)
        (self.width, self.height) = (abs(width), abs(height))
    }
}

/// - gridScrollのレイアウトを利用した際のキーの位置指定子に与える値
/// - values in position specifier when you use grid scroll layout
public struct GridScrollPositionSpecifier: Codable, Hashable, ExpressibleByIntegerLiteral, Sendable {
    /// - 通し番号
    /// - index
    public var index: Int

    public init(_ index: Int) {
        self.index = index
    }
}

/// - 記述の簡便化のため定義
/// - conforms to protocol for writability
public extension GridScrollPositionSpecifier {
    typealias IntegerLiteralType = Int

    init(integerLiteral value: Int) {
        self.index = value
    }
}

/// - インターフェース
/// - interface
public struct CustardInterface: Codable, Equatable, Sendable {
    public init(keyStyle: CustardInterfaceStyle, keyLayout: CustardInterfaceLayout, keys: [CustardKeyPositionSpecifier: CustardInterfaceKey]) {
        self.keyStyle = keyStyle
        self.keyLayout = keyLayout
        self.keys = keys
    }

    /// - キーのスタイル
    /// - style of keys
    /// - warning: Currently when you use gird scroll. layout, key style would be ignored.
    public var keyStyle: CustardInterfaceStyle

    /// - キーのレイアウト
    /// - layout of keys
    public var keyLayout: CustardInterfaceLayout

    /// - キーの辞書
    /// - dictionary of keys
    /// - warning: You must use specifiers consistent with key layout. When you use inconsistent one, it would be ignored.
    public var keys: [CustardKeyPositionSpecifier: CustardInterfaceKey]
}

public extension CustardInterface {
    private enum CodingKeys: CodingKey {
        case key_style
        case key_layout
        case keys
    }

    private enum KeyType: String, Codable {
        case custom, system
    }

    private enum SpecifierType: String, Codable {
        case grid_fit, grid_scroll
    }

    private struct Element: Codable {
        init(specifier: CustardKeyPositionSpecifier, key: CustardInterfaceKey) {
            self.specifier = specifier
            self.key = key
        }

        let specifier: CustardKeyPositionSpecifier
        let key: CustardInterfaceKey

        private var specifierType: SpecifierType {
            switch self.specifier {
            case .gridFit: return .grid_fit
            case .gridScroll: return .grid_scroll
            }
        }

        private var keyType: KeyType {
            switch self.key {
            case .system: return .system
            case .custom: return .custom
            }
        }

        private enum CodingKeys: CodingKey {
            case specifier_type
            case specifier
            case key_type
            case key
        }

        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(specifierType, forKey: .specifier_type)
            switch self.specifier {
            case let .gridFit(value as any Encodable),
                 let .gridScroll(value as any Encodable):
                try value.containerEncode(container: &container, key: CodingKeys.specifier)
            }
            try container.encode(keyType, forKey: .key_type)
            switch self.key {
            case let .system(value as any Encodable),
                 let .custom(value as any Encodable):
                try value.containerEncode(container: &container, key: CodingKeys.key)
            }
        }

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let specifierType = try container.decode(SpecifierType.self, forKey: .specifier_type)
            switch specifierType {
            case .grid_fit:
                let specifier = try container.decode(GridFitPositionSpecifier.self, forKey: .specifier)
                self.specifier = .gridFit(specifier)
            case .grid_scroll:
                let specifier = try container.decode(GridScrollPositionSpecifier.self, forKey: .specifier)
                self.specifier = .gridScroll(specifier)
            }

            let keyType = try container.decode(KeyType.self, forKey: .key_type)
            switch keyType {
            case .system:
                let key = try container.decode(CustardInterfaceSystemKey.self, forKey: .key)
                self.key = .system(key)
            case .custom:
                let key = try container.decode(CustardInterfaceCustomKey.self, forKey: .key)
                self.key = .custom(key)
            }
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(keyStyle, forKey: .key_style)
        try container.encode(keyLayout, forKey: .key_layout)
        let elements = self.keys.map {Element(specifier: $0.key, key: $0.value)}
        try container.encode(elements, forKey: .keys)
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.keyStyle = try container.decode(CustardInterfaceStyle.self, forKey: .key_style)
        self.keyLayout = try container.decode(CustardInterfaceLayout.self, forKey: .key_layout)
        let elements = try container.decode([Element].self, forKey: .keys)
        self.keys = elements.reduce(into: [:]) {dictionary, element in
            dictionary[element.specifier] = element.key
        }
    }
}

/// - キーのデザイン
/// - design information of key
public struct CustardKeyDesign: Codable, Equatable, Hashable, Sendable {
    public init(label: CustardKeyLabelStyle, color: CustardKeyDesign.ColorType) {
        self.label = label
        self.color = color
    }

    public var label: CustardKeyLabelStyle
    public var color: ColorType

    public enum ColorType: String, Codable, Sendable {
        case normal
        case special
        case selected
        case unimportant
    }
}

/// - バリエーションのキーのデザイン
/// - design information of key
public struct CustardVariationKeyDesign: Codable, Equatable, Hashable, Sendable {
    public init(label: CustardKeyLabelStyle) {
        self.label = label
    }

    public var label: CustardKeyLabelStyle
}

/// - key's data in interface
public enum CustardInterfaceKey: Equatable, Hashable, Sendable {
    case system(CustardInterfaceSystemKey)
    case custom(CustardInterfaceCustomKey)
}

/// - keys prepared in default
public enum CustardInterfaceSystemKey: Codable, Equatable, Hashable, Sendable {
    /// - the globe key
    case changeKeyboard

    /// - the QWERTY language switch key
    case qwertyLanguageSwitch

    /// - the QWERTY shift key
    case qwertyShift

    /// - the QWERTY key whose label and destination depend on the current tab
    case qwertyDynamicChange

    /// - the QWERTY space key that follows the next-candidate setting
    case qwertySpace

    /// - the enter key that changes its label in condition
    case enter

    /// - the upper_lower toggle key
    case upperLower

    /// - the "next candidate" key
    case nextCandidate

    /// custom keys.
    /// - flick 小ﾞﾟkey
    case flickKogaki
    /// - flick ､｡!? key
    case flickKutoten
    /// - flick hiragana tab
    case flickHiraTab
    /// - flick abc tab
    case flickAbcTab
    /// - flick number and symbols tab
    case flickStar123Tab
}

public extension CustardInterfaceSystemKey {
    private enum CodingKeys: CodingKey {
        case type
    }

    private enum ValueType: String, Codable {
        case change_keyboard
        case qwerty_language_switch
        case qwerty_shift
        case qwerty_dynamic_change
        case qwerty_space
        case enter
        case upper_lower
        case next_candidate
        case flick_kogaki
        case flick_kutoten
        case flick_hira_tab
        case flick_abc_tab
        case flick_star123_tab
    }

    private var valueType: ValueType {
        switch self {
        case .changeKeyboard: return .change_keyboard
        case .qwertyLanguageSwitch: return .qwerty_language_switch
        case .qwertyShift: return .qwerty_shift
        case .qwertyDynamicChange: return .qwerty_dynamic_change
        case .qwertySpace: return .qwerty_space
        case .enter: return .enter
        case .upperLower: return .upper_lower
        case .nextCandidate: return .next_candidate
        case .flickKogaki: return .flick_kogaki
        case .flickKutoten: return .flick_kutoten
        case .flickHiraTab: return .flick_hira_tab
        case .flickAbcTab: return .flick_abc_tab
        case .flickStar123Tab: return .flick_star123_tab
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.valueType, forKey: .type)
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ValueType.self, forKey: .type)
        switch type {
        case .enter:
            self = .enter
        case .change_keyboard:
            self = .changeKeyboard
        case .qwerty_language_switch:
            self = .qwertyLanguageSwitch
        case .qwerty_shift:
            self = .qwertyShift
        case .qwerty_dynamic_change:
            self = .qwertyDynamicChange
        case .qwerty_space:
            self = .qwertySpace
        case .upper_lower:
            self = .upperLower
        case .next_candidate:
            self = .nextCandidate
        case .flick_kogaki:
            self = .flickKogaki
        case .flick_kutoten:
            self = .flickKutoten
        case .flick_hira_tab:
            self = .flickHiraTab
        case .flick_abc_tab:
            self = .flickAbcTab
        case .flick_star123_tab:
            self = .flickStar123Tab
        }
    }
}

/// - direction in which long-press variations expand
public enum CustardInterfaceLongpressVariationDirection: String, Codable, Equatable, Hashable, Sendable {
    case center
    case right
    case left
}

/// - keys you can defined
public struct CustardInterfaceCustomKey: Codable, Equatable, Hashable, Sendable {
    public init(
        design: CustardKeyDesign,
        press_actions: [CodableActionData],
        longpress_actions: CodableLongpressActionData,
        variations: [CustardInterfaceVariation],
        longpress_variation_direction: CustardInterfaceLongpressVariationDirection? = nil,
        shows_tap_bubble: Bool? = nil
    ) {
        self.design = design
        self.press_actions = press_actions
        self.longpress_actions = longpress_actions
        self.variations = variations
        self.longpress_variation_direction = longpress_variation_direction
        self.shows_tap_bubble = shows_tap_bubble
    }

    /// - design of this key
    public var design: CustardKeyDesign

    /// - actions done when this key is pressed. actions are done in order.
    public var press_actions: [CodableActionData]

    /// - actions done when this key is longpressed. actions are done in order.
    public var longpress_actions: CodableLongpressActionData

    /// - variations available when user flick or longpress this key
    public var variations: [CustardInterfaceVariation]

    /// - direction in which long-press variations expand.
    ///   `nil` keeps the legacy center-aligned behavior.
    public var longpress_variation_direction: CustardInterfaceLongpressVariationDirection?

    /// - whether the key shows a QWERTY-style tap bubble.
    ///   `nil` keeps the legacy behavior inferred from the key style and actions.
    public var shows_tap_bubble: Bool?
}

public extension CustardInterfaceCustomKey {
    /// Create simple input key using flick
    /// - parameters:
    ///  - center: string inputed when tap the key
    ///  - subs: set string inputed when flick the key up to four letters. letters are stucked in order left -> top -> right -> bottom
    ///  - centerLabel: (optional) if needed, set label of center. without specification `center` is set as label
    static func flickSimpleInputs(center: String, subs: [String], centerLabel: String? = nil) -> Self {
        let variations: [CustardInterfaceVariation] = zip(subs, [FlickDirection.left, .top, .right, .bottom]).map {letter, direction in
            .init(
                type: .flickVariation(direction),
                key: .init(
                    design: .init(label: .text(letter)),
                    press_actions: [.input(letter)],
                    longpress_actions: .none
                )
            )
        }

        return .init(
            design: .init(label: .text(centerLabel ?? center), color: .normal),
            press_actions: [.input(center)],
            longpress_actions: .none,
            variations: variations
        )
    }

    /// Create simple input key using flick
    /// - parameters:
    ///  - center: if label and input are the same value, simply set the literal or explicitly `.init(string)`. otherwise use `.init(input: String, label: String)`.
    ///  - left: optional. if label and input are the same value, simply set the literal or explicitly `.init(string)`. otherwise use `.init(input: String, label: String)`.
    ///  - top: optional. if label and input are the same value, simply set the literal or explicitly `.init(string)`. otherwise use `.init(input: String, label: String)`.
    ///  - right: optional. if label and input are the same value, simply set the literal or explicitly `.init(string)`. otherwise use `.init(input: String, label: String)`.
    ///  - bottom: optional. if label and input are the same value, simply set the literal or explicitly `.init(string)`. otherwise use `.init(input: String, label: String)`.
    static func flickSimpleInputs(center: SimpleInputArgument, left: SimpleInputArgument? = nil, top: SimpleInputArgument? = nil, right: SimpleInputArgument? = nil, bottom: SimpleInputArgument? = nil) -> Self {
        let variations: [CustardInterfaceVariation] = zip([left, top, right, bottom], [FlickDirection.left, .top, .right, .bottom]).compactMap {argument, direction in
            if let argument = argument {
                return .init(
                    type: .flickVariation(direction),
                    key: .init(
                        design: .init(label: .text(argument.label)),
                        press_actions: [.input(argument.input)],
                        longpress_actions: .none
                    )
                )
            }
            return nil
        }

        return .init(
            design: .init(label: .text(center.label), color: .normal),
            press_actions: [.input(center.input)],
            longpress_actions: .none,
            variations: variations
        )
    }

    struct SimpleInputArgument: Equatable, ExpressibleByStringLiteral, Sendable {
        public var label: String
        public var input: String

        public typealias StringLiteralType = String

        public init(label: String, input: String) {
            self.label = label
            self.input = input
        }
        public init(stringLiteral: String) {
            self.init(stringLiteral)
        }
        public init(_ input: String) {
            self.label = input
            self.input = input
        }
    }

    static func flickDelete() -> Self {
        .init(
            design: .init(label: .systemImage("delete.left"), color: .special),
            press_actions: [.delete(1)],
            longpress_actions: .init(repeat: [.delete(1)]),
            variations: [
                .init(
                    type: .flickVariation(.left),
                    key: .init(
                        design: .init(label: .systemImage("xmark")),
                        press_actions: [.smartDeleteDefault],
                        longpress_actions: .none
                    )
                ),
            ]
        )
    }

    static func flickSpace() -> Self {
        .init(
            design: .init(label: .text("空白"), color: .special),
            press_actions: [.input(" ")],
            longpress_actions: .init(start: [.toggleCursorBar]),
            variations: [
                .init(
                    type: .flickVariation(.left),
                    key: .init(
                        design: .init(label: .text("←")),
                        press_actions: [.moveCursor(-1)],
                        longpress_actions: .init(repeat: [.moveCursor(-1)])
                    )
                ),
                .init(
                    type: .flickVariation(.top),
                    key: .init(
                        design: .init(label: .text("全角")),
                        press_actions: [.input("　")],
                        longpress_actions: .none
                    )
                ),
                .init(
                    type: .flickVariation(.bottom),
                    key: .init(
                        design: .init(label: .text("tab")),
                        press_actions: [.input("\t")],
                        longpress_actions: .none
                    )
                ),
            ]
        )
    }
}
