//
//  EditingTenkeyCustardView.swift
//  MainApp
//
//  Created by ensan on 2021/04/22.
//  Copyright © 2021 ensan. All rights reserved.
//

import AzooKeyUtils
import CustardKit
import Foundation
import KeyboardViews
import SwiftUI
import SwiftUIUtils
import SwiftUtils

extension CustardInterfaceCustomKey {
    static let empty: Self = .init(design: .init(label: .text(""), color: .normal), press_actions: [.input("")], longpress_actions: .none, variations: [])
}

fileprivate extension Dictionary where Key == KeyPosition, Value == UserMadeKeyData {
    subscript(key: Key) -> Value {
        get {
            self[key, default: .init(model: .custom(.empty), width: 1, height: 1)]
        }
        set {
            self[key] = newValue
        }
    }
}

@MainActor
struct EditingTenkeyCustardView: CancelableEditor {
    private static let emptyKey: UserMadeKeyData = .init(model: .custom(.empty), width: 1, height: 1)
    private static let emptyKeys: [KeyPosition: UserMadeKeyData] = (0..<5).reduce(into: [:]) {dict, x in
        (0..<4).forEach {y in
            dict[.gridFit(x: x, y: y)] = emptyKey
        }
    }
    private static let emptyItem: UserMadeTenKeyCustard = .init(tabName: "新規タブ", rowCount: "5", columnCount: "4", inputStyle: .direct, language: .ja_JP, keys: emptyKeys, addTabBarAutomatically: true)

    let base: UserMadeTenKeyCustard
    @StateObject private var variableStates = VariableStates(clipboardHistoryManagerConfig: ClipboardHistoryManagerConfig(), tabManagerConfig: TabManagerConfig(), userDefaults: UserDefaults.standard)
    @State private var editingItem: UserMadeTenKeyCustard
    @Binding private var manager: CustardManager

    // MARK: 遷移
    private let shouldJustDimiss: Bool
    private let isNewItem: Bool
    @Binding private var path: [CustomizeTabView.Path]
    @Environment(\.dismiss) var dismiss

    // MARK: UI表示系
    @State private var showPreview = false
    @State private var baseSelectionSheetState = BaseSelectionSheetState()
    private struct BaseSelectionSheetState: Sendable, Equatable, Hashable {
        var showBaseSelectionSheet = false
        var hasShown = false
    }
    @State private var showDuplicateAlert = false

    private var models: [(position: GridFitPositionSpecifier, model: any FlickKeyModelProtocol<AzooKeyKeyboardViewExtension>)] {
        (0..<layout.rowCount).reduce(into: []) {models, x in
            (0..<layout.columnCount).forEach {y in
                if let value = editingItem.keys[.gridFit(x: x, y: y)] {
                    models.append(
                        (.init(x: x, y: y, width: value.width, height: value.height), value.model.flickKeyModel(extension: AzooKeyKeyboardViewExtension.self))
                    )
                } else if !editingItem.emptyKeys.contains(.gridFit(x: x, y: y)) {
                    models.append(
                        (.init(x: x, y: y, width: 1, height: 1), CustardInterfaceKey.custom(.empty).flickKeyModel(extension: AzooKeyKeyboardViewExtension.self))
                    )
                }
            }
        }
    }

    private var layout: CustardInterfaceLayoutGridValue {
        .init(rowCount: max(Int(editingItem.rowCount) ?? 1, 1), columnCount: max(Int(editingItem.columnCount) ?? 1, 1))
    }

    private var custard: Custard {
        Custard(
            identifier: editingItem.tabName,
            language: editingItem.language,
            input_style: editingItem.inputStyle,
            metadata: .init(
                custard_version: .v1_2,
                display_name: editingItem.tabName
            ),
            interface: .init(
                keyStyle: .tenkeyStyle,
                keyLayout: .gridFit(layout),
                keys: editingItem.keys.reduce(into: [:]) {dict, item in
                    if case let .gridFit(x: x, y: y) = item.key, !editingItem.emptyKeys.contains(item.key) {
                        dict[.gridFit(.init(x: x, y: y, width: item.value.width, height: item.value.height))] = item.value.model
                    }
                }
            )
        )
    }

    init(manager: Binding<CustardManager>, editingItem: UserMadeTenKeyCustard? = nil, path: Binding<[CustomizeTabView.Path]>?) {
        self._manager = manager
        self.shouldJustDimiss = path == nil
        self._path = path ?? .constant([])
        self.baseSelectionSheetState = .init(hasShown: editingItem != nil)  // 編集の場合はすでにbase選択は終わったと考える
        self.base = editingItem ?? Self.emptyItem
        self._editingItem = State(initialValue: self.base)
        self.isNewItem = editingItem == nil
    }

    private func isCovered(at position: (x: Int, y: Int)) -> Bool {
        for x in 0...position.x {
            for y in 0...position.y {
                if x == position.x && y == position.y {
                    continue
                }
                if let model = models.first(where: {$0.position.x == x && $0.position.y == y}) {
                    // 存在範囲にpositionがあれば
                    if x ..< x + model.position.width ~= position.x && y ..< y + model.position.height ~= position.y {
                        return true
                    }
                }
            }
        }
        return false
    }

    private var interfaceSize: CGSize {
        .init(width: UIScreen.main.bounds.width, height: Design.keyboardHeight(screenWidth: UIScreen.main.bounds.width, orientation: MainAppDesign.keyboardOrientation))
    }

    var body: some View {
        VStack {
            Form {
                if isNewItem {
                    TextField("タブの名前", text: $editingItem.tabName)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.done)
                } else {
                    LabeledContent("タブの名前") {
                        Text(editingItem.tabName)
                    }
                }
                if showPreview {
                    Button("プレビューを閉じる") {
                        showPreview = false
                    }
                } else {
                    Button("プレビュー") {
                        UIApplication.shared.closeKeyboard()
                        showPreview = true
                    }
                }

                let columnCount: Binding<Int> = $editingItem.columnCount.converted(.intStringConversion(defaultValue: 1).reversed())
                Stepper("行の数: \(editingItem.columnCount)", value: columnCount, in: 1 ... .max)
                let rowCount: Binding<Int> = $editingItem.rowCount.converted(.intStringConversion(defaultValue: 1).reversed())
                Stepper("列の数: \(editingItem.rowCount)", value: rowCount, in: 1 ... .max)
                Picker("言語", selection: $editingItem.language) {
                    Text("なし").tag(CustardLanguage.none)
                    Text("日本語").tag(CustardLanguage.ja_JP)
                    Text("英語").tag(CustardLanguage.en_US)
                }
                Picker("入力方式", selection: $editingItem.inputStyle) {
                    Text("そのまま入力").tag(CustardInputStyle.direct)
                    Text("ローマ字かな入力").tag(CustardInputStyle.roman2kana)
                }
                if self.isNewItem {
                    Toggle("自動的にタブバーに追加", isOn: $editingItem.addTabBarAutomatically)
                }
            }
            HStack {
                Spacer()
                if showPreview {
                    Button("閉じる", systemImage: "xmark.circle") {
                        showPreview = false
                    }
                } else {
                    Button("プレビュー", systemImage: "play.circle") {
                        showPreview = true
                    }
                }
            }
            .labelStyle(.iconOnly)
            .font(.title)
            .padding(.horizontal, 8)
            if !showPreview {
                CustardFlickKeysView<AzooKeyKeyboardViewExtension, _>(models: models, tabDesign: .init(width: layout.rowCount, height: layout.columnCount, interfaceSize: interfaceSize, orientation: MainAppDesign.keyboardOrientation), layout: layout) {(view: FlickKeyView<AzooKeyKeyboardViewExtension>, x: Int, y: Int) in
                    if editingItem.emptyKeys.contains(.gridFit(x: x, y: y)) {
                        if !isCovered(at: (x, y)) {
                            Button {
                                editingItem.emptyKeys.remove(.gridFit(x: x, y: y))
                            } label: {
                                view.disabled(true)
                                    .opacity(0)
                                    .overlay {
                                        Rectangle().stroke(style: .init(lineWidth: 2, dash: [5]))
                                    }
                                    .overlay {
                                        Image(systemName: "plus.circle")
                                            .foregroundStyle(.accentColor)
                                    }
                            }
                        }
                    } else {
                        NavigationLink {
                            CustardInterfaceKeyEditor(data: $editingItem.keys[.gridFit(x: x, y: y)])
                        } label: {
                            view.disabled(true)
                                .border(Color.primary)
                        }
                        .contextMenu {
                            Button("コピーする", systemImage: "doc.on.doc") {
                                self.manager.editorState.copiedKey = editingItem.keys[.gridFit(x: x, y: y)]
                            }
                            Button("ペーストする", systemImage: "doc.on.clipboard") {
                                if let copiedKey = self.manager.editorState.copiedKey {
                                    editingItem.keys[.gridFit(x: x, y: y)] = copiedKey
                                }
                            }
                            .disabled(self.manager.editorState.copiedKey == nil)
                            Button("下に行を追加", systemImage: "plus") {
                                editingItem.columnCount = Int(editingItem.columnCount)?.advanced(by: 1).description ?? editingItem.columnCount
                                for px in 0 ..< Int(layout.rowCount) {
                                    for py in (y + 1 ..< Int(layout.columnCount)).reversed() {
                                        editingItem.keys[.gridFit(x: px, y: py + 1)] = editingItem.keys[.gridFit(x: px, y: py)]
                                    }
                                }
                                for px in 0 ..< Int(layout.rowCount) {
                                    editingItem.keys[.gridFit(x: px, y: y + 1)] = nil
                                }
                                editingItem.emptyKeys = editingItem.emptyKeys.mapSet { item in
                                    switch item {
                                    case .gridFit(x: let px, y: let py) where y + 1 <= py:
                                        return .gridFit(x: px, y: py + 1)
                                    default:
                                        return item
                                    }
                                }
                            }
                            Button("上に行を追加", systemImage: "plus") {
                                editingItem.columnCount = Int(editingItem.columnCount)?.advanced(by: 1).description ?? editingItem.columnCount
                                for px in 0 ..< Int(layout.rowCount) {
                                    for py in (y ..< Int(layout.columnCount)).reversed() {
                                        editingItem.keys[.gridFit(x: px, y: py + 1)] = editingItem.keys[.gridFit(x: px, y: py)]
                                    }
                                }
                                for px in 0 ..< Int(layout.rowCount) {
                                    editingItem.keys[.gridFit(x: px, y: y)] = nil
                                }
                                editingItem.emptyKeys = editingItem.emptyKeys.mapSet { item in
                                    switch item {
                                    case .gridFit(x: let px, y: let py) where y <= py:
                                        return .gridFit(x: px, y: py + 1)
                                    default:
                                        return item
                                    }
                                }
                            }
                            Button("右に列を追加", systemImage: "plus") {
                                editingItem.rowCount = Int(editingItem.rowCount)?.advanced(by: 1).description ?? editingItem.rowCount
                                for px in (x + 1 ..< Int(layout.rowCount)).reversed() {
                                    for py in 0 ..< Int(layout.columnCount) {
                                        editingItem.keys[.gridFit(x: px + 1, y: py)] = editingItem.keys[.gridFit(x: px, y: py)]
                                    }
                                }
                                for py in 0 ..< Int(layout.columnCount) {
                                    editingItem.keys[.gridFit(x: x + 1, y: py)] = nil
                                }
                                editingItem.emptyKeys = editingItem.emptyKeys.mapSet { item in
                                    switch item {
                                    case .gridFit(x: let px, y: let py) where x + 1 <= px:
                                        return .gridFit(x: px + 1, y: py)
                                    default:
                                        return item
                                    }
                                }
                            }
                            Button("左に列を追加", systemImage: "plus") {
                                editingItem.rowCount = Int(editingItem.rowCount)?.advanced(by: 1).description ?? editingItem.rowCount
                                for px in (x ..< Int(layout.rowCount)).reversed() {
                                    for py in 0 ..< Int(layout.columnCount) {
                                        editingItem.keys[.gridFit(x: px + 1, y: py)] = editingItem.keys[.gridFit(x: px, y: py)]
                                    }
                                }
                                for py in 0 ..< Int(layout.columnCount) {
                                    editingItem.keys[.gridFit(x: x, y: py)] = nil
                                }
                                editingItem.emptyKeys = editingItem.emptyKeys.mapSet { item in
                                    switch item {
                                    case .gridFit(x: let px, y: let py) where x <= px:
                                        return .gridFit(x: px + 1, y: py)
                                    default:
                                        return item
                                    }
                                }
                            }
                            Divider()
                            Button("削除する", systemImage: "trash", role: .destructive) {
                                editingItem.emptyKeys.insert(.gridFit(x: x, y: y))
                            }
                            Button("この行を削除", systemImage: "trash", role: .destructive) {
                                removeRow(y: y)
                            }
                            Button("この列を削除", systemImage: "trash", role: .destructive) {
                                removeColumn(x: x)
                            }
                        }
                    }
                }
                .environmentObject(variableStates)
            } else {
                KeyboardPreview(defaultTab: .custard(custard))
            }
        }
        .onChange(of: layout) {_ in
            updateModel()
        }
        .background(Color.secondarySystemBackground)
        .navigationBarBackButtonHidden(true)
        .navigationTitle(Text("カスタムタブを作る"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                let hasChanges: Bool = self.base != self.editingItem
                EditCancelButton(confirmationRequired: hasChanges)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("保存") {
                    if isNewItem && manager.availableCustards.contains(editingItem.tabName) {
                        showDuplicateAlert = true
                    } else {
                        self.save()
                        let saved = custard
                        if self.shouldJustDimiss {
                            dismiss()
                        } else {
                            path.append(.information(saved.identifier))
                        }
                    }
                }
            }
        }
        .alert("名前が重複しています", isPresented: $showDuplicateAlert) {
            Button("OK", role: .cancel) {}
        }
        .onAppear {
            variableStates.setInterfaceSize(orientation: MainAppDesign.keyboardOrientation, screenWidth: SemiStaticStates.shared.screenWidth)
            if !self.baseSelectionSheetState.hasShown {
                self.baseSelectionSheetState.showBaseSelectionSheet = true
            }
        }
        .sheet(isPresented: self.$baseSelectionSheetState.showBaseSelectionSheet) {
            NavigationStack {
                List {
                    ForEach(baseCustards, id: \.identifier) {custard in
                        custardSelectionView(for: custard)
                    }
                    ForEach(manager.availableCustards, id: \.self) {identifier in
                        if let custard = self.getCustard(identifier: identifier),
                           case .tenkeyStyle = custard.interface.keyStyle,
                           case .gridFit = custard.interface.keyLayout {
                            custardSelectionView(for: custard)
                        }
                    }
                }
                .navigationTitle("ベースを選ぶ")
                Button("ベース無しで始める", systemImage: "xmark") {
                    self.baseSelectionSheetState.showBaseSelectionSheet = false
                    self.baseSelectionSheetState.hasShown = true
                }
                .foregroundStyle(.white)
                .buttonStyle(LargeButtonStyle(backgroundColor: .blue))
                .padding(.horizontal)
            }
        }
    }

    private var baseCustards: [Custard] {
        [
            Custard(
                identifier: "japanese_flick",
                language: .ja_JP,
                input_style: .direct,
                metadata: .init(
                    custard_version: .v1_2,
                    display_name: "日本語フリック"
                ),
                interface: CustardInterface(
                    keyStyle: .tenkeyStyle,
                    keyLayout: .gridFit(.init(rowCount: 5, columnCount: 4)),
                    keys: [
                        // 1列目
                        .gridFit(.init(x: 0, y: 0)): .system(.flickStar123Tab),
                        .gridFit(.init(x: 0, y: 1)): .system(.flickAbcTab),
                        .gridFit(.init(x: 0, y: 2)): .system(.flickHiraTab),
                        .gridFit(.init(x: 0, y: 3)): .system(.changeKeyboard),
                        // 2列目
                        .gridFit(.init(x: 1, y: 0)): .custom(
                            .flickSimpleInputs(center: "あ", left: "い", top: "う", right: "え", bottom: "お")
                        ),
                        .gridFit(.init(x: 1, y: 1)): .custom(
                            .flickSimpleInputs(center: "た", left: "ち", top: "つ", right: "て", bottom: "と")
                        ),
                        .gridFit(.init(x: 1, y: 2)): .custom(
                            .flickSimpleInputs(center: "ま", left: "み", top: "む", right: "め", bottom: "も")
                        ),
                        .gridFit(.init(x: 1, y: 3)): .system(.flickKogaki),
                        // 3列目
                        .gridFit(.init(x: 2, y: 0)): .custom(
                            .flickSimpleInputs(center: "か", left: "き", top: "く", right: "け", bottom: "こ")
                        ),
                        .gridFit(.init(x: 2, y: 1)): .custom(
                            .flickSimpleInputs(center: "な", left: "に", top: "ぬ", right: "ね", bottom: "の")
                        ),
                        .gridFit(.init(x: 2, y: 2)): .custom(
                            .flickSimpleInputs(center: "や", left: "「", top: "ゆ", right: "」", bottom: "よ")
                        ),
                        .gridFit(.init(x: 2, y: 3)): .custom(
                            .flickSimpleInputs(center: "わ", left: "を", top: "ん", right: "ー")
                        ),
                        // 4列目
                        .gridFit(.init(x: 3, y: 0)): .custom(
                            .flickSimpleInputs(center: "さ", left: "し", top: "す", right: "せ", bottom: "そ")
                        ),
                        .gridFit(.init(x: 3, y: 1)): .custom(
                            .flickSimpleInputs(center: "は", left: "ひ", top: "ふ", right: "へ", bottom: "ほ")
                        ),
                        .gridFit(.init(x: 3, y: 2)): .custom(
                            .flickSimpleInputs(center: "ら", left: "り", top: "る", right: "れ", bottom: "ろ")
                        ),
                        .gridFit(.init(x: 3, y: 3)): .system(.flickKutoten),
                        .gridFit(.init(x: 4, y: 0)): .custom(.flickDelete()),
                        .gridFit(.init(x: 4, y: 1)): .custom(.flickSpace()),
                        .gridFit(.init(x: 4, y: 2, width: 1, height: 2)): .system(.enter),
                    ]
                )
            ),
            Custard(
                identifier: "english_flick",
                language: .en_US,
                input_style: .direct,
                metadata: .init(
                    custard_version: .v1_2,
                    display_name: "英語フリック"
                ),
                interface: CustardInterface(
                    keyStyle: .tenkeyStyle,
                    keyLayout: .gridFit(.init(rowCount: 5, columnCount: 4)),
                    keys: [
                        // 1列目
                        .gridFit(.init(x: 0, y: 0)): .system(.flickStar123Tab),
                        .gridFit(.init(x: 0, y: 1)): .system(.flickAbcTab),
                        .gridFit(.init(x: 0, y: 2)): .system(.flickHiraTab),
                        .gridFit(.init(x: 0, y: 3)): .system(.changeKeyboard),

                        // 2列目
                        .gridFit(.init(x: 1, y: 0)): .custom(
                            .flickSimpleInputs(center: "@", subs: ["#", "/", "&", "_"], centerLabel: "@#/&_")
                        ),
                        .gridFit(.init(x: 1, y: 1)): .custom(
                            .flickSimpleInputs(center: "G", subs: ["H", "I"], centerLabel: "GHI")
                                .lowercasedInput()
                        ),
                        .gridFit(.init(x: 1, y: 2)): .custom(
                            .flickSimpleInputs(center: "P", subs: ["Q", "R", "S"], centerLabel: "PQRS")
                                .lowercasedInput()
                        ),
                        .gridFit(.init(x: 1, y: 3)): .system(.upperLower),   // a/A (大文字・小文字切替)

                        // 3列目
                        .gridFit(.init(x: 2, y: 0)): .custom(
                            .flickSimpleInputs(center: "A", subs: ["B", "C"], centerLabel: "ABC")
                                .lowercasedInput()
                        ),
                        .gridFit(.init(x: 2, y: 1)): .custom(
                            .flickSimpleInputs(center: "J", subs: ["K", "L"], centerLabel: "JKL")
                                .lowercasedInput()
                        ),
                        .gridFit(.init(x: 2, y: 2)): .custom(
                            .flickSimpleInputs(center: "T", subs: ["U", "V"], centerLabel: "TUV")
                                .lowercasedInput()
                        ),
                        .gridFit(.init(x: 2, y: 3)): .custom(
                            .flickSimpleInputs(center: "'", subs: ["\"", "(", ")"], centerLabel: "'\"()")
                        ),

                        // 4列目
                        .gridFit(.init(x: 3, y: 0)): .custom(
                            .flickSimpleInputs(center: "D", subs: ["E", "F"], centerLabel: "DEF")
                                .lowercasedInput()
                        ),
                        .gridFit(.init(x: 3, y: 1)): .custom(
                            .flickSimpleInputs(center: "M", subs: ["N", "O"], centerLabel: "MNO")
                                .lowercasedInput()
                        ),
                        .gridFit(.init(x: 3, y: 2)): .custom(
                            .flickSimpleInputs(center: "W", subs: ["X", "Y", "Z"], centerLabel: "WXYZ")
                                .lowercasedInput()
                        ),
                        .gridFit(.init(x: 3, y: 3)): .custom(
                            .flickSimpleInputs(center: ".", subs: [",", "?", "!"], centerLabel: ".,?!")
                        ),

                        // 5列目 (システムキー列)
                        .gridFit(.init(x: 4, y: 0)): .custom(.flickDelete()),
                        .gridFit(.init(x: 4, y: 1)): .custom(.flickSpace()),
                        .gridFit(.init(x: 4, y: 2, width: 1, height: 2)): .system(.enter),
                    ]
                )
            ),
            Custard(
                identifier: "symbols_flick",
                language: .ja_JP,
                input_style: .direct,
                metadata: .init(
                    custard_version: .v1_2,
                    display_name: "記号フリック"
                ),
                interface: CustardInterface(
                    keyStyle: .tenkeyStyle,
                    keyLayout: .gridFit(.init(rowCount: 5, columnCount: 4)),
                    keys: [
                        // 1列目
                        .gridFit(.init(x: 0, y: 0)): .system(.flickStar123Tab),
                        .gridFit(.init(x: 0, y: 1)): .system(.flickAbcTab),
                        .gridFit(.init(x: 0, y: 2)): .system(.flickHiraTab),
                        .gridFit(.init(x: 0, y: 3)): .system(.changeKeyboard),

                        // 2列目
                        .gridFit(.init(x: 1, y: 0)): .custom(
                            .flickSimpleInputs(center: "1", subs: ["☆", "♪", "→"])
                                .mainAndSubLabel()
                        ),
                        .gridFit(.init(x: 1, y: 1)): .custom(
                            .flickSimpleInputs(center: "4", subs: ["○", "＊", "・"])
                                .mainAndSubLabel()
                        ),
                        .gridFit(.init(x: 1, y: 2)): .custom(
                            .flickSimpleInputs(center: "7", subs: ["「", "」", ":"])
                                .mainAndSubLabel()
                        ),
                        .gridFit(.init(x: 1, y: 3)): .custom(
                            .flickSimpleInputs(center: "(", subs: [")", "[", "]"], centerLabel: "()[]")
                        ),

                        // 3列目
                        .gridFit(.init(x: 2, y: 0)): .custom(
                            .flickSimpleInputs(center: "2", subs: ["¥", "$", "€"])
                                .mainAndSubLabel()
                        ),
                        .gridFit(.init(x: 2, y: 1)): .custom(
                            .flickSimpleInputs(center: "5", subs: ["+", "×", "÷"])
                                .mainAndSubLabel()
                        ),
                        .gridFit(.init(x: 2, y: 2)): .custom(
                            .flickSimpleInputs(center: "8", subs: ["〒", "々", "〆"])
                                .mainAndSubLabel()
                        ),
                        .gridFit(.init(x: 2, y: 3)): .custom(
                            .flickSimpleInputs(center: "0", subs: ["〜", "…"])
                                .mainAndSubLabel()
                        ),

                        // 4列目
                        .gridFit(.init(x: 3, y: 0)): .custom(
                            .flickSimpleInputs(center: "3", subs: ["%", "°", "#"])
                                .mainAndSubLabel()
                        ),
                        .gridFit(.init(x: 3, y: 1)): .custom(
                            .flickSimpleInputs(center: "6", subs: ["<", "=", ">"])
                                .mainAndSubLabel()
                        ),
                        .gridFit(.init(x: 3, y: 2)): .custom(
                            .flickSimpleInputs(center: "9", subs: ["^", "|", "\\"])
                                .mainAndSubLabel()
                        ),
                        .gridFit(.init(x: 3, y: 3)): .custom(
                            .flickSimpleInputs(center: ".", subs: [",", "-", "/"], centerLabel: ".,-/")
                        ),

                        // 5列目
                        .gridFit(.init(x: 4, y: 0)): .custom(.flickDelete()),
                        .gridFit(.init(x: 4, y: 1)): .custom(.flickSpace()),
                        .gridFit(.init(x: 4, y: 2, width: 1, height: 2)): .system(.enter),
                    ]
                )
            ),
        ]
    }

    private func custardSelectionView(for custard: Custard) -> some View {
        VStack {
            CenterAlignedView {
                KeyboardPreview(scale: 0.7, defaultTab: .custard(custard))
            }
            .disabled(true)
            .overlay(alignment: .bottom) {
                Text(custard.metadata.display_name)
                    .bold()
                    .font(.caption)
                    .padding(8)
                    .background {
                        Capsule()
                            .foregroundStyle(.regularMaterial)
                            .shadow(radius: 1.5)
                    }
                    .padding(.bottom, 4)
            }
            .onTapGesture {
                self.selectBaseCustard(custard)
                self.baseSelectionSheetState.showBaseSelectionSheet = false
                self.baseSelectionSheetState.hasShown = true
            }
            .contextMenu {
                Button("選択", systemImage: "checkmark") {
                    self.selectBaseCustard(custard)
                    self.baseSelectionSheetState.showBaseSelectionSheet = false
                    self.baseSelectionSheetState.hasShown = true
                }
            }
        }
    }

    private func selectBaseCustard(_ custard: Custard) {
        self.editingItem = custard.userMadeTenKeyCustard ?? Self.emptyItem
        let identifiers = self.manager.availableCustards.compactMap { self.getCustard(identifier: $0)?.identifier }
        if identifiers.contains(self.editingItem.tabName) {
            let d = (1...).first {
                !identifiers.contains(self.editingItem.tabName + "#\($0)")
            }!
            self.editingItem.tabName += "#\(d)"
        }
        self.baseSelectionSheetState.showBaseSelectionSheet = false
        self.baseSelectionSheetState.hasShown = true
    }

    private func getCustard(identifier: String) -> Custard? {
        do {
            let custard = try manager.custard(identifier: identifier)
            return custard
        } catch {
            debug(error)
            return nil
        }
    }

    private func removeColumn(x: Int) {
        for px in x + 1 ..< Int(layout.rowCount) {
            for py in 0 ..< Int(layout.columnCount) {
                editingItem.keys[.gridFit(x: px - 1, y: py)] = editingItem.keys[.gridFit(x: px, y: py)]
            }
        }
        editingItem.rowCount = Int(editingItem.rowCount)?.advanced(by: -1).description ?? editingItem.rowCount
        editingItem.emptyKeys = editingItem.emptyKeys.compactMapSet { item in
            switch item {
            case .gridFit(x: let px, y: _) where px == x:
                return nil
            case .gridFit(x: let px, y: let py) where x + 1 <= px:
                return .gridFit(x: px - 1, y: py)
            default:
                return item
            }
        }
    }

    private func removeRow(y: Int) {
        for px in 0 ..< Int(layout.rowCount) {
            for py in y + 1 ..< Int(layout.columnCount) {
                editingItem.keys[.gridFit(x: px, y: py - 1)] = editingItem.keys[.gridFit(x: px, y: py)]
            }
        }
        editingItem.columnCount = Int(editingItem.columnCount)?.advanced(by: -1).description ?? editingItem.columnCount
        editingItem.emptyKeys = editingItem.emptyKeys.compactMapSet { item in
            switch item {
            case .gridFit(x: _, y: let py) where y == py:
                return nil
            case .gridFit(x: let px, y: let py) where y + 1 <= py:
                return .gridFit(x: px, y: py - 1)
            default:
                return item
            }
        }
    }

    private func updateModel() {
        let layout = layout
        (0..<layout.rowCount).forEach {x in
            (0..<layout.columnCount).forEach {y in
                if !editingItem.keys.keys.contains(.gridFit(x: x, y: y)) {
                    editingItem.keys[.gridFit(x: x, y: y)] = .init(model: .custom(.empty), width: 1, height: 1)
                }
            }
        }
        for key in editingItem.keys.keys {
            guard case let .gridFit(x: x, y: y) = key else {
                continue
            }
            if x < 0 || layout.rowCount <= x || y < 0 || layout.columnCount <= y {
                if editingItem.keys[key] == Self.emptyKey {
                    editingItem.keys[key] = nil
                }
            }
        }
    }

    private func save() {
        do {
            try self.manager.saveCustard(
                custard: custard,
                metadata: .init(origin: .userMade),
                userData: .tenkey(editingItem),
                updateTabBar: self.isNewItem && self.editingItem.addTabBarAutomatically
            )
        } catch {
            debug(error)
        }
    }

    func cancel() {
        // required for `CancelableEditor` conformance, but in this view, it is treated by `EditCancelButton`
    }
}

extension CustardInterfaceCustomKey {
    /// 小文字カスタードを記述するためのヘルパー関数
    consuming func lowercasedInput() -> CustardInterfaceCustomKey {
        let transform: (CodableActionData) -> CodableActionData = {
            switch $0 {
            case .input(let value): .input(value.lowercased())
            default: $0
            }
        }
        self.press_actions = self.press_actions.map(transform)
        self.longpress_actions.start = self.longpress_actions.start.map(transform)
        self.longpress_actions.repeat = self.longpress_actions.repeat.map(transform)
        self.variations.mutatingForEach { variation in
            variation.key.press_actions = variation.key.press_actions.map(transform)
            variation.key.longpress_actions.start = variation.key.longpress_actions.start.map(transform)
            variation.key.longpress_actions.repeat = variation.key.longpress_actions.repeat.map(transform)
        }
        return self
    }
    /// ベースカスタードを記述するためのヘルパー関数
    consuming func mainAndSubLabel() -> CustardInterfaceCustomKey {
        let center: String? = self.press_actions.first.flatMap {
            if case let .input(value) = $0 {
                value
            } else {
                nil
            }
        }
        let subs: [String] = self.variations.compactMap { (variation: CustardInterfaceVariation) in
            variation.key.press_actions.first.flatMap {
                if case let .input(value) = $0 {
                    value
                } else {
                    nil
                }
            }
        }
        if let center {
            self.design = .init(label: .mainAndSub(center, subs.joined()), color: .normal)
        }
        return self
    }

}
