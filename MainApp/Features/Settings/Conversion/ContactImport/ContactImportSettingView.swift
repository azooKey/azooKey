//
//  ContactImportSettingView.swift
//  azooKey
//
//  Created by miwa on 2023/09/23.
//  Copyright © 2023 DevEn3. All rights reserved.
//

import AzooKeyUtils
import KeyboardViews
import SwiftUI
import SwiftUIUtils

struct ContactImportSettingView: View {
    @State private var manager = ContactAuthManager()
    @State private var showRequireFullAccessAlert = false
    @State private var setting: SettingUpdater<EnableContactImport>
    @State private var showAuthErrorMessage = false
    @State private var authorized: Bool = false

    @MainActor init() {
        self._setting = .init(initialValue: .init())
    }

    @MainActor private var disabled: Bool {
        !SemiStaticStates.shared.hasFullAccess
    }

    @MainActor private var enabledButDenied: Bool {
        !disabled && setting.value && !self.authorized
    }

    @MainActor @ViewBuilder private var control: some View {
        Toggle(isOn: $setting.value) {
            HStack {
                Text(EnableContactImport.title)
                HelpAlertButton(title: EnableContactImport.title, explanation: EnableContactImport.explanation)
                Image(systemName: "f.circle.fill")
                    .foregroundStyle(.purple)
                if self.enabledButDenied {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.red)
                }
            }
        }
    }

    var body: some View {
        Group {
            if disabled {
                control
                    .disabled(true)
                    .onTapGesture {
                        showRequireFullAccessAlert = true
                    }
            } else if enabledButDenied {
                control
                    .disabled(true)
                    .onTapGesture {
                        showAuthErrorMessage = true
                    }
            } else {
                control
            }
        }
        .onChange(of: setting.value) { (_, enabled) in
            if enabled && manager.authState == .notDetermined {
                manager.requestAuthForContact { (granted, _) in
                    if !granted {
                        self.showAuthErrorMessage = true
                        self.authorized = false
                    } else {
                        self.authorized = true
                    }
                }
            } else if enabled && manager.authState == .denied {
                self.showAuthErrorMessage = true
            }
        }
        .onAppear {
            self.authorized = manager.authState == .authorized
            self.setting.reload()
        }
        .alert("設定を有効化できません", isPresented: $showAuthErrorMessage) {
            Button("「設定」アプリを開く") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
            Button("キャンセル", role: .cancel) {
                self.setting.value = false
            }
        } message: {
            Text("「連絡先」へのアクセスを許可する必要があります")
        }
        .alert(EnableContactImport.explanation, isPresented: $showRequireFullAccessAlert) {
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
    }
}
