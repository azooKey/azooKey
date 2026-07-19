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
    @EnvironmentObject private var appStates: MainAppStates
    private let fontSize: CGFloat

    init(fontSize: CGFloat) {
        self.fontSize = fontSize
    }

    private var size: CGSize {
        let screenWidth = UIScreen.main.bounds.width
        switch appStates.japaneseLayout {
        case .flick:
            return CGSize(width: screenWidth / 5.6, height: screenWidth / 8)
        case .qwerty:
            return CGSize(width: screenWidth / 12.2, height: screenWidth / 9)
        case .custard:
            return CGSize(width: screenWidth / 5.6, height: screenWidth / 8)
        }
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 5)
            .stroke()
            .frame(width: size.width, height: size.height)
            .overlay {
                Text(verbatim: "あ").font(.system(size: fontSize))
            }
    }
}
