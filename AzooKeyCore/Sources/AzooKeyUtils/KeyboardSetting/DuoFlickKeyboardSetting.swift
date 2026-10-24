import Foundation
import SwiftUI

public struct EnableDuoFlick: BoolKeyboardSettingKey {
    public static let title: LocalizedStringKey = "Duoフリックを使う"
    public static let explanation: LocalizedStringKey = "幅600pt以上の画面で、同じフリック配列を左右に表示します。"
    // Existing keyboards retain their layout until the user opts in.
    public static let defaultValue = false
    public static let key = "enable_duo_flick"
}

public extension KeyboardSettingKey where Self == EnableDuoFlick {
    static var enableDuoFlick: Self { .init() }
}

public struct DuoFlickPanelWidth: DoubleKeyboardSettingKey {
    public static let title: LocalizedStringKey = "片側の幅"
    public static let explanation: LocalizedStringKey = "標準では画面幅いっぱいに広げます。手動で片側の最大幅も調整できます。"
    public static let defaultValue: Double = 0
    public static let key = "duo_flick_panel_width"
}

public struct DuoFlickCenterGap: DoubleKeyboardSettingKey {
    public static let title: LocalizedStringKey = "中央の間隔"
    public static let explanation: LocalizedStringKey = "折り目付近に確保する最小の間隔を調整できます。"
    public static let defaultValue: Double = 16
    public static let key = "duo_flick_center_gap"
}

@MainActor
public enum DuoFlickLayoutDefaults {
    /// Apply the expanded defaults once, including installations which already
    /// saved the original narrow defaults. Later manual adjustments are kept.
    public static func migrateIfNeeded(in defaults: UserDefaults = SharedStore.userDefaults) {
        let marker = "duo_flick_expanded_defaults_applied"
        guard !defaults.bool(forKey: marker) else {
            return
        }
        defaults.set(DuoFlickPanelWidth.defaultValue, forKey: DuoFlickPanelWidth.key)
        defaults.set(DuoFlickCenterGap.defaultValue, forKey: DuoFlickCenterGap.key)
        defaults.set(true, forKey: marker)
    }
}
