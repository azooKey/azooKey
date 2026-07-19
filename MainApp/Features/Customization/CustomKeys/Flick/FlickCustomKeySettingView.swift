//
//  FlickCustomKeySettingView.swift
//  MainApp
//
//  Created by ensan on 2020/12/27.
//  Copyright © 2020 ensan. All rights reserved.
//

import AzooKeyUtils
import CustardKit
import Foundation
import KeyboardViews
import SwiftUI

extension WritableKeyPath<KeyFlickSetting, FlickCustomKey>: @unchecked @retroactive Sendable {}

fileprivate extension FlickKeyPosition {
    var keyPath: WritableKeyPath<KeyFlickSetting, FlickCustomKey> {
        switch self {
        case .left:
            return \.left
        case .top:
            return \.top
        case .right:
            return \.right
        case .bottom:
            return \.bottom
        case .center:
            return \.center
        }
    }

    var bindedKeyPath: KeyPath<Binding<KeyFlickSetting>, Binding<FlickCustomKey>> {
        switch self {
        case .left:
            return \.left
        case .top:
            return \.top
        case .right:
            return \.right
        case .bottom:
            return \.bottom
        case .center:
            return \.center
        }
    }
}

private extension KeyFlickSetting {
    enum InputKey { case input }
    subscript(_ key: InputKey, position: FlickKeyPosition) -> String {
        get {
            if case let .input(value) = self[keyPath: position.keyPath].actions.first {
                return value
            }
            return ""
        }
        set {
            self[keyPath: position.keyPath].actions = [.input(newValue)]
        }
    }

    enum LabelKey { case label }
    subscript(_ key: LabelKey, position: FlickKeyPosition) -> String {
        get {
            self[keyPath: position.keyPath].label
        }
        set {
            self[keyPath: position.keyPath].label = newValue
        }
    }

}

struct FlickCustomKeysSettingSelectView: View {
    @State private var selection: CustomizableFlickKey = .kogana
    var body: some View {
        VStack {
            Picker(selection: $selection, label: Text("カスタムするキー")) {
                Text(verbatim: "小ﾞﾟ").tag(CustomizableFlickKey.kogana)
                Text(verbatim: "､｡?!").tag(CustomizableFlickKey.kanaSymbols)
                Text(verbatim: "あいう").tag(CustomizableFlickKey.hiraTab)
                Text(verbatim: "ABC").tag(CustomizableFlickKey.abcTab)
                Text(verbatim: "☆123").tag(CustomizableFlickKey.symbolsTab)
            }
            .pickerStyle(.segmented)
            .padding()

            switch selection {
            case .kogana:
                FlickCustomKeySettingView(.koganaFlickCustomKey)
            case .kanaSymbols:
                FlickCustomKeySettingView(.kanaSymbolsFlickCustomKey)
            case .hiraTab:
                FlickCustomKeySettingView(.hiraTabFlickCustomKey)
            case .abcTab:
                FlickCustomKeySettingView(.abcTabFlickCustomKey)
            case .symbolsTab:
                FlickCustomKeySettingView(.symbolsTabFlickCustomKey)
            }
        }
        .background(Color.secondarySystemBackground)
    }
}

struct FlickCustomKeySettingView<SettingKey: FlickCustomKeyKeyboardSetting>: View {
    @State private var bottomSheetShown = false
    @State private var selectedPosition: FlickKeyPosition = .center
    @State private var setting: SettingUpdater<SettingKey>

    @MainActor init(_ key: SettingKey) {
        self._setting = .init(initialValue: .init())
    }

    @MainActor private var screenWidth: CGFloat { UIScreen.main.bounds.width }

    @MainActor private var keySize: CGSize {
        CGSize(width: screenWidth / 5.6, height: screenWidth / 8)
    }
    @MainActor private var spacing: CGFloat {
        (screenWidth - keySize.width * 5) / 5
    }

    /// おすすめ設定
    private var preset: [(label: LocalizedStringKey, item: KeyFlickSetting)] {
        switch self.setting.value.identifier {
        case .kogana:
            [
                ("デフォルト", CustomizableFlickKey.kogana.defaultSetting),
                ("丸括弧", KeyFlickSetting(
                    identifier: .kogana,
                    center: CustomizableFlickKey.kogana.defaultSetting.center,
                    left: .init(label: "（", actions: [.input("（")]),
                    top: .init(label: "", actions: []),
                    right: .init(label: "）", actions: [.input("）")]),
                    bottom: .init(label: "", actions: [])
                )),
                ("Android風", KeyFlickSetting(
                    identifier: .kogana,
                    center: CustomizableFlickKey.kogana.defaultSetting.center,
                    left: .init(label: "゛", actions: [.replaceDefault(.init(type: .dakuten, fallbacks: [.default]))]),
                    top: .init(label: "あぁ", actions: [.replaceDefault(.init(type: .kogaki, fallbacks: [.default]))]),
                    right: .init(label: "゜", actions: [.replaceDefault(.init(type: .handakuten, fallbacks: [.default]))]),
                    bottom: .init(label: "", actions: [])
                )),
            ]
        case .kanaSymbols:
            [
                ("デフォルト", CustomizableFlickKey.kanaSymbols.defaultSetting),
                ("コンマとピリオド", KeyFlickSetting(
                    identifier: .kanaSymbols,
                    center: .init(label: ",.?!", actions: [.input("，")]),
                    left: .init(label: "．", actions: [.input("．")]),
                    top: .init(label: "？", actions: [.input("？")]),
                    right: .init(label: "！", actions: [.input("！")]),
                    bottom: .init(label: "", actions: [])
                )),
                ("半角!?", KeyFlickSetting(
                    identifier: .kanaSymbols,
                    center: .init(label: "､｡?!", actions: [.input("、")]),
                    left: .init(label: "．", actions: [.input("。")]),
                    top: .init(label: "?", actions: [.input("?")]),
                    right: .init(label: "!", actions: [.input("!")]),
                    bottom: .init(label: "", actions: [])
                )),
                ("句読点で確定", KeyFlickSetting(
                    identifier: .kanaSymbols,
                    center: .init(label: "､｡?!", actions: [.complete, .input("、")]),
                    left: .init(label: "．", actions: [.complete, .input("。")]),
                    top: .init(label: "？", actions: [.input("？")]),
                    right: .init(label: "！", actions: [.input("！")]),
                    bottom: .init(label: "", actions: [])
                )),
            ]
        case .hiraTab, .symbolsTab, .abcTab:
            []
        }
    }

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Text("編集したい方向を選択してください。")
                    .padding(.vertical)

                VStack {
                    CustomKeySettingFlickKeyView(.top, label: setting.value[.label, .top], selectedPosition: $selectedPosition)
                        .frame(width: keySize.width, height: keySize.height)
                    HStack {
                        CustomKeySettingFlickKeyView(.left, label: setting.value[.label, .left], selectedPosition: $selectedPosition)
                            .frame(width: keySize.width, height: keySize.height)
                        CustomKeySettingFlickKeyView(.center, label: setting.value[.label, .center], selectedPosition: $selectedPosition)
                            .frame(width: keySize.width, height: keySize.height)
                        CustomKeySettingFlickKeyView(.right, label: setting.value[.label, .right], selectedPosition: $selectedPosition)
                            .frame(width: keySize.width, height: keySize.height)
                    }
                    CustomKeySettingFlickKeyView(.bottom, label: setting.value[.label, .bottom], selectedPosition: $selectedPosition)
                        .frame(width: keySize.width, height: keySize.height)
                }
                if !preset.isEmpty {
                    Picker("プリセットから選ぶ", selection: $setting.value) {
                        ForEach(preset, id: \.item) { (label, item) in
                            Text(label).tag(item)
                        }
                        if !preset.map(\.item).contains(self.setting.value) {
                            Text("カスタム")
                                .tag(self.setting.value)
                        }
                    }
                    .pickerStyle(.menu)
                }
                Spacer()
            }
            .navigationBarTitle("カスタムキーの設定", displayMode: .inline)
            .onChange(of: selectedPosition) { (_, _) in
                bottomSheetShown = true
            }
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            BottomSheetView(
                isOpen: self.$bottomSheetShown,
                maxHeight: geometry.size.height * 0.7
            ) {
                Form {
                    if isPossiblePosition(selectedPosition) {
                        switch mainEditor {
                        case .input:
                            Section(header: Text("入力")) {
                                if self.isInputActionEditable(actions: setting.value[keyPath: selectedPosition.keyPath].actions) {
                                    Text("キーを押して入力される文字を設定します。")
                                    TextField("入力", text: Binding(
                                                get: {
                                                    setting.value[.input, selectedPosition]
                                                },
                                                set: {
                                                    setting.value[.input, selectedPosition] = $0
                                                }))
                                        .textFieldStyle(.roundedBorder)
                                        .submitLabel(.done)
                                } else {
                                    Text("このキーには入力以外のアクションが設定されています。現在のアクションを消去して入力する文字を設定するには「入力を設定する」を押してください")
                                    Button("入力を設定する") {
                                        setting.value[.input, selectedPosition] = ""
                                    }
                                    .foregroundStyle(.accentColor)
                                }
                            }
                        case .tab:
                            Section(header: Text("タブ")) {
                                let tab = self.getTab(actions: setting.value[keyPath: selectedPosition.keyPath].actions)
                                if tab != nil || setting.value[keyPath: selectedPosition.keyPath].actions.isEmpty {
                                    Text("キーを押して移動するタブを設定します。")
                                    AvailableTabPicker(tab ?? .system(.user_japanese)) { (_, tabData) in
                                        setting.value[keyPath: selectedPosition.keyPath].actions = [.moveTab(tabData)]
                                    }
                                } else {
                                    tabSetter(keyPath: selectedPosition.keyPath)
                                }
                            }
                        }
                        Section(header: Text("ラベル")) {
                            Text("キーに表示される文字を設定します。")
                            TextField("ラベル", text: Binding(
                                        get: {
                                            setting.value[.label, selectedPosition]
                                        },
                                        set: {
                                            setting.value[.label, selectedPosition] = $0
                                        }))
                                .textFieldStyle(.roundedBorder)
                                .submitLabel(.done)
                        }
                        Section(header: Text("アクション")) {
                            Text("キーを押したときの動作をより詳しく設定します。")
                            NavigationLink("アクションを編集する") {
                                CodableActionDataEditor($setting.value[keyPath: selectedPosition.bindedKeyPath].actions, availableCustards: CustardManager.load().availableCustards)
                            }
                            .foregroundStyle(.accentColor)
                        }
                        Section(header: Text("長押しアクション")) {
                            Text("キーを長押ししたときの動作をより詳しく設定します。")
                            NavigationLink("長押しアクションを編集する") {
                                CodableLongpressActionDataEditor($setting.value[keyPath: selectedPosition.bindedKeyPath].longpressActions, availableCustards: CustardManager.load().availableCustards)
                            }
                            .foregroundStyle(.accentColor)
                        }
                        Button("リセット") {
                            self.reload()
                        }
                        .foregroundStyle(.red)
                    } else {
                        Text("このキーは編集できません")
                    }
                }
                .foregroundStyle(.primary)
            }
        }
    }

    @MainActor @ViewBuilder private func tabSetter(keyPath: WritableKeyPath<KeyFlickSetting, FlickCustomKey>) -> some View {
        Text("このキーにはタブ移動以外のアクションが設定されています。現在のアクションを消去して移動するタブを設定するには「タブを設定する」を押してください")
        Button("タブを設定する") {
            setting.value[keyPath: keyPath].actions = [.moveTab(.system(.user_japanese))]
        }
        .foregroundStyle(.accentColor)
    }

    @MainActor private func isPossiblePosition(_ position: FlickKeyPosition) -> Bool {
        setting.value.identifier.ablePosition.contains(position)
    }

    private func isInputActionEditable(actions: [CodableActionData]) -> Bool {
        if actions.count == 1, case .input = actions.first {
            return true
        }
        if actions.isEmpty {
            return true
        }
        return false
    }

    private func getTab(actions: [CodableActionData]) -> TabData? {
        if actions.count == 1, let action = actions.first, case let .moveTab(value) = action {
            return value
        }
        return nil
    }

    @MainActor private func reload() {
        if self.isPossiblePosition(selectedPosition) {
            setting.value[keyPath: selectedPosition.keyPath] = setting.value.identifier.defaultSetting[keyPath: selectedPosition.keyPath]
        }
    }

    private enum MainEditorSpecifier {
        case input
        case tab
    }

    @MainActor private var mainEditor: MainEditorSpecifier {
        switch setting.value.identifier {
        case .kanaSymbols, .kogana:
            return .input
        case .hiraTab, .abcTab, .symbolsTab:
            return .tab
        }
    }
}
