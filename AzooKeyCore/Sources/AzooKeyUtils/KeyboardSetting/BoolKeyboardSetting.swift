//
//  BoolKeyboardSetting.swift
//  BoolKeyboardSetting
//
//  Created by ensan on 2021/08/10.
//  Copyright © 2021 ensan. All rights reserved.
//

import Foundation
import KeyboardViews
import SwiftUI
import SwiftUtils

public protocol BoolKeyboardSettingKey: KeyboardSettingKey, StoredInUserDefault where Value == Bool {
    /// 有効化時に実行される処理
    static func onEnabled() -> LocalizedStringKey?
    /// 無効化時に実行される処理
    static func onDisabled()
}
public extension StoredInUserDefault where Value == Bool {
    @MainActor
    static func get() -> Value? {
        let object = SharedStore.userDefaults.object(forKey: key)
        return object as? Bool
    }
    @MainActor
    static func set(newValue: Value) {
        SharedStore.userDefaults.set(newValue, forKey: key)
    }
}

public extension BoolKeyboardSettingKey {
    static func onEnabled() -> LocalizedStringKey? { nil }
    static func onDisabled() {}

    @MainActor static var value: Value {
        get {
            get() ?? defaultValue
        }
        set {
            set(newValue: newValue)
        }
    }
}

public struct LiveConversionInputMode: BoolKeyboardSettingKey {
    public static let title: LocalizedStringKey = "ライブ変換"
    public static let explanation: LocalizedStringKey = "入力中の文字列を自動的に変換します。"
    public static let defaultValue = true
    public static let key: String = "live_conversion"
}

public extension KeyboardSettingKey where Self == LiveConversionInputMode {
    static var liveConversion: Self { .init() }
}

public struct EnableZenzai: BoolKeyboardSettingKey {
    public static let title: LocalizedStringKey = "Zenzaiを有効化"
    public static let explanation: LocalizedStringKey = "高度な変換アルゴリズム「Zenzai」を利用します。"
    public static let defaultValue = false
    public static let key: String = "enable_zenzai"
}

public extension KeyboardSettingKey where Self == EnableZenzai {
    static var zenzaiEnable: Self { .init() }
}

public struct TypographyLetter: BoolKeyboardSettingKey {
    public static let title: LocalizedStringKey = "装飾英字変換"
    public static let explanation: LocalizedStringKey = "英字入力の際に\n「𝕥𝕪𝕡𝕠𝕘𝕣𝕒𝕡𝕙𝕪」のような装飾字体を候補に表示します。"
    public static let defaultValue = true
    public static let key: String = "typography_roman_candidate"
}

public extension KeyboardSettingKey where Self == TypographyLetter {
    static var typographyLetter: Self { .init() }
}

public struct EnglishCandidate: BoolKeyboardSettingKey {
    public static let title: LocalizedStringKey = "日本語入力中の英単語変換"
    public static let explanation: LocalizedStringKey = "「いんてれsちんg」→「interesting」のように、ローマ字日本語入力中も英語への変換候補を表示します。"
    public static let defaultValue = true
    public static let key: String = "roman_english_candidate"
}

public extension KeyboardSettingKey where Self == EnglishCandidate {
    static var englishCandidate: Self { .init() }
}

public struct MemoryResetFlag: BoolKeyboardSettingKey {
    public static let title: LocalizedStringKey = "学習のリセット"
    public static let explanation: LocalizedStringKey = "学習履歴を全て消去します。この操作は取り消せません。"
    public static let defaultValue = false
    public static let key: String = "memory_reset_setting"
}

public extension KeyboardSettingKey where Self == MemoryResetFlag {
    static var memoryResetFlag: Self { .init() }
}

public struct EnableKeySound: BoolKeyboardSettingKey {
    public static let title: LocalizedStringKey = "キーの音"
    public static let explanation: LocalizedStringKey = "キーを押した際に音を鳴らします♪"
    public static let defaultValue = false
    public static let key: String = "sound_enable_setting"
}

public extension KeyboardSettingKey where Self == EnableKeySound {
    static var enableKeySound: Self { .init() }
}

/// キーボードの触覚フィードバックを有効化する設定
/// - note: この機能はフルアクセスがないと実現できない
public struct EnableKeyHaptics: BoolKeyboardSettingKey {
    public static let title: LocalizedStringKey = "振動フィードバック"
    public static let explanation: LocalizedStringKey = "キーを押した際に端末を振動させます。"
    public static let defaultValue = false
    public static let key: String = "enable_key_haptics"
    public static let requireFullAccess: Bool = true
}

public extension KeyboardSettingKey where Self == EnableKeyHaptics {
    static var enableKeyHaptics: Self { .init() }
}

public struct UseOSUserDict: BoolKeyboardSettingKey {
    public static let title: LocalizedStringKey = "OSのユーザ辞書の利用"
    public static let explanation: LocalizedStringKey = "OS標準のユーザ辞書を利用します。"
    public static let defaultValue = true
    public static let key: String = "use_OS_user_dict"
}

public extension KeyboardSettingKey where Self == UseOSUserDict {
    static var useOSUserDict: Self { .init() }
}

public struct UseReflectStyleCursorBar: BoolKeyboardSettingKey {
    public static let title: LocalizedStringKey = "新しいカーソルバーを使う"
    public static let explanation: LocalizedStringKey = "操作性が向上した新しいカーソルバーを有効化します。"
    public static let defaultValue = true
    // MARK: This setting is originally introduced as 'beta cursor bar'
    public static let key: String = "use_move_cursor_bar_beta"
}

public extension KeyboardSettingKey where Self == UseReflectStyleCursorBar {
    static var useReflectStyleCursorBar: Self { .init() }
}

public struct DisplayCursorBarAutomatically: BoolKeyboardSettingKey {
    public static let title: LocalizedStringKey = "カーソルバーを自動表示"
    public static let explanation: LocalizedStringKey = "カーソル移動の際にカーソルバーを自動表示します"
    public static let defaultValue = false
    public static let key: String = "display_cursor_bar_automatically"
}

public extension KeyboardSettingKey where Self == DisplayCursorBarAutomatically {
    static var displayCursorBarAutomatically: Self { .init() }
}

public struct UseShiftKey: BoolKeyboardSettingKey {
    public static let title: LocalizedStringKey = "シフトキーを使う"
    public static let explanation: LocalizedStringKey = "QwertyキーボードでAaキーの代わりにシフトキーを利用します。"
    public static let defaultValue = false
    public static let key: String = "use_shift_key"
}

public extension KeyboardSettingKey where Self == UseShiftKey {
    static var useShiftKey: Self { .init() }
}

public struct KeepDeprecatedShiftKeyBehavior: BoolKeyboardSettingKey {
    public static let title: LocalizedStringKey = "シフトキーの古い挙動を使う"
    public static let explanation: LocalizedStringKey = "シフトキーの以前の挙動を利用します。iOS 18以降では廃止されます。"
    public static let defaultValue: Bool = true
    public static let key: String = "keep_deprecated_shift_key_behavior"
}

public extension KeyboardSettingKey where Self == KeepDeprecatedShiftKeyBehavior {
    static var keepDeprecatedShiftKeyBehavior: Self { .init() }
}

public struct UseNextCandidateKey: BoolKeyboardSettingKey {
    public static let title: LocalizedStringKey = "次候補キーを使う"
    public static let explanation: LocalizedStringKey = "キーボードで入力中、空白キーに「次候補」機能を表示します"
    public static let defaultValue = false
    public static let key: String = "use_next_candidate_key"
}

public extension KeyboardSettingKey where Self == UseNextCandidateKey {
    static var useNextCandidateKey: Self { .init() }
}

public struct HideResetButtonInOneHandedMode: BoolKeyboardSettingKey {
    public static let title: LocalizedStringKey = "片手モードで解除ボタンを表示しない"
    public static let explanation: LocalizedStringKey = "片手モードの際に表示される解除ボタンを非表示にします。片手モードの調整はタブバーのボタンから行えます。"
    public static let defaultValue = false
    public static let key: String = "hide_reset_button_in_one_handed_mode"
}

public extension KeyboardSettingKey where Self == HideResetButtonInOneHandedMode {
    static var hideResetButtonInOneHandedMode: Self { .init() }
}

public struct StopLearningWhenSearch: BoolKeyboardSettingKey {
    public static let title: LocalizedStringKey = "検索時は学習を停止"
    public static let explanation: LocalizedStringKey = "web検索などで入力した単語を学習しません。"
    public static let defaultValue = false
    public static let key: String = "stop_learning_when_search"
}

public extension KeyboardSettingKey where Self == StopLearningWhenSearch {
    static var stopLearningWhenSearch: Self { .init() }
}

/// ペーストボタンを追加する設定
/// - note: この機能はフリックのキーボードのみで提供する
/// - note: この機能はフルアクセスがないと実現できない
public struct EnablePasteButton: BoolKeyboardSettingKey {
    public static let title: LocalizedStringKey = "ペーストボタン"
    public static let explanation: LocalizedStringKey = "左下のカーソル移動キーの上フリックにペーストボタンを追加します"
    public static let defaultValue = false
    public static let key: String = "enable_paste_button_on_flick_cursorbar_key"
    public static let requireFullAccess: Bool = true
}

public extension KeyboardSettingKey where Self == EnablePasteButton {
    static var enablePasteButton: Self { .init() }
}

/// 「連絡先」アプリの名前情報を読み込む設定
/// - note: この機能はフルアクセスがないと実現できない
public struct EnableContactImport: BoolKeyboardSettingKey {
    public static let title: LocalizedStringKey = "変換に連絡先データを利用"
    public static let explanation: LocalizedStringKey = "「連絡先」アプリに登録された氏名のデータを変換に利用します"
    public static let defaultValue = false
    public static let key: String = "enable_contact_import"
    public static let requireFullAccess: Bool = true
}

public extension KeyboardSettingKey where Self == EnableContactImport {
    static var enableContactImport: Self { .init() }
}

/// クリップボード履歴マネージャを有効化する設定
/// - note: この機能はフルアクセスがないと実現できない
public struct EnableClipboardHistoryManagerTab: BoolKeyboardSettingKey {
    public static let title: LocalizedStringKey = "クリップボードの履歴を保存"
    public static let explanation: LocalizedStringKey = "コピーした文字列の履歴を保存し、専用のタブから入力できるようにします。"
    public static let defaultValue = false
    public static let key: String = "enable_clipboard_history_manager_tab"
    public static let requireFullAccess: Bool = true
    public static func onEnabled() -> LocalizedStringKey? {
        do {
            var manager = CustardManager.load()
            var tabBarData = (try? manager.tabbar(identifier: 0)) ?? .default
            if !tabBarData.items.contains(where: {$0.actions == [.moveTab(.system(.clipboard_history_tab))]}) {
                tabBarData.items.append(TabBarItem(label: .image("doc.badge.clock"), pinned: true, actions: [.moveTab(.system(.clipboard_history_tab))]))
            }
            tabBarData.lastUpdateDate = Date()
            try manager.saveTabBarData(tabBarData: tabBarData)
            return "タブバーに「コピー履歴」を開くためのボタン\(Image(systemName: "doc.badge.clock"))を追加しました。「ペーストの許可」を求めるダイアログが繰り返し出る場合、本体設定の「ほかのAppからペースト」を「許可」に設定してください。"
        } catch {
            debug("EnableClipboardHistoryManagerTab onEnabled", error)
            return nil
        }
    }
    public static func onDisabled() {
        do {
            var manager = CustardManager.load()
            var tabBarData = (try? manager.tabbar(identifier: 0)) ?? .default
            tabBarData.items.removeAll {
                $0.actions == [.moveTab(.system(.clipboard_history_tab))]
            }
            tabBarData.lastUpdateDate = Date()
            try manager.saveTabBarData(tabBarData: tabBarData)
        } catch {
            debug("EnableClipboardHistoryManagerTab onEnabled", error)
        }
    }
}

public extension KeyboardSettingKey where Self == EnableClipboardHistoryManagerTab {
    static var enableClipboardHistoryManagerTab: Self { .init() }
}

/// 削除した設定を記録するためのenum。おもに`key`の情報を残すため、ソースに維持している。
private enum DeprecatedSetting {
    public struct HalfKanaCandidate: BoolKeyboardSettingKey {
        public static let title: LocalizedStringKey = "半角カナ変換"
        public static let explanation: LocalizedStringKey = "半角ｶﾀｶﾅへの変換を候補に表示します。"
        public static let defaultValue = true
        public static let key: String = "half_kana_candidate"
    }

    public struct FullRomanCandidate: BoolKeyboardSettingKey {
        public static let title: LocalizedStringKey = "全角英数字変換"
        public static let explanation: LocalizedStringKey = "全角英数字(ａｂｃ１２３)への変換候補を表示します。"
        public static let defaultValue = true
        public static let key: String = "full_roman_candidate"
    }

    public struct UnicodeCandidate: BoolKeyboardSettingKey {
        public static let title: LocalizedStringKey = "unicode変換"
        public static let explanation: LocalizedStringKey = "「u3042→あ」のように、入力されたunicode番号に対応する文字に変換します。接頭辞にはu, u+, U, U+が使えます。"
        public static let defaultValue = true
        public static let key: String = "unicode_candidate"
    }

    public struct DisplayTabBarButton: BoolKeyboardSettingKey {
        public static let title: LocalizedStringKey = "タブバーボタン"
        public static let explanation: LocalizedStringKey = "変換候補欄が空のときにタブバーボタンを表示します"
        public static let defaultValue = true
        public static let key: String = "display_tab_bar_button"
    }
}
