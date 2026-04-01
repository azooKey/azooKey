//
//  ApplicationSpecificKeyboardViewSettingProvider.swift
//
//
//  Created by ensan on 2023/07/22.
//

import Foundation

@MainActor public protocol ApplicationSpecificKeyboardViewSettingProvider {
    static var koganaFlickCustomKey: KeyFlickSetting { get }
    static var kanaSymbolsFlickCustomKey: KeyFlickSetting { get }
    static var hiraTabFlickCustomKey: KeyFlickSetting { get }
    static var abcTabFlickCustomKey: KeyFlickSetting { get }
    static var symbolsTabFlickCustomKey: KeyFlickSetting { get }

    static var numberTabCustomKeysSetting: QwertyCustomKeysValue { get }

    static var japaneseKeyboardLayout: LanguageLayout { get }
    static var englishKeyboardLayout: LanguageLayout { get }

    static var flickSensitivity: Double { get }
    static var resultViewFontSize: Double { get }
    static var keyViewFontSize: Double { get }

    static var enableSound: Bool { get }
    static var enableHaptics: Bool { get }
    static var enablePasteButton: Bool { get }
    static var hideResetButtonInOneHandedMode: Bool { get }
    static var useShiftKey: Bool { get }
    static var keepDeprecatedShiftKeyBehavior: Bool { get }
    static var useNextCandidateKey: Bool { get }

    /// タブバーボタンを表示する
    static var displayTabBarButton: Bool { get }
    /// 反射スタイルのカーソルバーを利用する
    static var useReflectStyleCursorBar: Bool { get }
    /// カーソルバーを自動表示する（実験的機能）
    ///  - note: この機能は実験的に導入しているが、仕様に議論がある。[#346](https://github.com/azooKey/azooKey/issues/346)も参照。
    static var displayCursorBarAutomatically: Bool { get }

    static var canResetLearningForCandidate: Bool { get }

    static func get(_: CustomizableFlickKey) -> KeyFlickSetting.SettingData
}
