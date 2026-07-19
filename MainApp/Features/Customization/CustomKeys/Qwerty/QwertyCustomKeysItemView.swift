//
//  QwertyCustomKeysSettingView.swift
//  MainApp
//
//  Created by ensan on 2020/12/12.
//  Copyright © 2020 ensan. All rights reserved.
//

import AzooKeyUtils
import CustardKit
import KeyboardViews
import SwiftUI

private final class EditState: ObservableObject {
    enum State {
        case none, drag
    }

    @Published var state = State.none
    @Published var details = false

    var allowDrag: Bool {
        state == .drag
    }
    func toggle(_ state: State) {
        if self.state == state {
            self.state = .none
        } else {
            self.state = state
        }
    }
}

private protocol QwertyKey {
    var actions: [CodableActionData] {get set}
    var name: String {get set}
}

extension QwertyCustomKey: QwertyKey {}
extension QwertyVariationKey: QwertyKey {}

private extension QwertyCustomKeysValue {
    subscript(_ state: Selection) -> any QwertyKey {
        get {
            let sIndex = state.selectIndex
            let lpsIndex = state.longpressSelectIndex
            if lpsIndex == -1 && sIndex != -1 {
                return self.keys[sIndex]
            } else {
                return self.keys[sIndex].longpresses[lpsIndex]
            }
        }
        set {
            let sIndex = state.selectIndex
            guard sIndex >= 0 else {
                return
            }
            let lpsIndex = state.longpressSelectIndex
            if lpsIndex == -1, let key = newValue as? QwertyCustomKey {
                self.keys[sIndex] = key
            } else if let key = newValue as? QwertyVariationKey {
                self.keys[sIndex].longpresses[lpsIndex] = key
            }
        }
    }

    enum InputKey {case input}

    subscript(_ key: InputKey, _ state: Selection) -> String {
        get {
            if case let .input(value) = self[state].actions.first {
                return value
            }
            return ""
        }
        set {
            self[state].actions = [.input(newValue)]
        }
    }
}

private struct Selection: Hashable {
    var selectIndex = -1 {
        didSet {
            if selectIndex != -1 {
                self.longpressSelectIndex = -1
                self.enabled = true
                self.longpressEnabled = false
            } else {
                self.enabled = false
            }
        }
    }
    var longpressSelectIndex = -1 {
        didSet {
            self.enabled = longpressSelectIndex == -1
            self.longpressEnabled = longpressSelectIndex != -1
        }
    }
    var enabled = false
    var longpressEnabled = false
}

@MainActor
struct QwertyCustomKeysSettingView<SettingKey: QwertyCustomKeyKeyboardSetting>: View {
    @StateObject private var editState = EditState()
    @State private var setting = SettingUpdater<SettingKey>()
    @State private var selection = Selection()

    private var padding: CGFloat {
        spacing / 2
    }

    private let screenWidth = UIScreen.main.bounds.width

    private var keySize: CGSize {
        CGSize(width: screenWidth / 12.2, height: screenWidth / 9)
    }
    private var spacing: CGFloat {
        (screenWidth - keySize.width * 10) / (9 + 0.5)
    }
    private func romanScaledKeyWidth(normal: Int, for count: Int) -> CGFloat {
        let width = keySize.width * CGFloat(normal) + spacing * CGFloat(normal - 1)
        let necessarySpacing = spacing * CGFloat(count - 1)
        return (width - necessarySpacing) / CGFloat(count)
    }
    private var width: CGFloat {
        romanScaledKeyWidth(normal: 7, for: setting.value.keys.count)
    }
    private var variationWidth: CGFloat {
        romanScaledKeyWidth(normal: 7, for: 7)
    }

    init(_ key: SettingKey) {}

    var body: some View {
        VStack(spacing: 0) {
            Color.secondarySystemBackground
                .overlay {
                    VStack {
                        Spacer(minLength: 10)
                            .fixedSize()
                        if editState.allowDrag {
                            Text("キーをドラッグして移動してください。")
                                .padding(.vertical)
                        } else {
                            Text("編集したいキーを選択してください。")
                                .padding(.vertical)
                        }
                        if setting.value.keys.isEmpty {
                            Button("デフォルトに戻す") {
                                setting.value.keys = QwertyCustomKeysValue.defaultValue.keys
                                selection.longpressSelectIndex = -1
                            }
                        }
                        DraggableView(items: $setting.value.keys, selection: $selection.selectIndex, enabled: selection.enabled && editState.allowDrag, width: width, height: keySize.height, padding: padding) {item, isSelected in
                            let strokeColor: Color = {
                                if !isSelected {
                                    return .primary
                                }
                                if selection.longpressSelectIndex != -1 {
                                    return .systemGray
                                }
                                return .accentColor
                            }()
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(strokeColor)
                                .background {
                                    RoundedRectangle(cornerRadius: 10).fill(Color.background)
                                }
                                .compositingGroup()
                                .focus(.accentColor, focused: isSelected && selection.longpressSelectIndex == -1)
                                .focus(.systemGray, focused: isSelected && selection.longpressSelectIndex != -1)
                                .overlay {
                                    Text(item.name)
                                }
                        }
                        if setting.value.keys.indices ~= selection.selectIndex {
                            Spacer(minLength: 50)
                                .fixedSize()
                            Text("長押しした時の候補")
                                .padding(.vertical)
                            HStack {
                                DraggableView(items: $setting.value.keys[selection.selectIndex].longpresses, selection: $selection.longpressSelectIndex, enabled: selection.longpressEnabled && editState.allowDrag, width: variationWidth, height: keySize.height, padding: padding) {item, isSelected in
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(isSelected ? Color.accentColor : .primary)
                                        .background {
                                            RoundedRectangle(cornerRadius: 10).fill(Color.background)
                                        }
                                        .compositingGroup()
                                        .focus(.accentColor, focused: isSelected)
                                        .overlay {
                                            Text(item.name)
                                        }
                                }
                            }
                        }
                        Spacer()
                    }
                }
                .navigationTitle(Text("カスタムキーの設定"))
                .navigationBarTitleDisplayMode(.inline)
            Form {
                if setting.value.keys.indices ~= selection.selectIndex {
                    let binded = Binding(
                        get: { setting.value },
                        set: { setting.value = $0 }
                    )
                    Section(header: Text("移動・追加")) {
                        Button("このキーを並び替える") {
                            editState.toggle(.drag)
                        }
                        Button("キーを追加する") {
                            self.addPressKey()
                        }
                        Button("このキーに長押しキーを追加する") {
                            self.addLongpressKey(sIndex: selection.selectIndex)
                        }
                    }
                    Section(header: Text("入力")) {
                        if self.isInputTextEditable {
                            Text("キーを押して入力される文字を設定します。")
                            TextField("入力", text: binded[.input, selection])
                                .textFieldStyle(.roundedBorder)
                                .submitLabel(.done)
                        } else {
                            Text("このキーには入力以外のアクションが設定されています。現在のアクションを消去して入力する文字を設定するには「入力を設定する」を押してください")
                            Button("入力を設定する") {
                                setting.value[.input, selection] = ""
                            }
                            .foregroundStyle(.accentColor)
                        }
                    }
                    Section(header: Text("ラベル")) {
                        Text("キーに表示される文字を設定します。")
                        TextField("ラベル", text: binded[selection].name)
                            .textFieldStyle(.roundedBorder)
                            .submitLabel(.done)
                    }
                    Section(header: Text("アクション")) {
                        Text("キーを押したときの動作をより詳しく設定します。")
                        NavigationLink("アクションを編集する") {
                            CodableActionDataEditor(binded[selection].actions, availableCustards: CustardManager.load().availableCustards)
                        }
                        .foregroundStyle(.accentColor)
                    }
                    Button("削除", role: .destructive) {
                        if editState.state == .none {
                            let sIndex = selection.selectIndex
                            let lpsIndex = selection.longpressSelectIndex
                            if lpsIndex == -1 && sIndex != -1 {
                                selection.selectIndex = -1
                                // FIXME: 場当たり的な対処。`selection.selectIndex = -1`がViewに反映されてから削除を行う。
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                    setting.value.keys.remove(at: sIndex)
                                }
                            } else {
                                selection.longpressSelectIndex = -1
                                setting.value.keys[sIndex].longpresses.remove(at: lpsIndex)
                            }
                        }
                    }
                } else {
                    Button("キーを追加する") {
                        self.addPressKey()
                    }
                }
            }
            .onAppear {
                self.setting.value = SettingKey.value   // Stateの状態が元に戻ってしまう問題への応急処置
            }
            .onChange(of: selection) { (_, _) in
                editState.state = .none
            }
        }
    }

    private var isInputTextEditable: Bool {
        let actions = setting.value[selection].actions
        if actions.count == 1, case .input = actions.first {
            return true
        }
        if actions.isEmpty {
            return true
        }
        return false
    }

    private func addPressKey() {
        setting.value.keys.append(QwertyCustomKey(name: "", actions: [.input("")], longpresses: []))
        selection.selectIndex = setting.value.keys.endIndex - 1
    }

    private func addLongpressKey(sIndex: Int) {
        setting.value.keys[sIndex].longpresses.append(QwertyVariationKey(name: "", actions: [.input("")]))
        selection.longpressSelectIndex = setting.value.keys[sIndex].longpresses.endIndex - 1
    }
}
