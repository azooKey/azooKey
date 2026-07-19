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
struct EditingGridFitCustardView: CancelableEditor {
    private static let emptyKey: UserMadeKeyData = .init(model: .custom(.empty), width: 1, height: 1)
    private static let emptyKeys: [KeyPosition: UserMadeKeyData] = (0..<5).reduce(into: [:]) {dict, x in
        (0..<4).forEach {y in
            dict[.gridFit(x: x, y: y)] = emptyKey
        }
    }
    private static let emptyItem: UserMadeGridFitCustard = .init(tabName: "新規タブ", rowCount: "5", columnCount: "4", inputStyle: .direct, language: .ja_JP, keys: emptyKeys, addTabBarAutomatically: true)

    let base: UserMadeGridFitCustard
    @StateObject private var variableStates = VariableStates(clipboardHistoryManagerConfig: ClipboardHistoryManagerConfig(), tabManagerConfig: TabManagerConfig(), userDefaults: UserDefaults.standard)
    @State private var editingItem: UserMadeGridFitCustard
    @Binding private var manager: CustardManager

    // MARK: 遷移
    private let isNewItem: Bool
    private let onFinishEditing: ((String) -> Void)?
    @Environment(\.dismiss) var dismiss

    // MARK: UI表示系
    @State private var showPreview = false
    @State private var baseSelectionSheetState = BaseSelectionSheetState()
    private struct BaseSelectionSheetState: Sendable, Equatable, Hashable {
        var showBaseSelectionSheet = false
        var hasShown = false
    }
    @State private var showDuplicateAlert = false

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
                keyStyle: editingItem.keyStyle.interfaceStyle,
                keyLayout: .gridFit(layout),
                keys: editingItem.keys.reduce(into: [:]) {dict, item in
                    if case let .gridFit(x: x, y: y) = item.key, !editingItem.emptyKeys.contains(item.key) {
                        dict[.gridFit(.init(x: x, y: y, width: item.value.width, height: item.value.height))] = item.value.model
                    }
                }
            )
        )
    }

    private var editingInterface: CustardInterface {
        .init(
            keyStyle: editingItem.keyStyle.interfaceStyle,
            keyLayout: .gridFit(layout),
            keys: editingItem.keys.reduce(into: [:]) {dict, item in
                if case let .gridFit(x: x, y: y) = item.key {
                    dict[.gridFit(.init(x: x, y: y, width: item.value.width, height: item.value.height))] = item.value.model
                }
            }
        )
    }

    init(manager: Binding<CustardManager>, editingItem: UserMadeGridFitCustard? = nil, onFinishEditing: ((String) -> Void)? = nil) {
        self._manager = manager
        self.onFinishEditing = onFinishEditing
        self.baseSelectionSheetState = .init(hasShown: editingItem != nil)  // 編集の場合はすでにbase選択は終わったと考える
        self.base = editingItem ?? Self.emptyItem
        self._editingItem = State(initialValue: self.base)
        self.isNewItem = editingItem == nil
    }

    private func isCovered(at position: (x: Double, y: Double)) -> Bool {
        editingItem.keys.contains { key, data in
            guard case let .gridFit(x, y) = key,
                  key != .gridFit(x: position.x, y: position.y),
                  !editingItem.emptyKeys.contains(key) else {
                return false
            }
            return x < position.x + 1
                && position.x < x + data.width
                && y < position.y + 1
                && position.y < y + data.height
        }
    }

    private var interfaceSize: CGSize {
        let context = MainAppDesign.keyboardLayoutContext(
            containerWidth: UIScreen.main.bounds.width
        )
        return .init(
            width: context.containerWidth,
            height: Design.keyboardHeight(context: context)
        )
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
                Picker("レイアウトスタイル", selection: $editingItem.keyStyle) {
                    Text("フリック").tag(UserMadeGridFitCustard.KeyStyle.tenkeyStyle)
                    Text("QWERTY").tag(UserMadeGridFitCustard.KeyStyle.pcStyle)
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
                let design = TabDependentDesign(
                    width: layout.rowCount,
                    height: layout.columnCount,
                    interfaceSize: interfaceSize,
                    layoutContext: MainAppDesign.keyboardLayoutContext(
                        containerWidth: interfaceSize.width
                    )
                )
                let unifiedModels = editingInterface.unifiedKeyModels(extension: AzooKeyKeyboardViewExtension.self)
                UnifiedKeysView(models: unifiedModels, tabDesign: design) { (view: UnifiedGenericKeyView<AzooKeyKeyboardViewExtension>, pos: UnifiedPositionSpecifier) in
                    let x = Double(pos.x)
                    let y = Double(pos.y)
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
                                        Image(systemName: "plus.circle").foregroundStyle(.accentColor)
                                    }
                            }
                        }
                    } else {
                        NavigationLink {
                            CustardInterfaceKeyEditor(data: $editingItem.keys[.gridFit(x: x, y: y)])
                        } label: {
                            view.disabled(true).border(Color.primary)
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
                                insertRow(at: Int(y.rounded(.down)) + 1)
                            }
                            Button("上に行を追加", systemImage: "plus") {
                                insertRow(at: Int(y.rounded(.down)))
                            }
                            Button("右に列を追加", systemImage: "plus") {
                                insertColumn(at: Int(x.rounded(.down)) + 1)
                            }
                            Button("左に列を追加", systemImage: "plus") {
                                insertColumn(at: Int(x.rounded(.down)))
                            }
                            Divider()
                            Button("削除する", systemImage: "trash", role: .destructive) {
                                editingItem.emptyKeys.insert(.gridFit(x: x, y: y))
                            }
                            Button("この行を削除", systemImage: "trash", role: .destructive) {
                                removeRow(y: Int(y.rounded(.down)))
                            }
                            Button("この列を削除", systemImage: "trash", role: .destructive) {
                                removeColumn(x: Int(x.rounded(.down)))
                            }
                        }
                    }
                }
                .environmentObject(variableStates)
            } else {
                KeyboardPreview(defaultTab: .custard(custard))
            }
        }
        .onChange(of: layout) { (_, _) in
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
                EditConfirmButton {
                    if isNewItem && manager.availableCustards.contains(editingItem.tabName) {
                        showDuplicateAlert = true
                    } else {
                        self.save()
                        let saved = custard
                        if let onFinishEditing {
                            onFinishEditing(saved.identifier)
                        } else {
                            dismiss()
                        }
                    }
                }
            }
        }
        .alert("名前が重複しています", isPresented: $showDuplicateAlert) {
            Button("OK", role: .cancel) {}
        }
        .onAppear {
            variableStates.setContainerWidth(
                SemiStaticStates.shared.screenWidth,
                orientation: MainAppDesign.keyboardOrientation
            )
            if !self.baseSelectionSheetState.hasShown {
                self.baseSelectionSheetState.showBaseSelectionSheet = true
            }
        }
        .sheet(isPresented: self.$baseSelectionSheetState.showBaseSelectionSheet, onDismiss: {
            self.baseSelectionSheetState.hasShown = true
        }) {
            NavigationStack {
                List {
                    ForEach(baseCustards, id: \.identifier) {custard in
                        custardSelectionView(for: custard)
                    }
                    ForEach(manager.availableCustards, id: \.self) {identifier in
                        if let custard = self.getCustard(identifier: identifier),
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
            Custard.flickJapanese,
            Custard.flickEnglish,
            Custard.flickNumberSymbols,
            Custard.qwertyJapanese,
            Custard.qwertyEnglish(
                useShiftKey: UseShiftKey.value,
                useDeprecatedShiftKeyBehavior: {
                    if #available(iOS 18, *) {
                        false
                    } else {
                        KeepDeprecatedShiftKeyBehavior.value
                    }
                }()
            ),
            Custard.qwertyNumbers(
                customKeys: NumberTabCustomKeysSetting.value
            ),
            Custard.qwertySymbols,
        ]
    }

    private func custardSelectionView(for custard: Custard) -> some View {
        VStack {
            CenterAlignedView {
                KeyboardPreview(
                    defaultTab: .custard(custard)
                )
            }
            .disabled(true)
            .overlay(alignment: .bottom) {
                Label(title: { Text(verbatim: custard.metadata.display_name) }, icon: EmptyView.init)
                    .labelStyle(LiquidLabelStyle())
                    .labelStyle(.titleOnly)
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
        self.editingItem = custard.userMadeGridFitCustard ?? Self.emptyItem
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

    private func insertColumn(at x: Int) {
        let boundary = Double(x)
        transformGridPositions { positionX, positionY in
            .gridFit(
                x: positionX >= boundary ? positionX + 1 : positionX,
                y: positionY
            )
        }
        editingItem.rowCount =
            Int(editingItem.rowCount)?.advanced(by: 1).description
            ?? editingItem.rowCount
    }

    private func insertRow(at y: Int) {
        let boundary = Double(y)
        transformGridPositions { positionX, positionY in
            .gridFit(
                x: positionX,
                y: positionY >= boundary ? positionY + 1 : positionY
            )
        }
        editingItem.columnCount =
            Int(editingItem.columnCount)?.advanced(by: 1).description
            ?? editingItem.columnCount
    }

    private func removeColumn(x: Int) {
        guard layout.rowCount > 1 else {
            return
        }
        let lowerBound = Double(x)
        let upperBound = lowerBound + 1
        transformGridPositions { positionX, positionY in
            if lowerBound <= positionX, positionX < upperBound {
                return nil
            }
            return .gridFit(
                x: positionX >= upperBound ? positionX - 1 : positionX,
                y: positionY
            )
        }
        editingItem.rowCount =
            Int(editingItem.rowCount)?.advanced(by: -1).description
            ?? editingItem.rowCount
    }

    private func removeRow(y: Int) {
        guard layout.columnCount > 1 else {
            return
        }
        let lowerBound = Double(y)
        let upperBound = lowerBound + 1
        transformGridPositions { positionX, positionY in
            if lowerBound <= positionY, positionY < upperBound {
                return nil
            }
            return .gridFit(
                x: positionX,
                y: positionY >= upperBound ? positionY - 1 : positionY
            )
        }
        editingItem.columnCount =
            Int(editingItem.columnCount)?.advanced(by: -1).description
            ?? editingItem.columnCount
    }

    private func transformGridPositions(
        _ transform: (Double, Double) -> KeyPosition?
    ) {
        editingItem.keys = editingItem.keys.reduce(into: [:]) { result, item in
            switch item.key {
            case let .gridFit(x, y):
                if let position = transform(x, y) {
                    result[position] = item.value
                }
            case .gridScroll:
                result[item.key] = item.value
            }
        }
        editingItem.emptyKeys = Set(
            editingItem.emptyKeys.compactMap { position in
                switch position {
                case let .gridFit(x, y):
                    transform(x, y)
                case .gridScroll:
                    position
                }
            }
        )
    }

    private func updateModel() {
        let layout = layout
        (0..<layout.rowCount).forEach {x in
            (0..<layout.columnCount).forEach {y in
                let position = KeyPosition.gridFit(
                    x: Double(x),
                    y: Double(y)
                )
                if !editingItem.keys.keys.contains(position) {
                    editingItem.keys[position] = .init(
                        model: .custom(.empty),
                        width: 1,
                        height: 1
                    )
                }
            }
        }
        for key in editingItem.keys.keys {
            guard case let .gridFit(x: x, y: y) = key else {
                continue
            }
            if x < 0
                || Double(layout.rowCount) <= x
                || y < 0
                || Double(layout.columnCount) <= y {
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
