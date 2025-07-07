//
//  OneHandedModeSetting.swift
//  azooKey
//
//  Created by ensan on 2021/03/12.
//  Copyright © 2021 ensan. All rights reserved.
//

import Foundation
import SwiftUI
import SwiftUIUtils

public struct OneHandedModeSetting: Sendable, Codable, StaticInitialValueAvailable {
    public static let initialValue = Self()

    private(set) var flick_vertical = OneHandedModeSettingItem()
    private(set) var flick_horizontal = OneHandedModeSettingItem()
    private(set) var qwerty_vertical = OneHandedModeSettingItem()
    private(set) var qwerty_horizontal = OneHandedModeSettingItem()

    private func keyPath(layout: KeyboardLayout, orientation: KeyboardOrientation) -> WritableKeyPath<Self, OneHandedModeSettingItem> {
        switch (layout, orientation) {
        case (.flick, .vertical): return \.flick_vertical
        case (.flick, .horizontal): return \.flick_horizontal
        case (.qwerty, .vertical): return \.qwerty_vertical
        case (.qwerty, .horizontal): return \.qwerty_horizontal
        }
    }

    public func item(layout: KeyboardLayout, orientation: KeyboardOrientation) -> OneHandedModeSettingItem {
        self[keyPath: keyPath(layout: layout, orientation: orientation)]
    }

    mutating func update(layout: KeyboardLayout, orientation: KeyboardOrientation, process: (inout OneHandedModeSettingItem) -> Void) {
        process(&self[keyPath: keyPath(layout: layout, orientation: orientation)])
    }

    mutating func set(layout: KeyboardLayout, orientation: KeyboardOrientation, size: CGSize, position: CGPoint) {
        self[keyPath: keyPath(layout: layout, orientation: orientation)].hasUsed = true
        self[keyPath: keyPath(layout: layout, orientation: orientation)].size = size
        self[keyPath: keyPath(layout: layout, orientation: orientation)].position = position
    }

    mutating func setIfFirst(layout: KeyboardLayout, orientation: KeyboardOrientation, size: CGSize, position: CGPoint, forced: Bool = false) {
        if !self[keyPath: keyPath(layout: layout, orientation: orientation)].hasUsed || forced {
            self[keyPath: keyPath(layout: layout, orientation: orientation)].hasUsed = true
            self[keyPath: keyPath(layout: layout, orientation: orientation)].size = size
            self[keyPath: keyPath(layout: layout, orientation: orientation)].position = position
        }
    }

    mutating func reset(layout: KeyboardLayout, orientation: KeyboardOrientation) {
        // 対応する設定項目に、新しい空のインスタンスを代入して上書きする
        // これにより、hasUsedフラグもfalseに戻るため、setIfFirstが機能するようになる
        // userHasOverwrittenKeyboardHeightSettingについては、明示的なリセット操作が行われている以上、trueにしてしまってよい
        self[keyPath: keyPath(layout: layout, orientation: orientation)] = OneHandedModeSettingItem(userHasOverwrittenKeyboardHeightSetting: true)
    }

    mutating func setUserHasOverwrittenKeyboardHeightSetting(layout: KeyboardLayout, orientation: KeyboardOrientation) {
        self[keyPath: keyPath(layout: layout, orientation: orientation)].userHasOverwrittenKeyboardHeightSetting = true
    }

}

public struct OneHandedModeSettingItem: Sendable, Codable {
    // 最後の状態がOneHandedModeだったかどうか
    var isLastOnehandedMode: Bool = false
    // 使われたことがあるか
    var hasUsed: Bool = false
    // 片手モードの設定を変更したか
    // v2.5で導入。片手モードの高さスケール設定（v2.4.2まで存在）に対して片手モード上の高さ設定を優先させるか判定するための値。
    public var userHasOverwrittenKeyboardHeightSetting: Bool = false
    // データ
    var size: CGSize = .zero
    var position: CGPoint = .zero
    public var maxHeight: CGFloat = 0
}
