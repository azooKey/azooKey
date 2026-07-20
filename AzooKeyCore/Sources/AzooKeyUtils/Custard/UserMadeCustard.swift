//
//  UserMadeCustard.swift
//  azooKey
//
//  Created by ensan on 2021/02/23.
//  Copyright © 2021 ensan. All rights reserved.
//

import CustardKit
import Foundation
import KeyboardViews

public enum UserMadeCustard: Codable, Sendable {
    case gridScroll(UserMadeGridScrollCustard)
    case tenkey(UserMadeGridFitCustard)
}

public extension UserMadeCustard {
    mutating func rename(to newName: String) {
        switch self {
        case .gridScroll(var value):
            value.tabName = newName
            self = .gridScroll(value)
        case .tenkey(var value):
            value.tabName = newName
            self = .tenkey(value)
        }
    }
}

public extension UserMadeCustard {
    enum CodingKeys: CodingKey {
        case gridScroll
        case tenkey
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .gridScroll(value):
            try container.encode(value, forKey: .gridScroll)
        case let .tenkey(value):
            try container.encode(value, forKey: .tenkey)
        }
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let key = container.allKeys.first else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Unabled to decode UserMadeCustard."
                )
            )
        }
        switch key {
        case .gridScroll:
            let value = try container.decode(
                UserMadeGridScrollCustard.self,
                forKey: .gridScroll
            )
            self = .gridScroll(value)
        case .tenkey:
            let value = try container.decode(
                UserMadeGridFitCustard.self,
                forKey: .tenkey
            )
            self = .tenkey(value)
        }
    }
}

public struct UserMadeGridScrollCustard: Codable, Sendable {
    public init(tabName: String, direction: CustardInterfaceLayoutScrollValue.ScrollDirection, columnCount: String, rowCount: String, keys: [UserMadeKeyData], addTabBarAutomatically: Bool) {
        self.tabName = tabName
        self.direction = direction
        self.columnCount = columnCount
        self.rowCount = rowCount
        self.keys = keys
        self.addTabBarAutomatically = addTabBarAutomatically
    }

    public var tabName: String
    public var direction: CustardInterfaceLayoutScrollValue.ScrollDirection
    public var columnCount: String
    public var rowCount: String
    public var keys: [UserMadeKeyData]
    public var addTabBarAutomatically: Bool

    enum CodingKeys: CodingKey {
        case tabName
        case direction
        case columnCount
        case rowCount
        case addTabBarAutomatically
        case keys
        /// for interop
        /// until Version 2.2.3
        /// String-like "é\n√\nπ\nΩ"
        @available(*, deprecated, renamed: "keys")
        case words
    }

    public init(from decoder: any Decoder) throws {
        let container: KeyedDecodingContainer<UserMadeGridScrollCustard.CodingKeys> = try decoder.container(keyedBy: UserMadeGridScrollCustard.CodingKeys.self)

        self.tabName = try container.decode(String.self, forKey: UserMadeGridScrollCustard.CodingKeys.tabName)
        self.direction = try container.decode(CustardInterfaceLayoutScrollValue.ScrollDirection.self, forKey: UserMadeGridScrollCustard.CodingKeys.direction)
        self.columnCount = try container.decode(String.self, forKey: UserMadeGridScrollCustard.CodingKeys.columnCount)
        self.rowCount = try container.decode(String.self, forKey: UserMadeGridScrollCustard.CodingKeys.rowCount)
        if container.contains(.keys) {
            self.keys = try container.decode([UserMadeKeyData].self, forKey: UserMadeGridScrollCustard.CodingKeys.keys)
        } else {
            let words = try container.decode(String.self, forKey: UserMadeGridScrollCustard.CodingKeys.words)
            self.keys = Self.wordsToKeys(words)
        }
        self.addTabBarAutomatically = try container.decode(Bool.self, forKey: UserMadeGridScrollCustard.CodingKeys.addTabBarAutomatically)

    }

    public func encode(to encoder: any Encoder) throws {
        var container: KeyedEncodingContainer<UserMadeGridScrollCustard.CodingKeys> = encoder.container(keyedBy: UserMadeGridScrollCustard.CodingKeys.self)
        try container.encode(self.tabName, forKey: UserMadeGridScrollCustard.CodingKeys.tabName)
        try container.encode(self.direction, forKey: UserMadeGridScrollCustard.CodingKeys.direction)
        try container.encode(self.columnCount, forKey: UserMadeGridScrollCustard.CodingKeys.columnCount)
        try container.encode(self.rowCount, forKey: UserMadeGridScrollCustard.CodingKeys.rowCount)
        try container.encode(self.keys, forKey: UserMadeGridScrollCustard.CodingKeys.keys)
        try container.encode(self.addTabBarAutomatically, forKey: UserMadeGridScrollCustard.CodingKeys.addTabBarAutomatically)
    }

    public static func wordsToKeys(_ words: consuming String) -> [UserMadeKeyData] {
        var keys: [UserMadeKeyData] = [
            .init(model: .system(.changeKeyboard), width: 1, height: 1),
            .init(model: .custom(.init(design: .init(label: .systemImage("list.bullet"), color: .special), press_actions: [.toggleTabBar], longpress_actions: .none, variations: [])), width: 1, height: 1),
            .init(model: .custom(.init(design: .init(label: .systemImage("delete.left"), color: .special), press_actions: [.delete(1)], longpress_actions: .init(repeat: [.delete(1)]), variations: [])), width: 1, height: 1),
            .init(model: .system(.enter), width: 1, height: 1),
        ]
        for substring in words.split(separator: "\n") {
            let target = substring.components(separatedBy: "\\|").map {$0.components(separatedBy: "|")}.reduce(into: [String]()) {array, value in
                if let last = array.last, let first = value.first {
                    array.removeLast()
                    array.append([last, first].joined(separator: "|"))
                    array.append(contentsOf: value.dropFirst())
                } else {
                    array.append(contentsOf: value)
                }
            }
            guard let input = target.first else {
                continue
            }
            let label = target.count > 1 ? target[1] : input
            keys.append(.init(
                model: .custom(.init(design: .init(label: .text(label), color: .normal), press_actions: [.directInput(input)], longpress_actions: .none, variations: [])),
                width: 1,
                height: 1
            ))
        }
        return keys
    }
}

public struct UserMadeGridFitCustard: Codable, Sendable, Equatable {
    public enum KeyStyle: String, Codable, Sendable, Hashable {
        case tenkeyStyle = "tenkey_style"
        case pcStyle = "pc_style"

        public init(_ value: CustardInterfaceStyle) {
            switch value {
            case .tenkeyStyle:
                self = .tenkeyStyle
            case .pcStyle:
                self = .pcStyle
            }
        }

        public var interfaceStyle: CustardInterfaceStyle {
            switch self {
            case .tenkeyStyle:
                .tenkeyStyle
            case .pcStyle:
                .pcStyle
            }
        }
    }

    public init(
        tabName: String,
        rowCount: String,
        columnCount: String,
        inputStyle: CustardInputStyle,
        language: CustardLanguage,
        keys: [KeyPosition: UserMadeKeyData],
        emptyKeys: Set<KeyPosition> = [],
        keyStyle: KeyStyle = .tenkeyStyle,
        addTabBarAutomatically: Bool
    ) {
        self.tabName = tabName
        self.rowCount = rowCount
        self.columnCount = columnCount
        self.inputStyle = inputStyle
        self.language = language
        self.keys = keys
        self.emptyKeys = emptyKeys
        self.keyStyle = keyStyle
        self.addTabBarAutomatically = addTabBarAutomatically
    }

    public var tabName: String
    public var rowCount: String
    public var columnCount: String
    public var inputStyle: CustardInputStyle
    public var language: CustardLanguage
    public var keys: [KeyPosition: UserMadeKeyData]
    public var emptyKeys: Set<KeyPosition> = []
    public var keyStyle: KeyStyle
    public var addTabBarAutomatically: Bool

    private enum CodingKeys: CodingKey {
        case tabName
        case rowCount
        case columnCount
        case inputStyle
        case language
        case keys
        case emptyKeys
        case keyStyle
        case addTabBarAutomatically
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.tabName = try container.decode(String.self, forKey: .tabName)
        self.rowCount = try container.decode(String.self, forKey: .rowCount)
        self.columnCount = try container.decode(String.self, forKey: .columnCount)
        self.inputStyle = try container.decode(CustardInputStyle.self, forKey: .inputStyle)
        self.language = try container.decode(CustardLanguage.self, forKey: .language)
        self.keys = try container.decode([KeyPosition: UserMadeKeyData].self, forKey: .keys)
        self.emptyKeys = try container.decodeIfPresent(Set<KeyPosition>.self, forKey: .emptyKeys) ?? []
        self.keyStyle = try container.decodeIfPresent(KeyStyle.self, forKey: .keyStyle) ?? .tenkeyStyle
        self.addTabBarAutomatically = try container.decode(Bool.self, forKey: .addTabBarAutomatically)
    }
}

public extension Custard {
    var userMadeGridFitCustard: UserMadeGridFitCustard? {
        guard case let .gridFit(layout) = self.interface.keyLayout else {
            return nil
        }
        var keys: [KeyPosition: UserMadeKeyData] = [:]
        for (position, key) in self.interface.keys {
            guard case let .gridFit(value) = position,
                  value.width > 0,
                  value.height > 0 else {
                continue
            }
            keys[.gridFit(x: value.x, y: value.y)] = .init(
                model: key,
                width: value.width,
                height: value.height
            )
        }
        return UserMadeGridFitCustard(
            tabName: self.identifier,
            rowCount: layout.rowCount.description,
            columnCount: layout.columnCount.description,
            inputStyle: self.input_style,
            language: self.language,
            keys: keys,
            keyStyle: .init(self.interface.keyStyle),
            addTabBarAutomatically: true
        )
    }
}

public struct UserMadeKeyData: Codable, Hashable, Sendable, Identifiable {
    /// - warning: Do not assume `id` is held between execution; this value is re-generated for each `init`
    public let id = UUID()
    public init(model: CustardInterfaceKey, width: Double, height: Double) {
        self.model = model
        self.width = width
        self.height = height
    }

    private enum CodingKeys: CodingKey {
        case type, key, width, height
    }

    private enum ModelType: String, Codable {
        case system, custom
    }

    public var model: CustardInterfaceKey
    public var width: Double
    public var height: Double

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
        switch self.model {
        case let .system(value):
            try container.encode(ModelType.system, forKey: .type)
            try container.encode(value, forKey: .key)
        case let .custom(value):
            try container.encode(ModelType.custom, forKey: .type)
            try container.encode(value, forKey: .key)
        }
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.width = try container.decode(Double.self, forKey: .width)
        self.height = try container.decode(Double.self, forKey: .height)
        let type = try container.decode(ModelType.self, forKey: .type)
        switch type {
        case .system:
            let key = try container.decode(CustardInterfaceSystemKey.self, forKey: .key)
            self.model = .system(key)
        case .custom:
            let key = try container.decode(CustardInterfaceCustomKey.self, forKey: .key)
            self.model = .custom(key)
        }
    }
}
