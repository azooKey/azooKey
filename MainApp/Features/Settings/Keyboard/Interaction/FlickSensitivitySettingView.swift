//
//  FlickSensitivitySettingView.swift
//  MainApp
//
//  Created by ensan on 2022/09/10.
//  Copyright © 2022 ensan. All rights reserved.
//

import AzooKeyUtils
import SwiftUI
import SwiftUIUtils

struct FlickSensitivitySettingView: View {
    typealias SettingKey = FlickSensitivitySettingKey
    @State private var enabled: Bool
    @State private var setting: SettingUpdater<SettingKey>

    @MainActor init(_ key: SettingKey) {
        self._setting = .init(initialValue: .init())
        if SettingKey.value == 1 {
            _enabled = .init(initialValue: false)
        } else {
            _enabled = .init(initialValue: true)
        }
    }

    @MainActor private var explanation: LocalizedStringKey {
        switch setting.value {
        case 0.33 ... 0.5: return "とても反応しにくい"
        case 0.5 ... 0.8: return "反応しにくい"
        case 0.8 ... 1.2: return "普通"
        case 1.2 ... 2: return "反応しやすい"
        case 2 ... 4: return "とても反応しやすい"
        default: return "普通"
        }
    }

    var body: some View {
        Toggle(isOn: $enabled) {
            HStack {
                Text(SettingKey.title)
                HelpAlertButton(title: SettingKey.title, explanation: SettingKey.explanation)
            }
        }.onChange(of: enabled) { (_, newValue) in
            if !newValue {
                setting.value = 1
            }
        }
        if enabled {
            VStack {
                // 対数スケールでBindingすると編集がしやすい
                Slider(value: $setting.value.converted(forward: log2, backward: {pow(2, $0)}), in: -1.59 ... 2)
                Text(explanation)
            }
        }
    }
}
