//
//  CustardInterfaceKeyEditor.swift
//  MainApp
//
//  Created by ensan on 2021/04/23.
//  Copyright © 2021 ensan. All rights reserved.
//

import AzooKeyUtils
import CustardKit
import Foundation
import KeyboardViews
import SwiftUI
import SwiftUIUtils
import UniformTypeIdentifiers

// Stable ID wrapper for longpress chip items
private struct IndexedLongpressItem: Identifiable, Hashable {
    let id: UUID
    let index: Int
}
private enum LabelType: Equatable {
    case text, systemImage, mainAndSub
}
// 共通のラベル選択肢（自動を含む）
private enum LabelSelection: Equatable {
    case auto, text, systemImage, mainAndSub
}

// MARK: 共通セクションビュー
private struct LabelEditorSection: View {
    @Binding var selection: LabelSelection
    @Binding var labelText: String
    @Binding var labelImageName: String
    @Binding var labelMain: String
    @Binding var labelSub: String
    @Binding var pressActions: [CodableActionData]
    var supportsAuto: Bool
    var showHelp: Bool

    var body: some View {
        Section(header: Text("ラベル")) {
            Picker("ラベルの種類", selection: $selection) {
                if supportsAuto {
                    Text("自動").tag(LabelSelection.auto)
                }
                Text("テキスト").tag(LabelSelection.text)
                Text("システムアイコン").tag(LabelSelection.systemImage)
                Text("メインとサブ").tag(LabelSelection.mainAndSub)
            }
            .onChange(of: pressActions) { (_, _) in
                if supportsAuto, selection == .auto {
                    let text = pressActions.inputText ?? ""
                    labelText = text
                }
            }
            switch selection {
            case .auto:
                EmptyView()
            case .text:
                HStack {
                    Text("ラベル")
                    if showHelp {
                        HelpAlertButton(title: "ラベル", explanation: "キーに表示される文字を設定します。")
                    }
                    TextField("ラベル", text: $labelText)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.done)
                }
            case .systemImage:
                SystemIconPicker(icon: $labelImageName)
            case .mainAndSub:
                HStack {
                    Text("メイン")
                    if showHelp {
                        HelpAlertButton(title: "メイン", explanation: "大きく表示される文字を設定します。")
                    }
                    TextField("メインのラベル", text: $labelMain)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.done)
                }
                HStack {
                    Text("サブ")
                    if showHelp {
                        HelpAlertButton(title: "サブ", explanation: "小さく表示される文字を設定します。")
                    }
                    TextField("サブのラベル", text: $labelSub)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.done)
                }
            }
        }
    }
}

private struct PressActionSection: View {
    @Binding var actions: [CodableActionData]
    var body: some View {
        Section(header: Text("アクション"), footer: Text("キーを押したときの動作をより詳しく設定します。")) {
            NavigationLink("アクションを編集する") {
                CodableActionDataEditor($actions, availableCustards: CustardManager.load().availableCustards)
            }
            .foregroundStyle(.accentColor)
        }
    }
}

private struct LongpressActionSection: View {
    @Binding var action: CodableLongpressActionData
    var warning: LocalizedStringKey?

    var body: some View {
        Section(header: Text("長押しアクション"), footer: Text("キーを長押ししたときの動作をより詳しく設定します。")) {
            NavigationLink("長押しアクションを編集する") {
                CodableLongpressActionDataEditor($action, availableCustards: CustardManager.load().availableCustards)
            }
            .foregroundStyle(.accentColor)
            if let warning {
                Text(warning)
                    .font(.footnote)
                    .foregroundStyle(.orange)
            }
        }
    }
}

fileprivate extension [CodableActionData] {
    var inputText: String? {
        self.compactMap { action in
            if case let .input(text) = action {
                text
            } else {
                nil
            }
        }.first
    }
}

fileprivate extension CustardInterfaceKey {
    enum SystemKey { case system }
    enum CustomKey { case custom }

    subscript(key: CustomKey) -> CustardInterfaceCustomKey {
        get {
            if case let .custom(value) = self {
                return value
            }
            return .init(design: .init(label: .text(""), color: .normal), press_actions: [], longpress_actions: .none, variations: [])
        }
        set {
            self = .custom(newValue)
        }
    }

    subscript(key: SystemKey) -> CustardInterfaceSystemKey {
        get {
            if case let .system(value) = self {
                return value
            }
            return .enter
        }
        set {
            self = .system(newValue)
        }
    }
}

fileprivate extension FlickKeyPosition {
    var flickDirection: FlickDirection? {
        switch self {
        case .left: return .left
        case .top: return .top
        case .right: return .right
        case .bottom: return .bottom
        case .center: return nil
        }
    }
}

fileprivate extension CustardInterfaceCustomKey {
    subscript(direction: FlickDirection) -> CustardInterfaceVariationKey {
        get {
            if let variation = self.variations.first(where: {$0.type == .flickVariation(direction)})?.key {
                return variation
            }
            return .init(design: .init(label: .text("")), press_actions: [], longpress_actions: .none)
        }
        set {
            if let index = self.variations.firstIndex(where: {$0.type == .flickVariation(direction)}) {
                self.variations[index].key = newValue
            } else {
                self.variations.append(.init(type: .flickVariation(direction), key: newValue))
            }
        }
    }

    enum LabelKey { case label }
    enum LabelTextKey { case labelText }
    enum LabelImageNameKey { case labelImageName }
    enum LabelTypeKey { case labelType }
    enum LabelMainKey { case labelMain }
    enum LabelSubKey { case labelSub }
    enum PressActionKey { case pressAction }
    enum InputActionKey { case inputAction }
    enum LongpressActionKey { case longpressAction }

    subscript(label: LabelKey, position: FlickKeyPosition) -> CustardKeyLabelStyle {
        get {
            if let direction = position.flickDirection {
                return self[direction].design.label
            }
            return self.design.label
        }
        set {
            if let direction = position.flickDirection {
                self[direction].design.label = newValue
            } else {
                self.design.label = newValue
            }
        }
    }

    subscript(label: LabelTextKey, position: FlickKeyPosition) -> String {
        get {
            if let direction = position.flickDirection {
                return self[direction][.labelText]
            }
            if case let .text(value) = self.design.label {
                return value
            }
            return ""
        }
        set {
            if let direction = position.flickDirection {
                self[direction][.labelText] = newValue
            } else {
                self.design.label = .text(newValue)
            }
        }
    }

    subscript(label: LabelImageNameKey, position: FlickKeyPosition) -> String {
        get {
            if let direction = position.flickDirection {
                return self[direction][.labelImageName]
            }
            if case let .systemImage(value) = self.design.label {
                return value
            }
            return ""
        }
        set {
            if let direction = position.flickDirection {
                self[direction][.labelImageName] = newValue
            } else {
                self.design.label = .systemImage(newValue)
            }
        }
    }

    subscript(label: LabelMainKey, position: FlickKeyPosition) -> String {
        get {
            if let direction = position.flickDirection {
                return self[direction][.labelMain]
            }
            if case let .mainAndSub(value, _) = self.design.label {
                return value
            }
            return ""
        }
        set {
            if let direction = position.flickDirection {
                self[direction][.labelMain] = newValue
            } else if case let .mainAndSub(_, variations) = self.design.label {
                self.design.label = .mainAndSub(newValue, variations)
            } else {
                self.design.label = .mainAndSub(newValue, "")
            }
        }
    }

    subscript(label: LabelSubKey, position: FlickKeyPosition) -> String {
        get {
            if let direction = position.flickDirection {
                return self[direction][.labelSub]
            }
            if case let .mainAndSub(_, value) = self.design.label {
                return value
            }
            return ""
        }
        set {
            if let direction = position.flickDirection {
                self[direction][.labelSub] = newValue
            } else if case let .mainAndSub(main, _) = self.design.label {
                self.design.label = .mainAndSub(main, newValue)
            } else {
                self.design.label = .mainAndSub("", newValue)
            }
        }
    }

    subscript(label: LabelTypeKey, position: FlickKeyPosition) -> LabelType {
        get {
            if let direction = position.flickDirection {
                return self[direction][.labelType]
            }
            switch self.design.label {
            case .systemImage: return .systemImage
            case .text: return .text
            case .mainAndSub: return .mainAndSub
            }
        }
        set {
            if let direction = position.flickDirection {
                self[direction][.labelType] = newValue
            } else {
                switch newValue {
                case .text:
                    self.design.label = .text("")
                case .systemImage:
                    self.design.label = .systemImage("circle.fill")
                case .mainAndSub:
                    self.design.label = .mainAndSub("A", "BC")
                }
            }
        }
    }

    subscript(action: PressActionKey, position: FlickKeyPosition) -> [CodableActionData] {
        get {
            if let direction = position.flickDirection {
                return self[direction][.pressAction]
            }
            return self.press_actions
        }
        set {
            if let direction = position.flickDirection {
                self[direction][.pressAction] = newValue
            } else {
                self.press_actions = newValue
            }
        }
    }

    subscript(inputAction: InputActionKey, position: FlickKeyPosition) -> String {
        get {
            if let direction = position.flickDirection {
                return self[direction][.inputAction]
            }
            if case let .input(value) = self.press_actions.first {
                return value
            }
            return ""
        }
        set {
            if let direction = position.flickDirection {
                self[direction][.inputAction] = newValue
            } else {
                self.press_actions = [.input(newValue)]
            }
        }
    }

    subscript(action: LongpressActionKey, position: FlickKeyPosition) -> CodableLongpressActionData {
        get {
            if let direction = position.flickDirection {
                return self[direction][.longpressAction]
            }
            return self.longpress_actions
        }
        set {
            if let direction = position.flickDirection {
                self[direction][.longpressAction] = newValue
            } else {
                self.longpress_actions = newValue
            }
        }
    }
}

// MARK: - Longpress variations utilities (for linear variations editing)
fileprivate extension CustardInterfaceCustomKey {
    func longpressKeys() -> [CustardInterfaceVariationKey] {
        self.variations.compactMap { v in
            if case .longpressVariation = v.type {
                v.key
            } else {
                nil
            }
        }
    }
    mutating func setLongpressKeys(_ keys: [CustardInterfaceVariationKey]) {
        let flicks = self.variations.filter { v in
            if case .flickVariation = v.type {
                return true
            } else {
                return false
            }
        }
        self.variations = flicks + keys.map {
            .init(type: .longpressVariation, key: $0)
        }
    }
    subscript(longpressListIndex index: Int) -> CustardInterfaceVariationKey {
        get { self.longpressKeys()[index] }
        set {
            var arr = self.longpressKeys()
            arr[index] = newValue
            self.setLongpressKeys(arr)
        }
    }
    mutating func appendLongpressVariation() {
        var arr = self.longpressKeys()
        // 初期は入力とラベルを一致させて自動判定にできるよう、空文字の入力アクションを設定
        arr.append(
            .init(
                design: .init(label: .text("")),
                press_actions: [.input("")],
                longpress_actions: .none
            )
        )
        self.setLongpressKeys(arr)
    }
    mutating func removeLongpress(at index: Int) {
        var arr = self.longpressKeys()
        guard arr.indices.contains(index) else {
            return
        }
        arr.remove(at: index)
        self.setLongpressKeys(arr)
    }
    mutating func moveLongpress(fromOffsets: IndexSet, toOffset: Int) {
        var arr = self.longpressKeys()
        arr.move(fromOffsets: fromOffsets, toOffset: toOffset)
        self.setLongpressKeys(arr)
    }
}

fileprivate extension CustardInterfaceVariationKey {
    enum LabelTextKey { case labelText }
    enum PressActionKey { case pressAction }
    enum InputActionKey { case inputAction }
    enum LongpressActionKey { case longpressAction }
    enum LabelImageNameKey { case labelImageName }
    enum LabelTypeKey { case labelType }
    enum LabelMainKey { case labelMain }
    enum LabelSubKey { case labelSub }

    subscript(label: LabelTextKey) -> String {
        get {
            if case let .text(value) = self.design.label {
                return value
            }
            return ""
        }
        set {
            self.design.label = .text(newValue)
        }
    }

    subscript(label: LabelImageNameKey) -> String {
        get {
            if case let .systemImage(value) = self.design.label {
                return value
            }
            return ""
        }
        set {
            self.design.label = .systemImage(newValue)
        }
    }

    subscript(label: LabelMainKey) -> String {
        get {
            if case let .mainAndSub(value, _) = self.design.label {
                return value
            }
            return ""
        }
        set {
            if case let .mainAndSub(_, variations) = self.design.label {
                self.design.label = .mainAndSub(newValue, variations)
            } else {
                self.design.label = .mainAndSub(newValue, "")
            }
        }
    }

    subscript(label: LabelSubKey) -> String {
        get {
            if case let .mainAndSub(_, value) = self.design.label {
                return value
            }
            return ""
        }
        set {
            if case let .mainAndSub(main, _) = self.design.label {
                self.design.label = .mainAndSub(main, newValue)
            } else {
                self.design.label = .mainAndSub("", newValue)
            }
        }
    }

    subscript(label: LabelTypeKey) -> LabelType {
        get {
            switch self.design.label {
            case .systemImage: return .systemImage
            case .text: return .text
            case .mainAndSub: return .mainAndSub
            }
        }
        set {
            switch newValue {
            case .text:
                self.design.label = .text("")
            case .systemImage:
                self.design.label = .systemImage("circle.fill")
            case .mainAndSub:
                self.design.label = .mainAndSub("A", "BC")
            }
        }
    }

    subscript(pressAction: PressActionKey) -> [CodableActionData] {
        get {
            self.press_actions
        }
        set {
            self.press_actions = newValue
        }
    }

    subscript(inputAction: InputActionKey) -> String {
        get {
            if case let .input(value) = self.press_actions.first {
                return value
            }
            return ""
        }
        set {
            self.press_actions = [.input(newValue)]
        }
    }

    subscript(longpressAction: LongpressActionKey) -> CodableLongpressActionData {
        get {
            self.longpress_actions
        }
        set {
            self.longpress_actions = newValue
        }
    }
}

@MainActor
struct CustardInterfaceKeyEditor: View {
    @Binding private var keyData: UserMadeKeyData
    private let target: Target

    @State private var selectedPosition: FlickKeyPosition = .center
    @State private var longpressSelectedIndex: Int = -1
    @State private var dragFromLongpressIndex: Int?
    @State private var longpressIDs: [UUID] = []
    @State private var longpressSelection: [UUID: LabelSelection] = [:]
    // 長押しの自動ラベル選択は「入力とラベル文字列が一致しているか」で判定する（フリックと同様）

    private struct KeyLabelTypeWrapper {
        var center: LabelType?
        var left: LabelType?
        var top: LabelType?
        var right: LabelType?
        var bottom: LabelType?

        subscript(position: FlickKeyPosition) -> LabelType? {
            get {
                switch position {
                case .center: center
                case .left: left
                case .top: top
                case .right: right
                case .bottom: bottom
                }
            }
            set {
                switch position {
                case .center: center = newValue
                case .left: left = newValue
                case .top: top = newValue
                case .right: right = newValue
                case .bottom: bottom = newValue
                }
            }
        }
    }
    @State private var keyLabelTypeWrapper: KeyLabelTypeWrapper = KeyLabelTypeWrapper()
    // 編集モード切替（フリック / 長押しバリエーション）
    private enum EditSegment: Sendable, Hashable {
        case flick
        case longpress
    }
    @State private var editSegment: EditSegment = .flick

    enum Target {
        /// フリック用のカスタムキーの編集画面
        case flick
        /// スクロール用のカスタムキーの編集画面
        /// バリエーションを表示しない
        case simple
        // TODO: Qwerty用のカスタムキーの編集画面を統合する？
    }

    init(data: Binding<UserMadeKeyData>, target: Target = .flick) {
        self._keyData = data
        self.target = target

        func getInitialLabelType(_ key: CustardInterfaceCustomKey, position: FlickKeyPosition) -> LabelType? {
            getInitialLabelType(pressActions: key[.pressAction, position], keyLabel: key[.label, position])
        }
        func getInitialLabelType(pressActions: [CodableActionData], keyLabel: CustardKeyLabelStyle) -> LabelType? {
            switch keyLabel {
            case .text(let string):
                if let inputText = pressActions.inputText, inputText == string {
                    nil
                } else {
                    .text
                }
            case .systemImage:
                .systemImage
            case .mainAndSub:
                .mainAndSub
            }
        }
        if case .custom = self.keyData.model {
            let model = self.keyData.model[.custom]
            self._keyLabelTypeWrapper = .init(
                initialValue: KeyLabelTypeWrapper(
                    center: getInitialLabelType(model, position: .center),
                    left: getInitialLabelType(model, position: .left),
                    top: getInitialLabelType(model, position: .top),
                    right: getInitialLabelType(model, position: .right),
                    bottom: getInitialLabelType(model, position: .bottom)
                )
            )
        }
    }

    private var screenWidth: CGFloat { UIScreen.main.bounds.width }

    private var keySize: CGSize {
        CGSize(width: min(100, screenWidth / 5.6), height: min(70, screenWidth / 8))
    }
    private var spacing: CGFloat {
        (screenWidth - keySize.width * 5) / 5
    }

    var body: some View {
        VStack {
            switch keyData.model {
            case let .custom(value):
                switch target {
                case .flick:
                    // セグメント切替（フリック / 長押しバリエーション）
                    Picker("編集モード", selection: $editSegment) {
                        Text("フリック").tag(EditSegment.flick)
                        Text("長押しバリエーション").tag(EditSegment.longpress)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    switch editSegment {
                    case .flick:
                        Text("編集したい方向を選択してください。")
                            .padding(.vertical)
                            .foregroundStyle(.secondary)
                        flickKeysView(key: value)
                        customKeyEditor(position: selectedPosition)
                    case .longpress:
                        longpressListEditor
                        let count = keyData.model[.custom].longpressKeys().count
                        if (0..<count).contains(longpressSelectedIndex) {
                            customKeyEditor(longpressIndex: longpressSelectedIndex)
                        } else {
                            Spacer()
                        }
                    }
                case .simple:
                    keyView(key: value, position: .center)
                    customKeyEditor(position: .center)
                }
            case .system:
                systemKeyEditor()
            }
        }
        .background(Color.secondarySystemBackground)
        .navigationTitle(Text("キーの編集"))
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Longpress variations list editor (Qwerty-like UI)
    @ViewBuilder
    private var longpressListEditor: some View {
        let customBinding = Binding<CustardInterfaceCustomKey>(
            get: { keyData.model[.custom] },
            set: { keyData.model[.custom] = $0 }
        )
        let longpressBinding = Binding<[CustardInterfaceVariationKey]>(
            get: { customBinding.wrappedValue.longpressKeys() },
            set: { arr in
                var v = customBinding.wrappedValue
                v.setLongpressKeys(arr)
                customBinding.wrappedValue = v
            }
        )

        let screenWidth = UIScreen.main.bounds.width
        let chipWidth: CGFloat = min(120, screenWidth / 4.5)
        let chipHeight: CGFloat = 44
        let padding: CGFloat = 6

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("長押しバリエーション").font(.headline)
                Spacer()
                Button("追加", systemImage: "plus") {
                    var v = customBinding.wrappedValue
                    v.appendLongpressVariation()
                    customBinding.wrappedValue = v
                    longpressSelectedIndex = customBinding.wrappedValue.longpressKeys().indices.last ?? -1
                    let newId = UUID()
                    longpressIDs.append(newId)
                    // 追加直後は自動モードにして、入力とラベルの同期を有効にする
                    longpressSelection[newId] = .auto
                }
            }
            if longpressBinding.wrappedValue.isEmpty {
                Text("バリエーションはキーを長押しすると選択できます").foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        let safeCount = min(longpressIDs.count, longpressBinding.wrappedValue.count)
                        let indexed: [IndexedLongpressItem] = (0..<safeCount).map { .init(id: longpressIDs[$0], index: $0) }
                        ForEach(indexed, id: \.id) { elem in
                            let i = elem.index
                            let item = longpressBinding.wrappedValue[i]
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.background)
                                .stroke(longpressSelectedIndex == i ? .accentColor : .primary)
                                .focus(.accentColor, focused: longpressSelectedIndex == i)
                                .overlay {
                                    switch item[.labelType] {
                                    case .text:
                                        Text(item[.labelText])
                                            .lineLimit(1)
                                            .padding(.horizontal, 6)
                                    case .systemImage:
                                        let name = item[.labelImageName]
                                        Image(systemName: name)
                                            .padding(.horizontal, 6)
                                    case .mainAndSub:
                                        VStack(spacing: 2) {
                                            Text(item[.labelMain])
                                            Text(item[.labelSub]).font(.caption)
                                        }
                                        .padding(.horizontal, 6)
                                    }
                                }
                                .compositingGroup()
                                .frame(width: chipWidth, height: chipHeight)
                                .padding(padding)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    longpressSelectedIndex = i
                                }
                                .onDrag {
                                    self.dragFromLongpressIndex = i
                                    return NSItemProvider(contentsOf: URL(string: "longpress-\(i)")!)!
                                }
                                .onDrop(of: [.url], delegate: LocalDropDelegate {
                                    guard let from = self.dragFromLongpressIndex else {
                                        return
                                    }
                                    withAnimation(.default) {
                                        var arr = longpressBinding.wrappedValue
                                        let toOffset = i > from ? i + 1 : i
                                        arr.move(fromOffsets: IndexSet(integer: from), toOffset: toOffset)
                                        // move stable IDs in tandem for animation
                                        let movedId = longpressIDs.remove(at: from)
                                        longpressIDs.insert(movedId, at: i > from ? i : i)
                                        var v = customBinding.wrappedValue
                                        v.setLongpressKeys(arr)
                                        customBinding.wrappedValue = v
                                        self.dragFromLongpressIndex = i
                                        self.longpressSelectedIndex = i
                                    }
                                })
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(.horizontal)
        .onAppear {
            let count = longpressBinding.wrappedValue.count
            if longpressIDs.count != count {
                longpressIDs = (0..<count).map { _ in UUID() }
            }
        }
        .onChange(of: longpressBinding.wrappedValue.count) { (_, newCount) in
            let current = longpressIDs.count
            if newCount > current {
                longpressIDs.append(contentsOf: Array(repeating: UUID(), count: newCount - current))
            } else if newCount < current {
                longpressIDs.removeLast(current - newCount)
            }
        }
    }

    private var keyPicker: some View {
        Picker("キーの種類", selection: $keyData.model) {
            if [CustardInterfaceKey.system(.enter), .custom(.flickSpace()), .custom(.flickDelete()), .system(.changeKeyboard), .system(.flickKogaki), .system(.flickKutoten), .system(.flickHiraTab), .system(.flickAbcTab), .system(.flickStar123Tab), .system(.upperLower), .system(.nextCandidate)].contains(keyData.model) {
                Text("カスタム").tag(CustardInterfaceKey.custom(.empty))
            } else {
                Text("カスタム").tag(keyData.model)
            }
            Text("改行キー").tag(CustardInterfaceKey.system(.enter))
            Text("削除キー").tag(CustardInterfaceKey.custom(.flickDelete()))
            Text("空白キー").tag(CustardInterfaceKey.custom(.flickSpace()))
            Text("次候補キー").tag(CustardInterfaceKey.system(.nextCandidate))
            Text("地球儀キー").tag(CustardInterfaceKey.system(.changeKeyboard))
            Text("小書き・濁点化キー").tag(CustardInterfaceKey.system(.flickKogaki))
            Text("大文字・小文字キー").tag(CustardInterfaceKey.system(.upperLower))
            Text("句読点キー").tag(CustardInterfaceKey.system(.flickKutoten))
            Text("日本語タブキー").tag(CustardInterfaceKey.system(.flickHiraTab))
            Text("英語タブキー").tag(CustardInterfaceKey.system(.flickAbcTab))
            Text("記号タブキー").tag(CustardInterfaceKey.system(.flickStar123Tab))
        }
    }

    @ViewBuilder private var sizePicker: some View {
        Stepper("縦: \(keyData.height)", value: $keyData.height, in: 1 ... .max)
        Stepper("横: \(keyData.width)", value: $keyData.width, in: 1 ... .max)
    }

    private func systemKeyEditor() -> some View {
        Form {
            Section {
                keyPicker
            }
            switch target {
            case .flick:
                Section(header: Text("キーのサイズ")) {
                    sizePicker
                }
            case .simple:
                EmptyView()
            }
            Section {
                Button("クリア") {
                    keyData.model = .custom(.empty)
                }.foregroundStyle(.red)
            }
        }
    }

    private func isInputActionEditable(position: FlickKeyPosition) -> Bool {
        let actions = self.keyData.model[.custom][.pressAction, position]
        if actions.count == 1, case .input = actions.first {
            return true
        }
        if actions.isEmpty {
            return true
        }
        return false
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

    private func customKeyEditor(position: FlickKeyPosition) -> some View {
        Form {
            Section(header: Text("入力")) {
                if self.isInputActionEditable(position: position) {
                    HStack {
                        Text("入力")
                        HelpAlertButton(title: "入力", explanation: "キーを押して入力される文字を設定します。")
                        // FIXME: バグを防ぐため一時的にBindingオブジェクトを手動生成する形にしている
                        TextField(
                            "入力",
                            text: Binding(
                                get: {
                                    keyData.model[.custom][.inputAction, position]
                                },
                                set: {
                                    keyData.model[.custom][.inputAction, position] = $0
                                }
                            )
                        )
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.done)
                    }
                } else {
                    Text("このキーには入力以外のアクションが設定されています。現在のアクションを消去して入力する文字を設定するには「入力を設定する」を押してください")
                    Button("入力を設定する") {
                        keyData.model[.custom][.inputAction, position] = ""
                    }
                    .foregroundStyle(.accentColor)
                }
            }
            LabelEditorSection(
                selection: Binding(
                    get: {
                        if let t = keyLabelTypeWrapper[position] {
                            switch t {
                            case .text: .text
                            case .systemImage: .systemImage
                            case .mainAndSub: .mainAndSub
                            }
                        } else {
                            .auto
                        }
                    },
                    set: { sel in
                        switch sel {
                        case .auto:
                            keyLabelTypeWrapper[position] = nil
                            let text = keyData.model[.custom][.pressAction, position].inputText ?? ""
                            keyData.model[.custom][.label, position] = .text(text)
                        case .text:
                            keyLabelTypeWrapper[position] = .text
                            keyData.model[.custom][.label, position] = .text(keyData.model[.custom][.labelText, position])
                        case .systemImage:
                            keyLabelTypeWrapper[position] = .systemImage
                            keyData.model[.custom][.label, position] = .systemImage(keyData.model[.custom][.labelImageName, position])
                        case .mainAndSub:
                            keyLabelTypeWrapper[position] = .mainAndSub
                            keyData.model[.custom][.label, position] = .mainAndSub(keyData.model[.custom][.labelMain, position], keyData.model[.custom][.labelSub, position])
                        }
                    }
                ),
                labelText: Binding(
                    get: { keyData.model[.custom][.labelText, position] },
                    set: { keyData.model[.custom][.labelText, position] = $0 }
                ),
                labelImageName: Binding(
                    get: { keyData.model[.custom][.labelImageName, position] },
                    set: { keyData.model[.custom][.labelImageName, position] = $0 }
                ),
                labelMain: Binding(
                    get: { keyData.model[.custom][.labelMain, position] },
                    set: { keyData.model[.custom][.labelMain, position] = $0 }
                ),
                labelSub: Binding(
                    get: { keyData.model[.custom][.labelSub, position] },
                    set: { keyData.model[.custom][.labelSub, position] = $0 }
                ),
                pressActions: $keyData.model[.custom][.pressAction, position],
                supportsAuto: true,
                showHelp: true
            )
            PressActionSection(actions: $keyData.model[.custom][.pressAction, position])
            LongpressActionSection(
                action: $keyData.model[.custom][.longpressAction, position],
                warning: {
                    if position == .center {
                        let hasLongpressVars = !keyData.model[.custom].longpressKeys().isEmpty
                        if hasLongpressVars {
                            return "長押しバリエーションが設定されている場合長押しアクションは動作しません"
                        }
                    }
                    return nil
                }()
            )
            if position == .center {
                Section(header: Text("キーの色")) {
                    Picker("キーの色", selection: $keyData.model[.custom].design.color) {
                        Text("通常のキー").tag(CustardKeyDesign.ColorType.normal)
                        Text("特別なキー").tag(CustardKeyDesign.ColorType.special)
                        Text("押されているキー").tag(CustardKeyDesign.ColorType.selected)
                        Text("目立たないキー").tag(CustardKeyDesign.ColorType.unimportant)
                    }
                }
            }
            switch target {
            case .flick:
                if position == .center {
                    Section(header: Text("キーのサイズ")) {
                        sizePicker
                    }
                    Section {
                        keyPicker
                    }
                    Section {
                        Button("クリア") {
                            // variationsには操作をしない
                            keyData.model[.custom].press_actions = [.input("")]
                            keyData.model[.custom].longpress_actions = .none
                            keyData.model[.custom].design = .init(label: .text(""), color: .normal)
                        }.foregroundStyle(.red)
                    }
                }
            case .simple:
                EmptyView()
            }
            if let direction = position.flickDirection {
                Button("クリア") {
                    keyData.model[.custom].variations.removeAll {
                        $0.type == .flickVariation(direction)
                    }
                }.foregroundStyle(.red)
            }
        }
    }

    @ViewBuilder private func flickKeysView(key: CustardInterfaceCustomKey) -> some View {
        VStack {
            keyView(key: key, position: .top)
            HStack {
                keyView(key: key, position: .left)
                keyView(key: key, position: .center)
                keyView(key: key, position: .right)
            }
            keyView(key: key, position: .bottom)
        }
    }

    @ViewBuilder private func keyView(key: CustardInterfaceCustomKey, position: FlickKeyPosition) -> some View {
        switch key[.label, position] {
        case .text:
            CustomKeySettingFlickKeyView(position, label: key[.labelText, position], selectedPosition: $selectedPosition)
                .frame(width: keySize.width, height: keySize.height)
        case .systemImage:
            CustomKeySettingFlickKeyView(position, selectedPosition: $selectedPosition) {
                Image(systemName: key[.labelImageName, position])
            }
            .frame(width: keySize.width, height: keySize.height)
        case .mainAndSub:
            CustomKeySettingFlickKeyView(position, selectedPosition: $selectedPosition) {
                VStack {
                    Text(verbatim: key[.labelMain, position])
                    Text(verbatim: key[.labelSub, position]).font(.caption)
                }
            }
            .frame(width: keySize.width, height: keySize.height)
        }
    }

    // Unified longpress editor (same style sections as flick editor)
    @ViewBuilder private func customKeyEditor(longpressIndex index: Int) -> some View {
        let variation = Binding<CustardInterfaceVariationKey>(
            get: {
                let arr = keyData.model[.custom].longpressKeys()
                if arr.indices.contains(index) {
                    return arr[index]
                } else {
                    return .init(design: .init(label: .text("")), press_actions: [.input("")], longpress_actions: .none)
                }
            },
            set: { newValue in
                var model = keyData.model[.custom]
                var arr = model.longpressKeys()
                if arr.indices.contains(index) {
                    arr[index] = newValue
                    model.setLongpressKeys(arr)
                    keyData.model[.custom] = model
                }
            }
        )
        let currentId: UUID? = longpressIDs.indices.contains(index) ? longpressIDs[index] : nil
        let lpLabelType = Binding<LabelSelection>(
            get: {
                if let id = currentId, let sel = longpressSelection[id] {
                    return sel
                }
                let input = variation.wrappedValue[.pressAction].inputText
                switch variation.wrappedValue.design.label {
                case .text(let s):
                    if let input, input == s {
                        return .auto
                    } else {
                        return .text
                    }
                case .systemImage:
                    return .systemImage
                case .mainAndSub:
                    return .mainAndSub
                }
            },
            set: { newValue in
                if let id = currentId {
                    longpressSelection[id] = newValue
                }
                switch newValue {
                case .auto:
                    let text = variation.wrappedValue[.pressAction].inputText ?? ""
                    variation.wrappedValue.design.label = .text(text)
                case .text:
                    variation.wrappedValue[.labelType] = .text
                case .systemImage:
                    variation.wrappedValue[.labelType] = .systemImage
                case .mainAndSub:
                    variation.wrappedValue[.labelType] = .mainAndSub
                }
            }
        )

        Form {
            Section(header: Text("入力")) {
                let actions = variation.wrappedValue[.pressAction]
                if isInputActionEditable(actions: actions) {
                    HStack {
                        Text("入力")
                        TextField(
                            "入力",
                            text: Binding(
                                get: { variation.wrappedValue[.inputAction] },
                                set: { variation.wrappedValue[.inputAction] = $0 }
                            )
                        )
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.done)
                    }
                } else {
                    Text("このキーには入力以外のアクションが設定されています。現在のアクションを消去して入力する文字を設定するには「入力を設定する」を押してください")
                    Button("入力を設定する") {
                        variation.wrappedValue[.inputAction] = ""
                    }
                    .foregroundStyle(.accentColor)
                }
            }
            LabelEditorSection(
                selection: lpLabelType,
                labelText: variation[.labelText],
                labelImageName: variation[.labelImageName],
                labelMain: variation[.labelMain],
                labelSub: variation[.labelSub],
                pressActions: variation[.pressAction],
                supportsAuto: true,
                showHelp: false
            )
            .onAppear {
                if let id = currentId, longpressSelection[id] == nil {
                    let input = variation.wrappedValue[.pressAction].inputText
                    let initial: LabelSelection
                    switch variation.wrappedValue.design.label {
                    case .text(let s):
                        if let input, input == s {
                            initial = .auto
                        } else {
                            initial = .text
                        }
                    case .systemImage:
                        initial = .systemImage
                    case .mainAndSub:
                        initial = .mainAndSub
                    }
                    longpressSelection[id] = initial
                }
            }
            PressActionSection(actions: variation[.pressAction])
            LongpressActionSection(action: variation[.longpressAction])
            Section {
                Button("このバリエーションを削除") {
                    var model = keyData.model[.custom]
                    model.removeLongpress(at: index)
                    keyData.model[.custom] = model
                    if longpressIDs.indices.contains(index) {
                        let removed = longpressIDs.remove(at: index)
                        longpressSelection.removeValue(forKey: removed)
                    }
                    let count = keyData.model[.custom].longpressKeys().count
                    if count == 0 {
                        longpressSelectedIndex = -1
                    } else {
                        longpressSelectedIndex = min(index, count - 1)
                    }
                }
                .foregroundStyle(.red)
            }
        }
    }
}

// Local drop delegate for reordering chips via onDrag/onDrop
private struct LocalDropDelegate: DropDelegate {
    let onMove: () -> Void

    func performDrop(info: DropInfo) -> Bool {
        true
    }
    func dropEntered(info: DropInfo) {
        withAnimation(.default) {
            self.onMove()
        }
    }
    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}
