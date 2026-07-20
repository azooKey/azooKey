//
//  LanguageLayoutSettingView.swift
//  MainApp
//
//  Created by ensan on 2020/11/09.
//  Copyright © 2020 ensan. All rights reserved.
//

import AzooKeyUtils
import enum KanaKanjiConverterModule.KeyboardLanguage
import KeyboardViews
import SwiftUI
import SwiftUIUtils

extension LanguageLayout {
    var label: LocalizedStringKey {
        switch self {
        case .flick:
            return "フリック入力"
        case .qwerty:
            return "ローマ字入力"
        case let .custard(identifier):
            return LocalizedStringKey(identifier)
        }
    }
}

@MainActor
struct LanguageLayoutSettingView<SettingKey: LanguageLayoutKeyboardSetting>: View {
    @EnvironmentObject private var keyboardConfiguration: KeyboardConfigurationState
    @State private var selection: LanguageLayout = .flick
    @State private var ignoreChange = false
    private let custardManager = CustardManager.load()
    private let language: Language
    private let setTogether: Bool

    enum Language {
        case japanese
        case english

        var name: LocalizedStringKey {
            switch self {
            case .japanese:
                return "日本語"
            case .english:
                return "英語"
            }
        }
    }

    init(_ key: SettingKey, language: Language = .japanese, setTogether: Bool = false) {
        self.language = language
        self.setTogether = setTogether
        self._selection = State(initialValue: SettingKey.value)
        self.types = {
            let keyboardlanguage: KeyboardLanguage
            switch language {
            case .japanese:
                keyboardlanguage = .ja_JP
            case .english:
                keyboardlanguage = .en_US
            }
            return [.flick, .qwerty] + CustardManager.load().availableCustard(for: keyboardlanguage).map {.custard($0)}
        }()
    }

    private let types: [LanguageLayout]

    private var labelText: LocalizedStringKey {
        if setTogether {
            return "キーボードの種類 (現在: \(selection.label))"
        } else {
            return "\(language.name)キーボードの種類 (現在: \(selection.label))"
        }
    }

    private var tab: ResolvedTab {
        switch (selection, language) {
        case (.flick, .japanese):
            return .standard(.flick_japanese)
        case (.flick, .english):
            return .standard(.flick_english)
        case (.qwerty, .japanese):
            return .standard(.qwerty_japanese)
        case (.qwerty, .english):
            return .standard(.qwerty_english)
        case let (.custard(identifier), _):
            if let custard = try? custardManager.custard(identifier: identifier) {
                return .custard(custard)
            } else {
                return .custard(.errorMessage)
            }
        }
    }

    var body: some View {
        Group {
            // ラベルの数でUIを出し分ける
            if types.count > 3 {
                Picker(selection: $selection, label: Text(labelText)) {
                    ForEach(0 ..< types.count, id: \.self) { i in
                        Text(types[i].label).tag(types[i])
                    }
                }
                CenterAlignedView {
                    KeyboardPreview(
                        sizing: .fitToExtension,
                        defaultTab: tab
                    )
                        .allowsHitTesting(false)
                        .disabled(true)
                }
            } else {
                VStack {
                    Text(labelText)
                    CenterAlignedView {
                        KeyboardPreview(
                            sizing: .fitToExtension,
                            defaultTab: tab
                        )
                            .allowsHitTesting(false)
                            .disabled(true)
                    }
                    Picker(selection: $selection, label: Text(labelText)) {
                        ForEach(0 ..< types.count, id: \.self) { i in
                            Text(types[i].label).tag(types[i])
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                }
            }
        }
        .onChange(of: selection) { (_, _) in
            if ignoreChange {
                return
            }
            let type = selection
            SettingKey.value = type
            switch language {
            case .japanese:
                keyboardConfiguration.japaneseLayout = type
            case .english:
                keyboardConfiguration.englishLayout = type
            }
            if setTogether {
                EnglishKeyboardLayout.value = type
                keyboardConfiguration.englishLayout = type
            }
        }
        .onAppear {
            self.ignoreChange = true
            self.selection = SettingKey.value
            self.ignoreChange = false
        }
        .onDisappear {
            self.ignoreChange = true
        }
    }
}
