//
//  AdditionalDictManageView.swift
//  MainApp
//
//  Created by ensan on 2020/11/13.
//  Copyright © 2020 ensan. All rights reserved.
//

import AzooKeyUtils
import Foundation
import KeyboardViews
import SwiftUI

protocol OnOffSettingSet {
    associatedtype Target: Hashable, CaseIterable, RawRepresentable where Target.RawValue == String
    var state: [Target: Bool] { get set }
}

extension OnOffSettingSet {
    subscript(_ key: Target) -> Bool {
        get {
            state[key, default: false]
        }
        set {
            state[key] = newValue
        }
    }
}

struct AdditionalSystemDictManager: OnOffSettingSet {
    var state: [AdditionalSystemDictionarySetting.SystemDictionaryType: Bool]

    init(dataList: [String]) {
        self.state = Target.allCases.reduce(into: [:]) {dict, target in
            dict[target] = dataList.contains(target.rawValue)
        }
    }
}

struct AdditionalDictBlockManager: OnOffSettingSet {
    var state: [Target: Bool]

    init(dataList: [String]) {
        self.state = Target.allCases.reduce(into: [:]) {dict, target in
            dict[target] = dataList.contains(target.rawValue)
        }
    }

    enum Target: String, CaseIterable {
        case gokiburi
        case spiders

        var characters: [String] {
            switch self {
            case .gokiburi:
                return ["\u{1FAB3}"]
            case .spiders:
                return ["🕸", "🕷"]
            }
        }
    }
}

final class AdditionalDictManager: ObservableObject {
    @MainActor @Published var systemDict: AdditionalSystemDictManager {
        didSet {
            self.userDictUpdate()
        }
    }

    @MainActor @Published var blockTargets: AdditionalDictBlockManager {
        didSet {
            self.userDictUpdate()
        }
    }

    @MainActor init() {
        let systemDictList = UserDefaults.standard.array(forKey: "additional_dict") as? [String]
        self.systemDict = .init(dataList: systemDictList ?? [])

        let blockList = UserDefaults.standard.array(forKey: "additional_dict_blocks") as? [String]
        self.blockTargets = .init(dataList: blockList ?? [])
    }

    @MainActor func userDictUpdate() {
        var additionalSystemDictionaries: [AdditionalSystemDictionarySetting.SystemDictionaryType] = []
        var blockTargets: [String] = []

        // MARK: AdditionalSystemDictionarySettingKeyが存在する場合はこれを優先する
        // MARK: この処理はv2.4系まで維持し、v2.5系以降は削除する。マイグレーションに成功しない可能性があるが、この設定はそれほど深刻ではないので、あまり考えずにやってしまってよい。
        if AdditionalSystemDictionarySettingKey.available {
            for (type, item) in AdditionalSystemDictionarySettingKey.value.systemDictionarySettings {
                if item.enabled {
                    additionalSystemDictionaries.append(type)
                }
                blockTargets.append(contentsOf: item.denylist)
            }
        } else {
            AdditionalSystemDictManager.Target.allCases.forEach { target in
                if self.systemDict[target] {
                    additionalSystemDictionaries.append(target)
                }
            }
            var blocklist: [String] = []
            AdditionalDictBlockManager.Target.allCases.forEach { target in
                if self.blockTargets[target] {
                    blocklist.append(target.rawValue)
                    blockTargets.append(contentsOf: target.characters)
                }
            }
            UserDefaults.standard.setValue(additionalSystemDictionaries.map(\.rawValue), forKey: "additional_dict")
            UserDefaults.standard.setValue(blocklist, forKey: "additional_dict_blocks")
        }
        let builder = UserDictionaryUpdater(
            additionalSystemDictionaries: additionalSystemDictionaries,
            denylist: Set(blockTargets)
        )
        builder.process()
        // MARK: v2.3→v2.4のMigration処理
        // 元々コンテナApp内部でのみ管理していた絵文字関連の設定情報をキーボード拡張との共有情報にするための処理
        if !AdditionalSystemDictionarySettingKey.available {
            // 設定が移植できていない場合の処理
            AdditionalSystemDictionarySettingKey.value = .init(systemDictionarySettings: [
                .emoji: .init(enabled: self.systemDict[.emoji], denylist: Set(blockTargets)),
                .kaomoji: .init(enabled: self.systemDict[.kaomoji]),
            ])
        }
    }
}

@MainActor
private struct ClassicAdditionalDictManageViewMain: View {
    let style: AdditionalDictManageViewMain.Style
    @StateObject private var viewModel = AdditionalDictManager()

    var body: some View {
        Section(header: Text("利用するもの")) {
            Toggle(isOn: $viewModel.systemDict[.emoji]) {
                Text("絵文字")
                Text(verbatim: "🥺🌎♨️")
            }
            Toggle(isOn: $viewModel.systemDict[.kaomoji]) {
                Text("顔文字")
                Text(verbatim: "(◍•ᴗ•◍)")
            }
        }
        if self.style == .all {
            Section(header: Text("不快な絵文字を表示しない")) {
                Toggle("ゴキブリの絵文字を非表示", isOn: $viewModel.blockTargets[.gokiburi])
                Toggle("クモの絵文字を非表示", isOn: $viewModel.blockTargets[.spiders])
            }
        }
    }
}

extension AdditionalSystemDictionarySetting {
    enum DictionaryEnabled {
        case enabled
    }
    subscript(type: Self.SystemDictionaryType, query query: DictionaryEnabled) -> Bool {
        get {
            self.systemDictionarySettings[type, default: .init(enabled: false)].enabled
        }
        set {
            self.systemDictionarySettings[type, default: .init(enabled: false)].enabled = newValue
        }
    }
    enum DenyTargetAddition {
        case denylist
    }
    subscript(type: Self.SystemDictionaryType, characters: Set<String>, query query: DenyTargetAddition) -> Bool {
        get {
            self.systemDictionarySettings[type, default: .init(enabled: false)].denylist.isSuperset(of: characters)
        }
        set {
            if newValue {
                self.systemDictionarySettings[type, default: .init(enabled: false)].denylist.formUnion(characters)
            } else {
                self.systemDictionarySettings[type, default: .init(enabled: false)].denylist.subtract(characters)
            }
        }
    }
}

@MainActor
private struct NewerAdditionalDictManageViewMain: View {
    let style: AdditionalDictManageViewMain.Style
    @State private var setting = SettingUpdater<AdditionalSystemDictionarySettingKey>()

    var body: some View {
        Group {
            Section(header: Text("利用するもの")) {
                Toggle(isOn: $setting.value[.emoji, query: .enabled]) {
                    Text("絵文字")
                    Text(verbatim: "🥺🌎♨️")
                }
                Toggle(isOn: $setting.value[.kaomoji, query: .enabled]) {
                    Text("顔文字")
                    Text(verbatim: "(◍•ᴗ•◍)")
                }
            }
            if self.style == .all {
                Section(header: Text("不快な絵文字を表示しない")) {
                    Toggle("ゴキブリの絵文字を非表示", isOn: $setting.value[.emoji, ["\u{1FAB3}"], query: .denylist])
                    Toggle("蚊の絵文字を非表示", isOn: $setting.value[.emoji, ["🦟"], query: .denylist])
                    Toggle("クモの絵文字を非表示", isOn: $setting.value[.emoji, ["🕸", "🕷"], query: .denylist])
                    Toggle("ミミズの絵文字を非表示", isOn: $setting.value[.emoji, ["🪱"], query: .denylist])
                }
                .disabled(!setting.value[.emoji, query: .enabled])
            }
        }
        .onChange(of: self.setting.value) { (_, _) in
            AdditionalDictManager().userDictUpdate()
        }
    }
}

@MainActor
struct AdditionalDictManageViewMain: View {
    enum Style {
        case simple
        case all
    }
    private let style: Style
    init(style: Style = .all) {
        self.style = style
    }

    var body: some View {
        if AdditionalSystemDictionarySettingKey.available {
            // v2.4以降
            NewerAdditionalDictManageViewMain(style: style)
        } else {
            // v2.3以前
            ClassicAdditionalDictManageViewMain(style: style)
        }
    }

}

struct AdditionalDictManageView: View {
    @EnvironmentObject private var reviewPrompt: RequestReviewManager
    var body: some View {
        Form {
            AdditionalDictManageViewMain()
        }
        .navigationBarTitle(Text("絵文字と顔文字"), displayMode: .inline)
        .onDisappear {
            reviewPrompt.shouldTryRequestReview = true
        }
    }
}
