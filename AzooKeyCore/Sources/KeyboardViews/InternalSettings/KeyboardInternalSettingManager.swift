//
//  KeyboardInternalSettingManager.swift
//
//
//  Created by ensan on 2023/07/21.
//

import Foundation
import SwiftUIUtils

public struct KeyboardInternalSettingManager: UserDefaultsManager {
    public var userDefaults: UserDefaults

    public enum Keys: String, UserDefaultsKeys {
        public typealias Manager = KeyboardInternalSettingManager
        case one_handed_mode_setting
        case tab_character_preference
        case emoji_tab_expand_mode_preference

        public init(keyPath: PartialKeyPath<Manager>) {
            switch keyPath {
            case \Manager.oneHandedModeSetting:
                self = .one_handed_mode_setting
            case \Manager.tabCharacterPreference:
                self = .tab_character_preference
            case \Manager.emojiTabExpandModePreference:
                self = .emoji_tab_expand_mode_preference
            default:
                fatalError("Unknown Key Path: \(keyPath)")
            }
        }
    }

    public init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
        self.oneHandedModeSetting = Self.load(key: .one_handed_mode_setting, userDefaults: userDefaults)
        self.tabCharacterPreference = Self.load(key: .tab_character_preference, userDefaults: userDefaults)
        self.emojiTabExpandModePreference = Self.load(key: .emoji_tab_expand_mode_preference, userDefaults: userDefaults)
    }

    public var oneHandedModeSetting: OneHandedModeSetting
    private(set) public var tabCharacterPreference: TabCharacterPreference
    private(set) public var emojiTabExpandModePreference: EmojiTabExpandModePreference
}
