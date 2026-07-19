//
//  MarkedTextSettingView.swift
//  MainApp
//
//  Created by ensan on 2022/09/26.
//  Copyright © 2022 ensan. All rights reserved.
//

import AzooKeyUtils
import SwiftUI
import SwiftUIUtils

struct MarkedTextSettingView: View {
    typealias SettingKey = MarkedTextSettingKey
    @State private var setting: SettingUpdater<SettingKey>

    @MainActor init(_ key: SettingKey) {
        self._setting = .init(initialValue: .init())
    }

    func forward(_ settingValue: MarkedTextSettingKey.Value) -> Bool {
        if settingValue == .disabled {
            return false
        } else {
            return true
        }
    }

    func backward(_ boolValue: Bool) -> MarkedTextSettingKey.Value {
        if boolValue {
            return .enabled
        } else {
            return .disabled
        }
    }

    var body: some View {
        Toggle(isOn: $setting.value.converted(forward: forward, backward: backward)) {
            HStack {
                Text(SettingKey.title)
                HelpAlertButton(title: SettingKey.title, explanation: SettingKey.explanation)
            }
        }
        .toggleStyle(.switch)
        .onAppear {
            setting.reload()
        }
    }
}
