import AzooKeyUtils
import CustardKit
import Foundation
import KeyboardViews
import SwiftUI
import SwiftUIUtils

struct CodableActionEditor: View {
    @Binding private var action: EditingCodableActionData
    private let availableCustards: [String]

    init(action: Binding<EditingCodableActionData>, availableCustards: [String]) {
        self._action = action
        self.availableCustards = availableCustards
    }

    var body: some View {
        switch action.data {
        case .moveTab:
            ActionMoveTabEditView($action, availableCustards: availableCustards)
        case let .smartDelete(item):
            ActionScanItemEditor(action: $action) { item } convert: { value in
                .smartDelete(CodableActionEditingService.normalized(value))
            }
        case let .smartMoveCursor(item):
            ActionScanItemEditor(action: $action) { item } convert: { value in
                .smartMoveCursor(CodableActionEditingService.normalized(value))
            }
        case let .replaceLastCharacters(pairs):
            ActionPairItemEditor(
                action: $action,
                initialValue: {
                    pairs.map { CodableActionReplacementPair(first: $0.key, second: $0.value) }
                },
                convert: {
                    .replaceLastCharacters(CodableActionEditingService.replacementDictionary(from: $0))
                }
            )
        case let .launchApplication(item):
            if item.target.hasPrefix("run-shortcut?") {
                ActionEditTextField(
                    "オプション",
                    action: $action,
                    initialValue: { String(item.target.dropFirst("run-shortcut?".count)) },
                    convert: { value in
                        .launchApplication(LaunchItem(scheme: .shortcuts, target: "run-shortcut?" + value))
                    }
                )
                FallbackLink(
                    "オプションの設定方法",
                    destination: URL(string: "https://support.apple.com/ja-jp/guide/shortcuts/apd624386f42/ios")!
                )
            } else {
                Text("このアプリでは編集できないアクションです")
            }
        case let .selectCandidate(item):
            ActionEditCandidateSelection(action: $action, initialValue: { item })
        case .replaceDefault:
            ActionReplaceBehaviorEditView($action)
        case .completeCharacterForm:
            ActionCompleteCharacterFormEditView($action)
        case .input, .directInput, .moveCursor, .delete, .paste, .complete,
             .smartDeleteDefault, .enableResizingMode, .toggleTabBar, .toggleCursorBar,
             .toggleCapsLockState, .dismissKeyboard:
            EmptyView()
        }
    }
}

struct EditableActionListLabel: View {
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
        .onChange(of: deleteValue) { _, newValue in
            if case .delete = action.data, let value = Int(newValue) {
                action.data = .delete(value)
            }
        }
        .onChange(of: moveCursorValue) { _, newValue in
            if case .moveCursor = action.data, let value = Int(newValue) {
                action.data = .moveCursor(value)
            }
        }
        .onChange(of: action.data) { _, newValue in
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
    let action: () -> Void
    let leftLabel: () -> LeftLabel
    let rightLabel: () -> RightLabel

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
    @State private var addItem = ""
    @State private var value = ScanItem(
        targets: CodableActionData.scanTargets,
        direction: .backward
    )

    init(
        action: Binding<EditingCodableActionData>,
        initialValue: () -> ScanItem?,
        convert: @escaping (ScanItem) -> CodableActionData?
    ) {
        self._action = action
        self.convert = convert
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
                                value.targets.removeAll { $0 == item }
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
        .onChange(of: value) { _, value in
            if let data = convert(value) {
                action.data = data
            }
        }
    }
}

struct ActionPairItemEditor: View {
    @Binding private var action: EditingCodableActionData
    private let convert: ([CodableActionReplacementPair]) -> CodableActionData?
    @State private var addFirstItem = ""
    @State private var addSecondItem = ""
    @State private var value: [CodableActionReplacementPair] = []

    init(
        action: Binding<EditingCodableActionData>,
        initialValue: () -> [CodableActionReplacementPair]?,
        convert: @escaping ([CodableActionReplacementPair]) -> CodableActionData?
    ) {
        self._action = action
        self.convert = convert
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
                        .disabled(true)
                } else {
                    Button("追加") {
                        value.append(.init(first: addFirstItem, second: addSecondItem))
                        addFirstItem = ""
                        addSecondItem = ""
                    }
                    .padding(.horizontal, 3)
                    .padding(.vertical, 7)
                    .background {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.systemGray5)
                    }
                    .disabled(addFirstItem.isEmpty)
                }
            }
            .textFieldStyle(.roundedBorder)
            .submitLabel(.done)
            .buttonStyle(.borderless)
            ScrollView(.horizontal) {
                HStack {
                    ForEach(value, id: \.self) { item in
                        ActionListItemView {
                            value.removeAll { $0 == item }
                        } leftLabel: {
                            Text(item.first + "→" + item.second)
                        } rightLabel: {
                            Label("削除", systemImage: "xmark")
                        }
                    }
                }
            }
        }
        .onChange(of: value) { _, value in
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
    @State private var value = ""

    init(
        _ title: LocalizedStringKey,
        action: Binding<EditingCodableActionData>,
        initialValue: () -> String?,
        convert: @escaping (String) -> CodableActionData?
    ) {
        self.title = title
        self._action = action
        self.convert = convert
        if let initialValue = initialValue() {
            self._value = State(initialValue: initialValue)
        }
    }

    var body: some View {
        TextField(title, text: $value)
            .onChange(of: value) { _, value in
                if let data = convert(value) {
                    action.data = data
                }
            }
            .textFieldStyle(.roundedBorder)
            .submitLabel(.done)
    }
}

private struct ActionEditCandidateSelection: View {
    private enum CandidateSelectionKey: String, Equatable, Hashable, Sendable, CaseIterable {
        case first
        case last
        case offset
        case exact

        init(from selection: CandidateSelection) {
            self = switch selection {
            case .first: .first
            case .last: .last
            case .offset: .offset
            case .exact: .exact
            }
        }
    }

    @State private var selectionType: CandidateSelectionKey = .first
    @State private var integerValue = ""
    @Binding private var action: EditingCodableActionData

    init(action: Binding<EditingCodableActionData>, initialValue: () -> CandidateSelection?) {
        self._action = action
        if let initialValue = initialValue() {
            self._selectionType = State(initialValue: .init(from: initialValue))
            switch initialValue {
            case .first, .last:
                self._integerValue = State(initialValue: "")
            case let .offset(value), let .exact(value):
                self._integerValue = State(initialValue: "\(value)")
            }
        }
    }

    private var resultCandidateSelection: CandidateSelection {
        switch selectionType {
        case .first:
            .first
        case .last:
            .last
        case .offset:
            .offset(Int(integerValue) ?? 0)
        case .exact:
            .exact(Int(integerValue) ?? 0)
        }
    }

    var body: some View {
        Group {
            Picker("選び方", selection: $selectionType) {
                Text("最初の候補").tag(CandidateSelectionKey.first)
                Text("最後の候補").tag(CandidateSelectionKey.last)
                Text("絶対位置の候補").tag(CandidateSelectionKey.exact)
                Text("相対位置の候補").tag(CandidateSelectionKey.offset)
            }
            switch selectionType {
            case .first, .last:
                EmptyView()
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
        .onChange(of: integerValue) {
            action.data = .selectCandidate(resultCandidateSelection)
        }
        .onChange(of: selectionType) {
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
        .onChange(of: replaceType) { _, newValue in
            action.data = .replaceDefault(.init(type: newValue, fallbacks: fallbacks))
        }
        Picker("フォールバック", selection: $fallbacks) {
            Text("デフォルト").tag([ReplaceBehavior.ReplaceType.default])
            Text("フォールバックなし").tag([ReplaceBehavior.ReplaceType]())
            if !(originalFallbacks.isEmpty || originalFallbacks == [.default]) {
                Text("オリジナル").tag(originalFallbacks)
            }
        }
        .onChange(of: fallbacks) { _, newValue in
            action.data = .replaceDefault(.init(type: replaceType, fallbacks: newValue))
        }
    }
}

private struct ActionCompleteCharacterFormEditView: View {
    @Binding private var action: EditingCodableActionData
    @State private var forms: [CharacterForm] = []
    @State private var targetForm: CharacterForm?

    init(_ action: Binding<EditingCodableActionData>) {
        self._action = action
        if case let .completeCharacterForm(forms) = action.wrappedValue.data {
            self._forms = State(initialValue: forms)
        }
    }

    var body: some View {
        HStack {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(forms.indices, id: \.self) { index in
                        ActionListItemView {
                            forms.remove(at: index)
                        } leftLabel: {
                            switch forms[index] {
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
                let allForms: [CharacterForm] = [
                    .hiragana,
                    .katakana,
                    .halfwidthKatakana,
                    .uppercase,
                    .lowercase,
                ]
                ForEach(allForms, id: \.self) {
                    Text($0.label).tag($0)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: targetForm) { _, newValue in
                if let newValue {
                    forms.removeAll { $0 == newValue }
                    forms.append(newValue)
                    action.data = .completeCharacterForm(forms)
                }
            }
        }
        .onChange(of: forms) { _, newValue in
            action.data = .completeCharacterForm(newValue)
        }
    }
}

private struct ActionMoveTabEditView: View {
    @Binding private var action: EditingCodableActionData
    private let availableCustards: [String]
    @State private var selectedTab: TabData = .system(.user_japanese)

    init(_ action: Binding<EditingCodableActionData>, availableCustards: [String]) {
        self._action = action
        self.availableCustards = availableCustards
        if case let .moveTab(value) = action.wrappedValue.data {
            self._selectedTab = State(initialValue: value)
        }
    }

    var body: some View {
        AvailableTabPicker(selectedTab, availableCustards: availableCustards) { _, tab in
            action.data = .moveTab(tab)
        }
    }
}

struct AvailableTabPicker: View {
    @State private var selectedTab: TabData
    private let items: [(label: String, tab: TabData)]
    private let process: (TabData, TabData) -> Void

    init(
        _ initialValue: TabData,
        availableCustards: [String]? = nil,
        onChange process: @escaping (TabData, TabData) -> Void = { _, _ in }
    ) {
        self._selectedTab = State(initialValue: initialValue)
        self.process = process
        var items: [(label: String, tab: TabData)] = [
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
        (availableCustards ?? CustardManager.load().availableCustards).forEach {
            items.insert(($0, .custom($0)), at: 0)
        }
        self.items = items
    }

    var body: some View {
        Picker(selection: $selectedTab, label: Text("移動先のタブ")) {
            ForEach(items.indices, id: \.self) { index in
                Text(LocalizedStringKey(items[index].label)).tag(items[index].tab)
            }
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            process(oldValue, newValue)
        }
    }
}

struct QuickActionPicker: View {
    struct Item: Identifiable {
        let id = UUID()
        let action: CodableActionData
        let systemImage: String
        let title: LocalizedStringKey
    }

    static var defaultRecommendation: [Item] {
        [
            .init(action: .input(""), systemImage: "character.cursor.ibeam", title: "入力"),
            .init(action: .directInput(""), systemImage: "text.badge.plus", title: "直接入力"),
            .init(action: .delete(1), systemImage: "delete.left", title: "削除"),
            .init(action: .moveTab(.system(.user_japanese)), systemImage: "arrow.right.square", title: "タブの移動"),
        ]
    }

    static var repeatRecommendation: [Item] {
        [
            .init(action: .input(""), systemImage: "character.cursor.ibeam", title: "入力"),
            .init(action: .directInput(""), systemImage: "text.badge.plus", title: "直接入力"),
            .init(action: .delete(1), systemImage: "delete.left", title: "削除"),
            .init(
                action: .moveCursor(1),
                systemImage: "arrowtriangle.left.and.line.vertical.and.arrowtriangle.right",
                title: "カーソル移動"
            ),
        ]
    }

    private let recommendation: [Item]
    private let perform: (CodableActionData) -> Void
    @State private var isActionPickerPresented = false

    init(
        recommendation: [Item] = Self.defaultRecommendation,
        perform: @escaping (CodableActionData) -> Void
    ) {
        self.recommendation = recommendation
        self.perform = perform
    }

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(), count: 4)) {
            ForEach(recommendation) { item in
                Button {
                    perform(item.action)
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
                isActionPickerPresented = true
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
        .sheet(isPresented: $isActionPickerPresented) {
            Form {
                ActionPicker { action in
                    perform(action)
                    isActionPickerPresented = false
                }
            }
            .presentationDetents([.fraction(0.4), .fraction(0.7)])
            .presentationBackgroundInteraction(.enabled)
        }
    }
}

struct ActionPicker: View {
    private enum Genre {
        case basic
        case advanced
    }

    private let perform: (CodableActionData) -> Void
    @State private var section: Genre = .basic

    init(perform: @escaping (CodableActionData) -> Void) {
        self.perform = perform
    }

    var body: some View {
        Section {
            Picker("セクション", selection: $section) {
                Text("基本").tag(Genre.basic)
                Text("高度").tag(Genre.advanced)
            }
            .pickerStyle(.segmented)
        }
        Section {
            switch section {
            case .basic:
                Button("文字の入力") {
                    perform(.input(""))
                }
                Button("文字の直接入力") {
                    perform(.directInput(""))
                }
                Button("タブの移動") {
                    perform(.moveTab(.system(.user_japanese)))
                }
                Button("タブバーの表示") {
                    perform(.toggleTabBar)
                }
                Button("カーソル移動") {
                    perform(.moveCursor(-1))
                }
                Button("文字の削除") {
                    perform(.delete(1))
                }
                if SemiStaticStates.shared.hasFullAccess {
                    Button("ペースト") {
                        perform(.paste)
                    }
                }
            case .advanced:
                Button("文頭まで削除") {
                    perform(.smartDeleteDefault)
                }
                Button("特定の文字まで削除") {
                    perform(.smartDelete(ScanItem(targets: ["。", "、", "\n"], direction: .backward)))
                }
                Button("特定の文字まで移動") {
                    perform(.smartMoveCursor(ScanItem(targets: ["。", "、", "\n"], direction: .backward)))
                }
                Button("末尾の文字を置換") {
                    perform(.replaceLastCharacters(["(^^)": "😄", "(TT)": "😭"]))
                }
                Button("特殊な置換") {
                    perform(.replaceDefault(.default))
                }
                Button("片手モードをオン") {
                    perform(.enableResizingMode)
                }
                Button("候補を選択") {
                    perform(.selectCandidate(.offset(1)))
                }
                Button("改行を入力") {
                    perform(.input("\n"))
                }
                Button("入力の確定") {
                    perform(.complete)
                }
                Button("文字種で入力を確定") {
                    perform(.completeCharacterForm([.hiragana]))
                }
                Button("Caps lock") {
                    perform(.toggleCapsLockState)
                }
                Button("カーソルバーの表示") {
                    perform(.toggleCursorBar)
                }
                Button("ショートカットを実行") {
                    perform(.launchApplication(.init(
                        scheme: .shortcuts,
                        target: "run-shortcut?name=[名前]&input=[入力]&text=[テキスト]"
                    )))
                }
                Button("キーボードを閉じる") {
                    perform(.dismissKeyboard)
                }
            }
        }
    }
}
