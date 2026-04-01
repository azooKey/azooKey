//
//  AzooKeyKeyboardViewExtension.swift
//  azooKey
//
//  Created by β α on 2023/07/22.
//  Copyright © 2023 DevEn3. All rights reserved.
//

import Foundation
import KeyboardViews

public enum AzooKeyKeyboardViewExtension: ApplicationSpecificKeyboardViewExtension {
    public typealias ThemeExtension = AzooKeySpecificTheme

    public typealias MessageProvider = AzooKeyMessageProvider

    public typealias SettingProvider = AzooKeySettingProvider
}

@MainActor public enum AzooKeySettingProvider: ApplicationSpecificKeyboardViewSettingProvider {
    public static var japaneseKeyboardLayout: KeyboardViews.LanguageLayout {
        JapaneseKeyboardLayout.value
    }

    public static var englishKeyboardLayout: KeyboardViews.LanguageLayout {
        EnglishKeyboardLayout.value
    }

    public static var koganaFlickCustomKey: KeyboardViews.KeyFlickSetting {
        KoganaFlickCustomKey.value
    }

    public static var symbolsTabFlickCustomKey: KeyboardViews.KeyFlickSetting {
        SymbolsTabFlickCustomKey.value
    }

    public static var abcTabFlickCustomKey: KeyboardViews.KeyFlickSetting {
        AbcTabFlickCustomKey.value
    }

    public static var hiraTabFlickCustomKey: KeyboardViews.KeyFlickSetting {
        HiraTabFlickCustomKey.value
    }

    public static var kanaSymbolsFlickCustomKey: KeyboardViews.KeyFlickSetting {
        KanaSymbolsFlickCustomKey.value
    }

    public static var numberTabCustomKeysSetting: KeyboardViews.QwertyCustomKeysValue {
        NumberTabCustomKeysSetting.value
    }

    public static var flickSensitivity: Double {
        FlickSensitivitySettingKey.value
    }

    public static var resultViewFontSize: Double {
        ResultViewFontSize.value
    }

    public static var keyViewFontSize: Double {
        KeyViewFontSize.value
    }

    public static var keyboardHeight: Double {
        KeyboardHeightScaleSettingKey.value
    }

    public static var enableSound: Bool {
        EnableKeySound.value
    }

    public static var enableHaptics: Bool {
        EnableKeyHaptics.value
    }

    public static var enablePasteButton: Bool {
        EnablePasteButton.value
    }

    public static var displayTabBarButton: Bool {
        true
    }

    public static var hideResetButtonInOneHandedMode: Bool {
        HideResetButtonInOneHandedMode.value
    }

    public static var useReflectStyleCursorBar: Bool {
        UseReflectStyleCursorBar.value
    }

    public static var useShiftKey: Bool {
        UseShiftKey.value
    }

    public static var keepDeprecatedShiftKeyBehavior: Bool {
        KeepDeprecatedShiftKeyBehavior.value
    }

    public static var useNextCandidateKey: Bool {
        UseNextCandidateKey.value
    }

    public static var displayCursorBarAutomatically: Bool {
        DisplayCursorBarAutomatically.value
    }

    public static var canResetLearningForCandidate: Bool {
        LearningTypeSetting.value.needUsingMemory
    }

    public static func get(_ key: KeyboardViews.CustomizableFlickKey) -> KeyboardViews.KeyFlickSetting.SettingData {
        let setting: KeyFlickSetting
        switch key {
        case .kogana:
            setting = KoganaFlickCustomKey.value
        case .kanaSymbols:
            setting = KanaSymbolsFlickCustomKey.value
        case .hiraTab:
            setting = HiraTabFlickCustomKey.value
        case .abcTab:
            setting = AbcTabFlickCustomKey.value
        case .symbolsTab:
            setting = SymbolsTabFlickCustomKey.value
        }
        return setting.compiled()
    }
}

public struct ClipboardHistoryManagerConfig: ClipboardHistoryManagerConfiguration {
    public init() {}

    public var enabled: Bool {
        EnableClipboardHistoryManagerTab.value
    }

    public var saveDirectory: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: SharedStore.appGroupKey)
    }

    public var maxCount: Int {
        50
    }
}

public struct TabManagerConfig: TabManagerConfiguration {
    public init() {}

    public var japaneseLayout: KeyboardViews.LanguageLayout {
        AzooKeySettingProvider.japaneseKeyboardLayout
    }

    public var englishLayout: KeyboardViews.LanguageLayout {
        AzooKeySettingProvider.englishKeyboardLayout
    }

    public var custardManager: any KeyboardViews.CustardManagerProtocol {
        CustardManager.load()
    }
}
