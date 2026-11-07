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

    @State private var containerWidth: CGFloat = UIScreen.main.bounds.width

    private var screenWidth: CGFloat { containerWidth }

    private var keySize: CGSize {
        CGSize(width: screenWidth / 12.2, height: screenWidth / 9)
    }
    private var spacing: CGFloat {
        (screenWidth - keySize.width * 10) / (9 + 0.5)
    }
    private func romanScaledKeyWidth(normal: Int, for count: Int) -> CGFloat {
        let width = keySize.width * CGFloat(normal) + spacing * CGFloat(normal - 1)
        let necessarySpacing = spacing * CGFloat(count - 1)
        return (width - necessarySpacing) / CGFloat(max(1, count))
    }
    private var width: CGFloat {
        romanScaledKeyWidth(normal: 7, for: setting.value.keys.count)
    }
    private var variationWidth: CGFloat {
        romanScaledKeyWidth(normal: 7, for: 7)
    }

    init(_ key: SettingKey) {}

    var body: some View {
        AdaptiveEditorView {
            Form { editorSections(adaptive: true) }
        } preview: {
            ScrollView {
                keyPreview(adaptive: true)
                    .frame(maxWidth: .infinity)
                    .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width in
                        if width > 0 { containerWidth = width }
                    }
            }
            .background(Color.secondarySystemBackground)
        } legacy: {
            VStack(spacing: 0) {
                Color.secondarySystemBackground
                    .overlay { keyPreview(adaptive: false) }
                Form { editorSections(adaptive: false) }
            }
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width in
                if width > 0 { containerWidth = width }
            }
        }
        .navigationTitle("カスタムキーの設定")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            self.setting.value = SettingKey.value
        }
        .onChange(of: selection) { _, _ in
            editState.state = .none
        }
    }

    private func keyPreview(adaptive: Bool) -> some View {
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
            DraggableView(items: $setting.value.keys, selection: $selection.selectIndex, enabled: selection.enabled && editState.allowDrag, width: width, height: keySize.height, padding: padding, scrollsHorizontally: adaptive) {item, isSelected in
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
                    DraggableView(items: $setting.value.keys[selection.selectIndex].longpresses, selection: $selection.longpressSelectIndex, enabled: selection.longpressEnabled && editState.allowDrag, width: variationWidth, height: keySize.height, padding: padding, scrollsHorizontally: adaptive) {item, isSelected in
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

    @ViewBuilder private func editorSections(adaptive: Bool) -> some View {
        if adaptive {
            Section("編集するキー") {
                Picker("キー", selection: $selection.selectIndex) {
                    Text("選択してください").tag(-1)
                    ForEach(setting.value.keys.indices, id: \.self) { index in
                        Text(setting.value.keys[index].name.isEmpty ? "キー \(index + 1)" : setting.value.keys[index].name).tag(index)
                    }
                }
                if setting.value.keys.indices.contains(selection.selectIndex) {
                    Picker("長押し候補", selection: $selection.longpressSelectIndex) {
                        Text("通常のキー").tag(-1)
                        ForEach(setting.value.keys[selection.selectIndex].longpresses.indices, id: \.self) { index in
                            Text(setting.value.keys[selection.selectIndex].longpresses[index].name).tag(index)
                        }
                    }
                }
            }
        }
        if setting.value.keys.indices ~= selection.selectIndex {
            let binded = Binding(
                get: { setting.value },
                set: { setting.value = $0 }
            )
            Section(header: Text("移動・追加")) {
                if adaptive {
                    Button("左へ移動", systemImage: "arrow.left") { moveSelectedKey(by: -1) }
                        .disabled(!canMoveSelection(by: -1))
                    Button("右へ移動", systemImage: "arrow.right") { moveSelectedKey(by: 1) }
                        .disabled(!canMoveSelection(by: 1))
                }
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
            if adaptive && setting.value.keys.isEmpty {
                Button("デフォルトに戻す") {
                    setting.value.keys = QwertyCustomKeysValue.defaultValue.keys
                    selection.selectIndex = -1
                }
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

    private func canMoveSelection(by offset: Int) -> Bool {
        guard setting.value.keys.indices.contains(selection.selectIndex) else {
            return false
        }
        if selection.longpressSelectIndex >= 0 {
            return setting.value.keys[selection.selectIndex].longpresses.indices.contains(selection.longpressSelectIndex + offset)
        }
        return setting.value.keys.indices.contains(selection.selectIndex + offset)
    }

    private func moveSelectedKey(by offset: Int) {
        guard canMoveSelection(by: offset) else {
            return
        }
        if selection.longpressSelectIndex >= 0 {
            let source = selection.longpressSelectIndex
            setting.value.keys[selection.selectIndex].longpresses.swapAt(source, source + offset)
            selection.longpressSelectIndex = source + offset
        } else {
            let source = selection.selectIndex
            setting.value.keys.swapAt(source, source + offset)
            selection.selectIndex = source + offset
        }
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
