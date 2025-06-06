//
//  KeyFlickSetting.swift
//  azooKey
//
//  Created by ensan on 2020/10/04.
//  Copyright © 2020 ensan. All rights reserved.
//

import CustardKit
import Foundation

public enum CustomizableFlickKey: String, Codable, Sendable {
    case kogana = "kogana"
    case kanaSymbols = "kana_symbols"
    case hiraTab = "hira_tab"
    case abcTab = "abc_tab"
    case symbolsTab = "symbols_tab"

    var identifier: String {
        self.rawValue
    }

    public var defaultSetting: KeyFlickSetting {
        switch self {
        case .kogana:
            return KeyFlickSetting(
                identifier: self,
                center: FlickCustomKey(label: "小ﾞﾟ", actions: [.replaceDefault(.default)]),
                left: FlickCustomKey(label: "", actions: []),
                top: FlickCustomKey(label: "", actions: []),
                right: FlickCustomKey(label: "", actions: []),
                bottom: FlickCustomKey(label: "", actions: [])
            )
        case .kanaSymbols:
            return KeyFlickSetting(
                identifier: self,
                center: FlickCustomKey(label: "､｡?!", actions: [.input("、")]),
                left: FlickCustomKey(label: "。", actions: [.input("。")]),
                top: FlickCustomKey(label: "？", actions: [.input("？")]),
                right: FlickCustomKey(label: "！", actions: [.input("！")]),
                bottom: FlickCustomKey(label: "", actions: [])
            )
        case .hiraTab:
            return KeyFlickSetting(
                identifier: self,
                center: FlickCustomKey(label: "あいう", actions: [.moveTab(.system(.user_japanese))]),
                left: FlickCustomKey(label: "", actions: []),
                top: FlickCustomKey(label: "", actions: []),
                right: FlickCustomKey(label: "", actions: []),
                bottom: FlickCustomKey(label: "", actions: [])
            )
        case .abcTab:
            return KeyFlickSetting(
                identifier: self,
                center: FlickCustomKey(label: "ABC", actions: [.moveTab(.system(.user_english))]),
                left: FlickCustomKey(label: "", actions: []),
                top: FlickCustomKey(label: "", actions: []),
                right: FlickCustomKey(label: "→", actions: [.moveCursor(1)], longpressActions: .init(repeat: [.moveCursor(1)])),
                bottom: FlickCustomKey(label: "", actions: [])
            )
        case .symbolsTab:
            return KeyFlickSetting(
                identifier: self,
                center: FlickCustomKey(label: "☆123", actions: [.moveTab(.system(.flick_numbersymbols))], longpressActions: .init(start: [.toggleTabBar])),
                left: FlickCustomKey(label: "", actions: []),
                top: FlickCustomKey(label: "", actions: []),
                right: FlickCustomKey(label: "", actions: []),
                bottom: FlickCustomKey(label: "", actions: [])
            )
        }
    }

    public var ablePosition: [FlickKeyPosition] {
        switch self {
        case .kogana:
            return [.left, .top, .right]
        case .kanaSymbols:
            return [.center, .left, .top, .right]
        case .hiraTab, .abcTab, .symbolsTab:
            return [.center, .top, .right, .bottom]
        }
    }
}

public enum FlickKeyPosition: String, Codable, Sendable {
    case left = "left"
    case top = "top"
    case right = "right"
    case bottom = "bottom"
    case center = "center"
}

public struct FlickCustomKey: Codable, Equatable, Sendable, Hashable {
    public var label: String
    public var actions: [CodableActionData]
    public var longpressActions: CodableLongpressActionData

    enum CodingKeys: CodingKey {
        case input
        case label
        case actions
        case longpressActions
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(label, forKey: .label)
        try container.encode(actions, forKey: .actions)
        try container.encode(longpressActions, forKey: .longpressActions)
    }

    public init(label: String, actions: [CodableActionData], longpressActions: CodableLongpressActionData = .none) {
        self.label = label
        self.actions = actions
        self.longpressActions = longpressActions
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let label = try container.decode(String.self, forKey: .label)
        let actions = try? container.decode([CodableActionData].self, forKey: .actions)
        let input = try? container.decode(String.self, forKey: .input)

        self.label = label
        if let actions {
            self.actions = actions
        } else if let input {
            self.actions = [.input(input)]
        } else {
            self.actions = []
        }
        self.longpressActions = (try? container.decode(CodableLongpressActionData.self, forKey: .longpressActions)) ?? .none
    }
}

public struct KeyFlickSetting: Codable, Equatable, Sendable, Hashable {
    enum CodingKeys: String, CodingKey {
        case targetKeyIdentifier

        case left
        case top
        case right
        case bottom
        case center
        case identifier
    }

    let targetKeyIdentifier: String // レガシー
    public var left: FlickCustomKey
    public var top: FlickCustomKey
    public var right: FlickCustomKey
    public var bottom: FlickCustomKey
    public var center: FlickCustomKey

    public let identifier: CustomizableFlickKey

    init(targetKeyIdentifier: String, left: String = "", top: String = "", right: String = "", bottom: String = "", center: String = "") {
        self.identifier = CustomizableFlickKey(rawValue: targetKeyIdentifier) ?? .kogana
        self.left = FlickCustomKey(label: left, actions: [.input(left)])
        self.top = FlickCustomKey(label: top, actions: [.input(top)])
        self.right = FlickCustomKey(label: right, actions: [.input(right)])
        self.bottom = FlickCustomKey(label: bottom, actions: [.input(bottom)])
        self.center = FlickCustomKey(label: "", actions: [])
        // レガシー
        self.targetKeyIdentifier = self.identifier.identifier
    }

    public init(identifier: CustomizableFlickKey, center: FlickCustomKey, left: FlickCustomKey, top: FlickCustomKey, right: FlickCustomKey, bottom: FlickCustomKey) {
        self.identifier = identifier
        self.center = center
        self.left = left
        self.top = top
        self.right = right
        self.bottom = bottom
        // レガシー
        self.targetKeyIdentifier = identifier.rawValue
    }

    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        if let targetKeyIdentifier = try? values.decode(String.self, forKey: .targetKeyIdentifier),
           let left = try? values.decode(String.self, forKey: .left),
           let top = try? values.decode(String.self, forKey: .top),
           let right = try? values.decode(String.self, forKey: .right),
           let bottom = try? values.decode(String.self, forKey: .bottom) {
            self.targetKeyIdentifier = targetKeyIdentifier
            self.identifier = CustomizableFlickKey(rawValue: targetKeyIdentifier) ?? .kogana
            self.left = FlickCustomKey(label: left, actions: [.input(left)])
            self.top = FlickCustomKey(label: top, actions: [.input(top)])
            self.right = FlickCustomKey(label: right, actions: [.input(right)])
            self.bottom = FlickCustomKey(label: bottom, actions: [.input(bottom)])
            self.center = FlickCustomKey(label: "", actions: [])
            return
        }

        self.identifier = try values.decode(CustomizableFlickKey.self, forKey: .identifier)
        self.left = try values.decode(FlickCustomKey.self, forKey: .left)
        self.top = try values.decode(FlickCustomKey.self, forKey: .top)
        self.right = try values.decode(FlickCustomKey.self, forKey: .right)
        self.bottom = try values.decode(FlickCustomKey.self, forKey: .bottom)
        self.center = try values.decode(FlickCustomKey.self, forKey: .center)

        self.targetKeyIdentifier = identifier.identifier
    }

    /*
     これに由来する
     var saveValue: [String: String] {
     return [
     "identifier":targetKeyIdentifier,
     "left":left,
     "top":top,
     "right":right,
     "bottom":bottom
     ]
     }*/

    public static func get(_ value: Any) -> KeyFlickSetting? {
        if let dict = value as? [String: String] {
            if let identifier = dict["identifier"],
               let left = dict["left"],
               let top = dict["top"],
               let right = dict["right"],
               let bottom = dict["bottom"] {
                return KeyFlickSetting(targetKeyIdentifier: identifier, left: left, top: top, right: right, bottom: bottom)
            }
        }
        if let value = value as? Data {
            let decoder = JSONDecoder()
            if let data = try? decoder.decode(KeyFlickSetting.self, from: value) {
                return data
            }

        }
        return nil
    }
}

extension KeyFlickSetting {
    public typealias SettingData = (labelType: KeyLabelType, actions: [ActionType], longpressActions: LongpressActionType, flick: [FlickDirection: FlickedKeyModel])

    public func compiled() -> SettingData {
        let targets: [(path: KeyPath<KeyFlickSetting, FlickCustomKey>, direction: FlickDirection)] = [(\.left, .left), (\.top, .top), (\.right, .right), (\.bottom, .bottom)]
        let dict: [FlickDirection: FlickedKeyModel] = targets.reduce(into: [:]) {dict, target in
            let item = self[keyPath: target.path]
            if item.label.isEmpty {
                return
            }
            let model = FlickedKeyModel(
                labelType: .text(item.label),
                pressActions: item.actions.map {$0.actionType},
                longPressActions: item.longpressActions.longpressActionType
            )
            dict[target.direction] = model
        }
        return (.text(self.center.label), self.center.actions.map {$0.actionType}, self.center.longpressActions.longpressActionType, dict)
    }
}
