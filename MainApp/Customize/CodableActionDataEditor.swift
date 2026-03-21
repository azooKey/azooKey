//
//  KeyActionsEditView.swift
//  MainApp
//
//  Created by ensan on 2021/02/21.
//  Copyright © 2021 ensan. All rights reserved.
//

import AzooKeyUtils
import CustardKit
import Foundation
import KeyboardViews
import SwiftUI
import SwiftUIUtils

fileprivate extension CharacterForm {
    var label: LocalizedStringKey {
        switch self {
        case .hiragana: "ひらがな"
        case .katakana: "カタカナ"
        case .halfwidthKatakana: "半角カタカナ"
        case .lowercase: "小文字"
        case .uppercase: "大文字"
        }
    }
}

extension CodableActionData {
    var hasAssociatedValue: Bool {
        switch self {
        case .input, .directInput, .moveCursor, .delete: false
        case .smartDelete, .replaceLastCharacters, .replaceDefault, .smartMoveCursor, .moveTab, .launchApplication, .selectCandidate, .completeCharacterForm: true
        case  .enableResizingMode, .complete, .smartDeleteDefault, .toggleCapsLockState, .toggleCursorBar, .toggleTabBar, .dismissKeyboard, .paste: false
        }
    }

    private func stringArrayDescription(_ array: [String]) -> String {
        array.map {$0 == "\n" ? "改行" : "'\($0)'"}.joined(separator: ", ")
    }

    var label: LocalizedStringKey {
        switch self {
        case let .input(value): return if value != "\n" {
            "「\(value)」を入力"
        } else {
            "改行を入力"
        }
        case let .directInput(value): return "「\(value)」を直接入力"
        case let .moveCursor(value): return "\(String(value))文字分カーソルを移動"
        case let .smartMoveCursor(value): return "\(stringArrayDescription(value.targets))の隣までカーソルを移動"
        case let .delete(value): return "\(String(value))文字削除"
        case let .smartDelete(value): return "\(stringArrayDescription(value.targets))の隣まで削除"
        case .paste: return "ペーストする"
        case .moveTab: return "タブの移動"
        case .replaceLastCharacters: return "末尾の文字を置換"
        case let .selectCandidate(selection):
            return switch selection {
            case .first: "最初の候補を選択"
            case .last: "最後の候補を選択"
            case .offset(let value): "\(value)個隣の候補を選択"
            case .exact(let value): "\(value)番目の候補を選択"
            }
        case .complete: return "確定"
        case .completeCharacterForm: return "文字種で入力を確定"
        case .replaceDefault: return "特殊な置換"
        case .smartDeleteDefault: return "文頭まで削除"
        case .toggleCapsLockState: return "Caps lockのモードの切り替え"
        case .toggleCursorBar: return "カーソルバーの切り替え"
        case .toggleTabBar: return "タブバーの切り替え"
        case .dismissKeyboard: return "キーボードを閉じる"
        case .enableResizingMode: return "片手モードをオンにする"
        case let .launchApplication(value):
            switch value.scheme {
            case .azooKey:
                return "azooKey本体アプリを開く"
            case .shortcuts:
                return "ショートカットを実行する"
            }
        }
    }
}

struct EditingCodableActionData: Identifiable, Equatable {
    typealias ID = UUID
    let id = UUID()
    var data: CodableActionData
    init(_ data: CodableActionData) {
        self.data = data
    }
}

struct CodableActionDataEditor: View {
    @State private var editMode = EditMode.inactive
    @State private var bottomSheetShown = false
    @State private var actions: [EditingCodableActionData]
    @Binding private var data: [CodableActionData]
    private let availableCustards: [String]

    init(_ actions: Binding<[CodableActionData]>, availableCustards: [String]) {
        self._data = actions
        self._actions = State(initialValue: actions.wrappedValue.map {EditingCodableActionData($0)})
        self.availableCustards = availableCustards
    }

    private func add(new action: CodableActionData) {
        withAnimation(Animation.interactiveSpring()) {
            actions.append(EditingCodableActionData(action))
        }
    }

    var body: some View {
        Form {
            Section(header: Text("アクション"), footer: Text("上から順に実行されます")) {
                if actions.isEmpty {
                    QuickActionPicker {
                        add(new: $0)
                    }
                } else {
                    DisclosuringList($actions) { $action in
                        CodableActionEditor(action: $action, availableCustards: availableCustards)
                    } label: { $action in
                        EditableActionListLabel(action: $action) {
                            actions.removeAll(where: {$0.id == $action.wrappedValue.id})
                        }
                    }
                    .onDelete(perform: delete)
                    .onMove(perform: onMove)
                    .disclosed { item in item.data.hasAssociatedValue }
                    Button {
                        self.bottomSheetShown = true
                    } label: {
                        HStack {
                            Image(systemName: "plus")
                            Text("アクションを追加")
                        }
                    }
                }
            }
        }
        .onChange(of: actions) { (_, _) in
            self.data = actions.map {$0.data}
        }
        .sheet(isPresented: $bottomSheetShown) {
            Form {
                ActionPicker { action in
                    self.add(new: action)
                    self.bottomSheetShown = false
                }
            }
            .presentationDetents([.fraction(0.4), .fraction(0.7)])
            .presentationBackgroundInteraction(.enabled)
        }
        .navigationBarTitle(Text("動作の編集"), displayMode: .inline)
        .navigationBarItems(trailing: editButton)
        .environment(\.editMode, $editMode)
    }

    @ViewBuilder
    private var editButton: some View {
        switch editMode {
        case .inactive:
            Button("削除と順番") {
                editMode = .active
            }
        case .active, .transient:
            EditConfirmButton(.done) {
                editMode = .inactive
            }
        @unknown default:
            EditConfirmButton(.done) {
                editMode = .inactive
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        actions.remove(atOffsets: offsets)
    }

    private func onMove(source: IndexSet, destination: Int) {
        actions.move(fromOffsets: source, toOffset: destination)
    }
}

private struct CodableActionEditor: View {
    init(action: Binding<EditingCodableActionData>, availableCustards: [String]) {
        self.availableCustards = availableCustards
        self._action = action
    }

    @Binding private var action: EditingCodableActionData
    private let availableCustards: [String]

    var body: some View {
        switch action.data {
        case .moveTab:
            ActionMoveTabEditView($action, availableCustards: availableCustards)
        case .smartDelete(let item):
            ActionScanItemEditor(action: $action) { item } convert: { value in
                // 重複を除去し、改行を追加する
                let targets = Array(value.targets.uniqued())
                return .smartDelete(ScanItem(targets: targets, direction: value.direction))
            }
        case .smartMoveCursor(let item):
            ActionScanItemEditor(action: $action) { item } convert: { value in
                // 重複を除去し、改行を追加する
                let targets = Array(value.targets.uniqued())
                return .smartMoveCursor(ScanItem(targets: targets, direction: value.direction))
            }
        case let .replaceLastCharacters(pairs):
            ActionPairItemEditor(action: $action) { pairs.map {.init(first: $0.key, second: $0.value)} } convert: { value in
                // 重複を除去し、改行を追加する
                let items = Dictionary(value.uniqued().map {(key: $0.first, value: $0.second)}, uniquingKeysWith: {first, _ in first})
                return .replaceLastCharacters(items)
            }
        case let .launchApplication(item):
            if item.target.hasPrefix("run-shortcut?") {
                ActionEditTextField("オプション", action: $action) {String(item.target.dropFirst("run-shortcut?".count))} convert: {value in
                    .launchApplication(LaunchItem(scheme: .shortcuts, target: "run-shortcut?" + value))
                }
                FallbackLink("オプションの設定方法", destination: URL(string: "https://support.apple.com/ja-jp/guide/shortcuts/apd624386f42/ios")!)
            } else {
                Text("このアプリでは編集できないアクションです")
            }
        case .selectCandidate(let item):
            ActionEditCandidateSelection(action: $action, initialValue: {item})
        case .replaceDefault:
            ActionReplaceBehaviorEditView($action)
        case .completeCharacterForm:
            ActionCompleteCharacterFormEditView($action)
        case .input, .directInput, .moveCursor, .delete, .paste, .complete, .smartDeleteDefault, .enableResizingMode, .toggleTabBar, .toggleCursorBar, .toggleCapsLockState, .dismissKeyboard:
            EmptyView()
        }
    }
}

private struct EditableActionListLabel: View {
    @Environment(\.editMode) private var editMode
    @Binding private var action: EditingCodableActionData
    private let onDelete: () -> Void
    @State private var deleteValue = ""
    @State private var moveCursorValue = ""

    init(action: Binding<EditingCodableActionData>, onDelete: @escaping () -> Void) {
        self._action = action
        self.onDelete = onDelete
        if case let .delete(value) = action.wrappedValue.data {
            self._deleteValue = State(initialValue: "\(value)")
        }
        if case let .moveCursor(value) = action.wrappedValue.data {
            self._moveCursorValue = State(initialValue: "\(value)")
        }
    }

    private var isEditingList: Bool {
        editMode?.wrappedValue.isEditing == true
    }

    private var inputTextBinding: Binding<String> {
        Binding(
            get: {
                switch action.data {
                case let .input(value), let .directInput(value):
                    return value
                default:
                    return ""
                }
            },
            set: { newValue in
                switch action.data {
                case .input:
                    action.data = .input(newValue)
                case .directInput:
                    action.data = .directInput(newValue)
                default:
                    break
                }
            }
        )
    }

    var body: some View {
        Group {
            if isEditingList {
                Text(action.data.label)
            } else {
                switch action.data {
                case .input("\n"):
                    Text(action.data.label)
                case .input:
                    HStack {
                        TextField("文字", text: inputTextBinding)
                            .textFieldStyle(.roundedBorder)
                            .submitLabel(.done)
                        Text("を入力")
                            .foregroundStyle(.secondary)
                    }
                case .directInput:
                    HStack {
                        TextField("文字", text: inputTextBinding)
                            .textFieldStyle(.roundedBorder)
                            .submitLabel(.done)
                        Text("を直接入力")
                            .foregroundStyle(.secondary)
                    }
                case .delete:
                    HStack {
                        IntegerTextField("値", text: $deleteValue, range: .min ... .max)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .submitLabel(.done)
                        Text("文字削除")
                            .foregroundStyle(.secondary)
                    }
                case .moveCursor:
                    HStack {
                        IntegerTextField("値", text: $moveCursorValue, range: .min ... .max)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .submitLabel(.done)
                        Text("文字移動")
                            .foregroundStyle(.secondary)
                    }
                default:
                    Text(action.data.label)
                }
            }
        }
        .onChange(of: deleteValue) { (_, newValue) in
            if case .delete = action.data, let value = Int(newValue) {
                action.data = .delete(value)
            }
        }
        .onChange(of: moveCursorValue) { (_, newValue) in
            if case .moveCursor = action.data, let value = Int(newValue) {
                action.data = .moveCursor(value)
            }
        }
        .onChange(of: action.data) { (_, newValue) in
            if case let .delete(value) = newValue, deleteValue != "\(value)" {
                deleteValue = "\(value)"
            }
            if case let .moveCursor(value) = newValue, moveCursorValue != "\(value)" {
                moveCursorValue = "\(value)"
            }
        }
        .contextMenu {
            Button("削除", systemImage: "trash", role: .destructive) {
                onDelete()
            }
        }
    }
}

private struct ActionListItemView<LeftLabel: View, RightLabel: View>: View {
    init(action: @escaping () -> Void, leftLabel: @escaping () -> LeftLabel, rightLabel: @escaping () -> RightLabel) {
        self.action = action
        self.leftLabel = leftLabel
        self.rightLabel = rightLabel
    }

    var action: () -> Void
    var leftLabel: () -> LeftLabel
    var rightLabel: () -> RightLabel

    var body: some View {
        HStack {
            leftLabel()
                .padding(.horizontal)
            Divider()
            Button {
                action()
            } label: {
                rightLabel()
                    .padding(4)
                    .contentShape(Rectangle())
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
        }
        .background {
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.systemGray5)
        }
    }
}

private struct ActionScanItemEditor: View {
    @Binding private var action: EditingCodableActionData
    private let convert: (ScanItem) -> CodableActionData?
    @State private var addItem: String = ""
    @State private var value: ScanItem = .init(targets: CodableActionData.scanTargets, direction: .backward)

    init(action: Binding<EditingCodableActionData>, initialValue: () -> ScanItem?, convert: @escaping (ScanItem) -> CodableActionData?) {
        self.convert = convert
        self._action = action
        if let initialValue = initialValue() {
            self._value = State(initialValue: initialValue)
        }
    }

    var body: some View {
        Group {
            Picker("方向", selection: $value.direction) {
                Text("左向き").tag(ScanItem.Direction.backward)
                Text("右向き").tag(ScanItem.Direction.forward)
            }
            .pickerStyle(.menu)
            HStack {
                TextField("目指す文字を追加", text: $addItem)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.done)
                if value.targets.contains(addItem) {
                    Button("追加済", systemImage: "plus") {}
                        .buttonStyle(.borderless)
                        .labelStyle(.titleOnly)
                        .disabled(true)
                        .padding(7)
                        .background {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.systemGray5)
                        }
                } else {
                    Button("追加", systemImage: "plus") {
                        value.targets.append(addItem)
                        addItem = ""
                    }
                    .buttonStyle(.borderless)
                    .labelStyle(.titleOnly)
                    .disabled(addItem.isEmpty)
                    .padding(7)
                    .background {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.systemGray5)
                    }

                }
            }
            HStack {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(value.targets, id: \.self) { item in
                            ActionListItemView {
                                value.targets.removeAll(where: { $0 == item })
                            } leftLabel: {
                                if item == "\n" {
                                    Text("改行")
                                } else {
                                    Text(item)
                                }
                            } rightLabel: {
                                Label("削除", systemImage: "xmark")
                            }
                        }
                    }
                }
                if !value.targets.contains("\n") {
                    Spacer()
                    Divider()
                    HStack {
                        ActionListItemView {
                            value.targets.append("\n")
                        } leftLabel: {
                            Text("改行")
                        } rightLabel: {
                            Label("追加", systemImage: "plus")
                        }
                    }
                }
            }
        }
        .onChange(of: value) { (_, value) in
            if let data = convert(value) {
                action.data = data
            }
        }
    }
}

private struct ActionPairItemEditor: View {
    struct Pair: Equatable, Hashable {
        var first: String
        var second: String
    }
    @Binding private var action: EditingCodableActionData
    private let convert: ([Pair]) -> CodableActionData?
    @State private var addFirstItem: String = ""
    @State private var addSecondItem: String = ""
    @State private var value: [Pair] = []

    init(action: Binding<EditingCodableActionData>, initialValue: () -> [Pair]?, convert: @escaping ([Pair]) -> CodableActionData?) {
        self.convert = convert
        self._action = action
        if let initialValue = initialValue() {
            self._value = State(initialValue: initialValue)
        }
    }

    var body: some View {
        Group {
            HStack {
                TextField("置換前", text: $addFirstItem)
                TextField("置換後", text: $addSecondItem)
                if value.contains(where: { $0.first == addFirstItem }) {
                    Button("追加済") {}
                        .padding(.horizontal, 3)
                        .padding(.vertical, 7)
                        .background {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.systemGray5)
                        }
                        .disabled(true) // addSecondItemは空白でも良い
                } else {
                    Button("追加") {
                        self.value.append(.init(first: addFirstItem, second: addSecondItem))
                        addFirstItem = ""
                        addSecondItem = ""
                    }
                    .padding(.horizontal, 3)
                    .padding(.vertical, 7)
                    .background {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.systemGray5)
                    }
                    .disabled(addFirstItem.isEmpty) // addSecondItemは空白でも良い
                }
            }
            .textFieldStyle(.roundedBorder)
            .submitLabel(.done)
            .buttonStyle(.borderless)
            HStack {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(self.value, id: \.self) { item in
                            ActionListItemView {
                                value.removeAll(where: { $0 == item })
                            } leftLabel: {
                                Text(item.first + "→" + item.second)
                            } rightLabel: {
                                Label("削除", systemImage: "xmark")
                            }
                        }
                    }
                }
            }
        }
        .onChange(of: value) { (_, value) in
            if let data = convert(value) {
                action.data = data
            }
        }
    }
}

private struct ActionEditTextField: View {
    private let title: LocalizedStringKey
    @Binding private var action: EditingCodableActionData
    private let convert: (String) -> CodableActionData?
    init(_ title: LocalizedStringKey, action: Binding<EditingCodableActionData>, initialValue: () -> String?, convert: @escaping (String) -> CodableActionData?) {
        self.title = title
        self.convert = convert
        self._action = action
        if let initialValue = initialValue() {
            self._value = State(initialValue: initialValue)
        }
    }

    @State private var value = ""

    var body: some View {
        TextField(title, text: $value)
            .onChange(of: value) { (_, value) in
                if let data = convert(value) {
                    action.data = data
                }
            }
            .textFieldStyle(.roundedBorder)
            .submitLabel(.done)
    }
}

private struct ActionEditCandidateSelection: View {

    private enum CandidateSelectionKeys: String, Equatable, Hashable, Sendable, CaseIterable {
        case first, last, offset, exact
        init(from selection: CandidateSelection) {
            self = switch selection {
            case .first: .first
            case .last: .last
            case .offset: .offset
            case .exact: .exact
            }
        }
    }

    init(action: Binding<EditingCodableActionData>, initialValue: () -> CandidateSelection?) {
        self._action = action
        if let initialValue = initialValue() {
            self._selectionType = State(initialValue: .init(from: initialValue))
            switch initialValue {
            case .first, .last:
                self._integerValue = State(initialValue: "")
            case .offset(let int), .exact(let int):
                self._integerValue = State(initialValue: "\(int)")
            }
        }
    }

    @State private var selectionType: CandidateSelectionKeys = .first
    @State private var integerValue = ""
    @Binding private var action: EditingCodableActionData

    private var resultCandidateSelection: CandidateSelection {
        switch selectionType {
        case .first:
            .first
        case .last:
            .last
        case .offset:
            .offset(Int(self.integerValue) ?? 0)
        case .exact:
            .exact(Int(self.integerValue) ?? 0)
        }
    }

    var body: some View {
        Group {
            Picker("選び方", selection: $selectionType) {
                Text("最初の候補").tag(CandidateSelectionKeys.first)
                Text("最後の候補").tag(CandidateSelectionKeys.last)
                Text("絶対位置の候補").tag(CandidateSelectionKeys.exact)
                Text("相対位置の候補").tag(CandidateSelectionKeys.offset)
            }
            switch self.selectionType {
            case .first, .last: EmptyView()
            case .offset:
                IntegerTextField("値", text: $integerValue, range: .min ... .max)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.done)
            case .exact:
                IntegerTextField("値", text: $integerValue, range: 0 ... .max)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.done)
            }
        }
        .onChange(of: integerValue) { (_, _) in
            action.data = .selectCandidate(resultCandidateSelection)
        }
        .onChange(of: selectionType) { (_, _) in
            action.data = .selectCandidate(resultCandidateSelection)
        }
    }
}

private struct ActionReplaceBehaviorEditView: View {
    @Binding private var action: EditingCodableActionData
    @State private var replaceType: ReplaceBehavior.ReplaceType = .default
    @State private var fallbacks: [ReplaceBehavior.ReplaceType] = []
    @State private var originalFallbacks: [ReplaceBehavior.ReplaceType] = []

    init(_ action: Binding<EditingCodableActionData>) {
        self._action = action
        if case let .replaceDefault(value) = action.wrappedValue.data {
            self._replaceType = State(initialValue: value.type)
            self._fallbacks = State(initialValue: value.fallbacks)
            self._originalFallbacks = State(initialValue: value.fallbacks)
        }
    }

    var body: some View {
        Picker("置換のタイプ", selection: $replaceType) {
            Text("大文字/小文字、拗音/濁音/半濁音の切り替え").tag(ReplaceBehavior.ReplaceType.default)
            Text("濁点をつける").tag(ReplaceBehavior.ReplaceType.dakuten)
            Text("半濁点をつける").tag(ReplaceBehavior.ReplaceType.handakuten)
            Text("小書きにする").tag(ReplaceBehavior.ReplaceType.kogaki)
        }
        .onChange(of: replaceType) { (_, newValue) in
            self.action.data = .replaceDefault(.init(type: newValue, fallbacks: self.fallbacks))
        }
        Picker("フォールバック", selection: $fallbacks) {
            Text("デフォルト").tag([ReplaceBehavior.ReplaceType.default])
            Text("フォールバックなし").tag([ReplaceBehavior.ReplaceType]())
            if !(originalFallbacks.isEmpty || originalFallbacks == [.default]) {
                Text("オリジナル").tag(originalFallbacks)
            }
        }
        .onChange(of: fallbacks) { (_, newValue) in
            self.action.data = .replaceDefault(.init(type: self.replaceType, fallbacks: newValue))
        }
    }
}

private struct ActionCompleteCharacterFormEditView: View {
    @Binding private var action: EditingCodableActionData
    @State private var forms: [CharacterForm] = []
    @State private var originalFallbacks: [CharacterForm] = []
    @State private var targetForm: CharacterForm?

    init(_ action: Binding<EditingCodableActionData>) {
        self._action = action
        if case let .completeCharacterForm(forms) = action.wrappedValue.data {
            self._forms = State(initialValue: forms)
            self._originalFallbacks = State(initialValue: forms)
        }
    }

    var body: some View {
        HStack {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(self.forms.indices, id: \.self) { i in
                        ActionListItemView {
                            self.forms.remove(at: i)
                        } leftLabel: {
                            switch self.forms[i] {
                            case .hiragana: Text(verbatim: "あ")
                            case .katakana: Text(verbatim: "ア")
                            case .halfwidthKatakana: Text(verbatim: "ｱ")
                            case .uppercase: Text(verbatim: "A")
                            case .lowercase: Text(verbatim: "a")
                            }
                        } rightLabel: {
                            Label("削除", systemImage: "xmark")
                        }
                    }
                }
            }
            Picker("追加", selection: $targetForm) {
                let allForms: [CharacterForm] = [.hiragana, .katakana, .halfwidthKatakana, .uppercase, .lowercase]
                ForEach(allForms, id: \.self) {
                    Text($0.label).tag($0)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: targetForm) { (_, newValue) in
                if let newValue {
                    if self.forms.contains(newValue) {
                        self.forms.removeAll(where: { $0 == newValue })
                    }
                    self.forms.append(newValue)
                    self.action.data = .completeCharacterForm(self.forms)
                }
            }
        }
        .onChange(of: self.forms) { (_, newValue) in
            self.action.data = .completeCharacterForm(newValue)
        }
    }
}

private struct ActionMoveTabEditView: View {
    @Binding private var action: EditingCodableActionData
    private let availableCustards: [String]
    @State private var selectedTab: TabData = .system(.user_japanese)

    init(_ action: Binding<EditingCodableActionData>, availableCustards: [String]) {
        self.availableCustards = availableCustards
        self._action = action
        if case let .moveTab(value) = action.wrappedValue.data {
            self._selectedTab = State(initialValue: value)
        }
    }

    var body: some View {
        AvailableTabPicker(selectedTab, availableCustards: self.availableCustards) { (_, tab) in
            self.action.data = .moveTab(tab)
        }
    }
}

extension TabData {
    var label: LocalizedStringKey {
        switch self {
        case let .system(tab):
            switch tab {
            case .user_japanese:
                return "日本語(設定に合わせる)"
            case .user_english:
                return "英語(設定に合わせる)"
            case .flick_japanese:
                return "日本語(フリック入力)"
            case .flick_english:
                return "英語(フリック入力)"
            case .flick_numbersymbols:
                return "記号と数字(フリック入力)"
            case .qwerty_japanese:
                return "日本語(ローマ字入力)"
            case .qwerty_english:
                return "英語(ローマ字入力)"
            case .qwerty_numbers:
                return "数字(ローマ字入力)"
            case .qwerty_symbols:
                return "記号(ローマ字入力)"
            case .last_tab:
                return "最後に表示していたタブ"
            case .clipboard_history_tab:
                return "クリップボードの履歴"
            case .emoji_tab:
                return "絵文字"
            }
        case let .custom(identifier):
            return LocalizedStringKey(identifier)
        }
    }
}

struct AvailableTabPicker: View {
    @State private var selectedTab: TabData = .system(.user_japanese)
    private let items: [(label: String, tab: TabData)]
    private let process: (TabData, TabData) -> Void

    init(_ initialValue: TabData, availableCustards: [String]? = nil, onChange process: @escaping (TabData, TabData) -> Void = {_, _ in}) {
        self._selectedTab = State(initialValue: initialValue)
        self.process = process
        var dict: [(label: String, tab: TabData)] = [
            ("日本語(設定に合わせる)", .system(.user_japanese)),
            ("英語(設定に合わせる)", .system(.user_english)),
            ("記号と数字(フリック入力)", .system(.flick_numbersymbols)),
            ("数字(ローマ字入力)", .system(.qwerty_numbers)),
            ("記号(ローマ字入力)", .system(.qwerty_symbols)),
            ("絵文字", .system(.emoji_tab)),
            ("クリップボードの履歴", .system(.clipboard_history_tab)),
            ("最後に表示していたタブ", .system(.last_tab)),
            ("日本語(フリック入力)", .system(.flick_japanese)),
            ("日本語(ローマ字入力)", .system(.qwerty_japanese)),
            ("英語(フリック入力)", .system(.flick_english)),
            ("英語(ローマ字入力)", .system(.qwerty_english)),
        ]
        (availableCustards ?? CustardManager.load().availableCustards) .forEach {
            dict.insert(($0, .custom($0)), at: 0)
        }
        self.items = dict
    }

    var body: some View {
        Picker(selection: $selectedTab, label: Text("移動先のタブ")) {
            ForEach(items.indices, id: \.self) {i in
                Text(LocalizedStringKey(items[i].label)).tag(items[i].tab)
            }
        }
        .onChange(of: selectedTab) {
            self.process($0, $1)
        }
    }
}

struct CodableLongpressActionDataEditor: View {
    @State private var editMode = EditMode.inactive
    @State private var bottomSheetShown = false
    @State private var addTarget: AddTarget = .start

    private enum AddTarget {
        case `repeat`
        case start
    }

    @State private var startActions: [EditingCodableActionData]
    @State private var repeatActions: [EditingCodableActionData]
    @Binding private var data: CodableLongpressActionData
    private let availableCustards: [String]

    init(_ actions: Binding<CodableLongpressActionData>, availableCustards: [String]) {
        self._data = actions
        self._startActions = State(initialValue: actions.wrappedValue.start.map {EditingCodableActionData($0)})
        self._repeatActions = State(initialValue: actions.wrappedValue.repeat.map {EditingCodableActionData($0)})
        self.availableCustards = availableCustards
    }

    private func add(new action: CodableActionData) {
        withAnimation(Animation.interactiveSpring()) {
            switch self.addTarget {
            case .start:
                startActions.append(EditingCodableActionData(action))
            case .repeat:
                repeatActions.append(EditingCodableActionData(action))
            }
        }
    }

    var body: some View {
        Form {
            Section {
                Picker("長押しの長さ", selection: $data.duration) {
                    Text("標準").tag(CodableLongpressActionData.LongpressDuration.normal)
                    Text("軽く").tag(CodableLongpressActionData.LongpressDuration.light)
                }
            }
            Section(header: Text("押し始めのアクション"), footer: Text("上から順に実行されます")) {
                if startActions.isEmpty {
                    QuickActionPicker {
                        self.addTarget = .start
                        add(new: $0)
                    }
                } else {
                    DisclosuringList($startActions) { $action in
                        CodableActionEditor(action: $action, availableCustards: availableCustards)
                    } label: { $action in
                        EditableActionListLabel(action: $action) {
                            startActions.removeAll(where: {$0.id == $action.wrappedValue.id})
                        }
                    }
                    .onDelete(perform: {startActions.remove(atOffsets: $0)})
                    .onMove(perform: {startActions.move(fromOffsets: $0, toOffset: $1)})
                    .disclosed { item in item.data.hasAssociatedValue }
                    Button {
                        self.addTarget = .start
                        self.bottomSheetShown = true
                    } label: {
                        HStack {
                            Image(systemName: "plus")
                            Text("アクションを追加")
                        }
                    }
                }
            }
            Section(header: Text("押している間のアクション"), footer: Text("繰り返し実行されます")) {
                if repeatActions.isEmpty {
                    QuickActionPicker(recommendation: [
                        .init(action: .input(""), systemImage: "character.cursor.ibeam", title: "入力"),
                        .init(action: .directInput(""), systemImage: "text.badge.plus", title: "直接入力"),
                        .init(action: .delete(1), systemImage: "delete.left", title: "削除"),
                        .init(action: .moveCursor(1), systemImage: "arrowtriangle.left.and.line.vertical.and.arrowtriangle.right", title: "カーソル移動"),
                    ]) {
                        self.addTarget = .repeat
                        add(new: $0)
                    }
                } else {
                    DisclosuringList($repeatActions) { $action in
                        CodableActionEditor(action: $action, availableCustards: availableCustards)
                    } label: { $action in
                        EditableActionListLabel(action: $action) {
                            repeatActions.removeAll(where: {$0.id == $action.wrappedValue.id})
                        }
                    }
                    .onDelete(perform: {repeatActions.remove(atOffsets: $0)})
                    .onMove(perform: {repeatActions.move(fromOffsets: $0, toOffset: $1)})
                    .disclosed { item in item.data.hasAssociatedValue }
                    Button {
                        self.addTarget = .repeat
                        self.bottomSheetShown = true
                    } label: {
                        HStack {
                            Image(systemName: "plus")
                            Text("アクションを追加")
                        }
                    }
                }
            }
        }
        .onChange(of: startActions) { (_, value) in
            self.data.start = value.map {$0.data}
        }
        .onChange(of: repeatActions) { (_, value) in
            self.data.repeat = value.map {$0.data}
        }
        .sheet(isPresented: $bottomSheetShown) {
            Form {
                ActionPicker { action in
                    self.add(new: action)
                    self.bottomSheetShown = false
                }
            }
            .presentationDetents([.fraction(0.4), .fraction(0.7)])
            .presentationBackgroundInteraction(.enabled)
        }
        .navigationBarTitle(Text("動作の編集"), displayMode: .inline)
        .navigationBarItems(trailing: editButton)
        .environment(\.editMode, $editMode)
    }

    @ViewBuilder
    private var editButton: some View {
        switch editMode {
        case .inactive:
            Button("編集") {
                editMode = .active
            }
        case .active, .transient:
            EditConfirmButton(.done) {
                editMode = .inactive
            }
        @unknown default:
            EditConfirmButton(.done) {
                editMode = .inactive
            }
        }
    }
}

private struct QuickActionPicker: View {
    private let process: (CodableActionData) -> Void
    private let recommendation: [Item]
    @State private var openCompleteActionPicker = false

    init(recommendation: [Item] = Self.defaultRecommendation, process: @escaping (CodableActionData) -> Void) {
        self.recommendation = recommendation
        self.process = process
    }

    static var defaultRecommendation: [Item] {
        [
            .init(action: .input(""), systemImage: "character.cursor.ibeam", title: "入力"),
            .init(action: .directInput(""), systemImage: "text.badge.plus", title: "直接入力"),
            .init(action: .delete(1), systemImage: "delete.left", title: "削除"),
            .init(action: .moveTab(.system(.user_japanese)), systemImage: "arrow.right.square", title: "タブの移動"),
        ]
    }
    struct Item: Identifiable {
        var id = UUID()
        var action: CodableActionData
        var systemImage: String
        var title: LocalizedStringKey
    }

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(), count: 4)) {
            ForEach(recommendation) { item in
                Button {
                    process(item.action)
                } label: {
                    VStack {
                        Image(systemName: item.systemImage)
                            .frame(width: 45, height: 45)
                            .foregroundStyle(.white)
                            .background(.tint)
                            .cornerRadius(10)
                        Text(item.title)
                            .font(.caption)
                    }
                }
                .buttonStyle(.plain)
            }
            Button {
                self.openCompleteActionPicker = true
            } label: {
                VStack {
                    Image(systemName: "ellipsis")
                        .frame(width: 45, height: 45)
                        .foregroundStyle(.white)
                        .background(.tint)
                        .cornerRadius(10)
                    Text("その他")
                        .font(.caption)
                }
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $openCompleteActionPicker) {
            Form {
                ActionPicker { action in
                    process(action)
                    self.openCompleteActionPicker = false
                }
            }
            .presentationDetents([.fraction(0.4), .fraction(0.7)])
            .presentationBackgroundInteraction(.enabled)
        }
    }
}

private struct ActionPicker: View {
    private let process: (CodableActionData) -> Void
    private enum Genre {
        case basic
        case advanced
    }

    init(process: @escaping (CodableActionData) -> Void) {
        self.process = process
    }

    @State private var section: Genre = .basic

    var body: some View {
        Section {
            Picker("セクション", selection: $section) {
                Text("基本").tag(Genre.basic)
                Text("高度").tag(Genre.advanced)
            }
            .pickerStyle(.segmented)
        }
        Section {
            switch self.section {
            case .basic:
                Button("文字の入力") {
                    process(.input(""))
                }
                Button("文字の直接入力") {
                    process(.directInput(""))
                }
                Button("タブの移動") {
                    process(.moveTab(.system(.user_japanese)))
                }
                Button("タブバーの表示") {
                    process(.toggleTabBar)
                }
                Button("カーソル移動") {
                    process(.moveCursor(-1))
                }
                Button("文字の削除") {
                    process(.delete(1))
                }
                if SemiStaticStates.shared.hasFullAccess {
                    Button("ペースト") {
                        process(.paste)
                    }
                }
            case .advanced:
                Button("文頭まで削除") {
                    process(.smartDeleteDefault)
                }
                Button("特定の文字まで削除") {
                    process(.smartDelete(ScanItem(targets: ["。", "、", "\n"], direction: .backward)))
                }
                Button("特定の文字まで移動") {
                    process(.smartMoveCursor(ScanItem(targets: ["。", "、", "\n"], direction: .backward)))
                }
                Button("末尾の文字を置換") {
                    process(.replaceLastCharacters(["(^^)": "😄", "(TT)": "😭"]))
                }
                Button("特殊な置換") {
                    process(.replaceDefault(.default))
                }
                Button("片手モードをオン") {
                    process(.enableResizingMode)
                }
                Button("候補を選択") {
                    process(.selectCandidate(.offset(1)))
                }
                Button("改行を入力") {
                    process(.input("\n"))
                }
                Button("入力の確定") {
                    process(.complete)
                }
                Button("文字種で入力を確定") {
                    process(.completeCharacterForm([.hiragana]))
                }
                Button("Caps lock") {
                    process(.toggleCapsLockState)
                }
                Button("カーソルバーの表示") {
                    process(.toggleCursorBar)
                }
                Button("ショートカットを実行") {
                    process(.launchApplication(.init(scheme: .shortcuts, target: "run-shortcut?name=[名前]&input=[入力]&text=[テキスト]")))
                }
                Button("キーボードを閉じる") {
                    process(.dismissKeyboard)
                }
            }
        }
    }
}
