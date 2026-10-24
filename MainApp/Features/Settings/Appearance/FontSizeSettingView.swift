//
//  FontSizeSettingItemView.swift
//  MainApp
//
//  Created by ensan on 2020/12/06.
//  Copyright © 2020 ensan. All rights reserved.
//

import AzooKeyUtils
import SwiftUI
import SwiftUIUtils

struct FontSizeSettingView<SettingKey: DoubleKeyboardSettingKey>: View {
    enum Target {
        case key
        case result
    }

    private let availableValueRange: ClosedRange<Double>
    private let target: Target

    @State private var enabled: Bool
    @State private var setting: SettingUpdater<SettingKey>

    @MainActor
    init(_ key: SettingKey, _ target: Target, availableValueRange: ClosedRange<Double>) {
        self.target = target
        self.availableValueRange = availableValueRange
        self._setting = .init(initialValue: .init())
        _enabled = State(initialValue: SettingKey.value != SettingKey.defaultValue)
    }

    var body: some View {
        Toggle(isOn: $enabled) {
            HStack {
                Text(SettingKey.title)
                HelpAlertButton(title: SettingKey.title, explanation: SettingKey.explanation)
            }
        }
        .onChange(of: enabled) { (_, newValue) in
            if newValue {
                setting.value = 18
            } else {
                setting.value = SettingKey.defaultValue
            }
        }
        .listRowSeparator(.hidden)

        if enabled {
            VStack {
                Slider(value: $setting.value, in: availableValueRange)
                switch self.target {
                case .key:
                    KeyView(fontSize: setting.value)

                case .result:
                    Text("サンプル")
                        .font(.system(size: setting.value))
                        .underline()
                        .padding()
                }
            }
        }
    }
}

@MainActor
private struct KeyView: View {
    @EnvironmentObject private var keyboardConfiguration: KeyboardConfigurationState
    private let fontSize: CGFloat

    init(fontSize: CGFloat) {
        self.fontSize = fontSize
    }

    var body: some View {
        GeometryReader { geometry in
            let referenceWidth = min(geometry.size.width, 560)
            let width = keyboardConfiguration.japaneseLayout == .qwerty
                ? max(44, referenceWidth / 12.2) : max(44, referenceWidth / 5.6)
            RoundedRectangle(cornerRadius: 5)
                .stroke()
                .frame(width: width, height: min(70, max(44, referenceWidth / 8)))
                .overlay {
                    Text(verbatim: "あ").font(.system(size: fontSize))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: 88)
    }
}
