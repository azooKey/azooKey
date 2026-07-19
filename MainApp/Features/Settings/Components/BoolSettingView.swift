//
//  BoolSettingView.swift
//  MainApp
//
//  Created by ensan on 2020/11/09.
//  Copyright © 2020 ensan. All rights reserved.
//

import AzooKeyUtils
import KeyboardViews
import SwiftUI
import SwiftUIUtils

struct BoolSettingView<SettingKey: BoolKeyboardSettingKey>: View {
    @State private var showRequireFullAccessAlert = false
    @State private var showOnEnabledMessageAlert = false
    @State private var onEnabledAlertMessage: LocalizedStringKey?
    @State private var setting: SettingUpdater<SettingKey>

    @MainActor init(_ key: SettingKey) {
        self._setting = .init(initialValue: .init())
    }

    private var toggle: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle(isOn: $setting.value) {
                HStack {
                    Text(SettingKey.title)
                    HelpAlertButton(title: SettingKey.title, explanation: SettingKey.explanation)
                    if SettingKey.requireFullAccess {
                        Image(systemName: "f.circle.fill")
                            .foregroundStyle(.purple)
                    }
                }
            }
            .toggleStyle(.switch)
        }
    }

    var body: some View {
        Group {
            if disabled {
                toggle
                    .disabled(true)
                    .onTapGesture {
                        showRequireFullAccessAlert = true
                    }
            } else {
                toggle
            }
        }
        .onAppear {
            setting.reload()
        }
        .onChange(of: setting.value) { (_, newValue) in
            if newValue {
                if let message = SettingKey.onEnabled() {
                    self.onEnabledAlertMessage = message
                    self.showOnEnabledMessageAlert = true
                }
            } else {
                SettingKey.onDisabled()
            }
        }
        .alert(SettingKey.explanation, isPresented: $showRequireFullAccessAlert) {
            Button("キャンセル", role: .cancel) {
                showRequireFullAccessAlert = false
            }
            if let url = URL(string: UIApplication.openSettingsURLString) {
                Button("「設定」アプリを開く") {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    showRequireFullAccessAlert = false
                }
            }
        } message: {
            Text("この機能にはフルアクセスが必要です。この機能を使いたい場合は、「設定」>「キーボード」でフルアクセスを有効にしてください。")
        }
        .alert(onEnabledAlertMessage ?? "", isPresented: $showOnEnabledMessageAlert) {
            Button("OK") {
                showOnEnabledMessageAlert = false
            }
        }
    }

    @MainActor private var disabled: Bool {
        SettingKey.requireFullAccess && !SemiStaticStates.shared.hasFullAccess
    }
}
