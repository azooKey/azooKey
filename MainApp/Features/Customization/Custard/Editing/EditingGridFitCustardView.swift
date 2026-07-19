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

private struct GridFitKeyPlacement: Equatable, Sendable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double

    var frame: GridFitPositionSpecifier {
        .init(x: x, y: y, width: width, height: height)
    }
}

private struct GridFitPlacementEditorTarget: Identifiable {
    let id = UUID()
    var originalPosition: KeyPosition?
    var placement: GridFitKeyPlacement
}

private func gridFramesIntersect(
    _ lhs: GridFitPositionSpecifier,
    _ rhs: GridFitPositionSpecifier
) -> Bool {
    lhs.x < rhs.x + rhs.width
        && rhs.x < lhs.x + lhs.width
        && lhs.y < rhs.y + rhs.height
        && rhs.y < lhs.y + lhs.height
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
    @State private var placementEditorTarget: GridFitPlacementEditorTarget?
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

    private func gridFrame(
        position: KeyPosition,
        data: UserMadeKeyData
    ) -> GridFitPositionSpecifier? {
        guard case let .gridFit(x, y) = position else {
            return nil
        }
        return .init(x: x, y: y, width: data.width, height: data.height)
    }

    private func activeKeyFrames(
        excluding excludedPosition: KeyPosition? = nil
    ) -> [GridFitPositionSpecifier] {
        editingItem.keys.compactMap { position, data in
            guard position != excludedPosition,
                  !editingItem.emptyKeys.contains(position) else {
                return nil
            }
            return gridFrame(position: position, data: data)
        }
    }

    private func defaultKeyPlacement() -> GridFitKeyPlacement {
        if let position = editingItem.emptyKeys.first,
           editingItem.keys[position] != nil,
           case let .gridFit(x, y) = position {
            return .init(x: x, y: y, width: 1, height: 1)
        }

        let occupied = activeKeyFrames()
        for y in 0 ..< layout.columnCount {
            for x in 0 ..< layout.rowCount {
                let placement = GridFitKeyPlacement(
                    x: Double(x),
                    y: Double(y),
                    width: 1,
                    height: 1
                )
                if !occupied.contains(where: {
                    gridFramesIntersect($0, placement.frame)
                }) {
                    return placement
                }
            }
        }
        return .init(x: 0, y: 0, width: 1, height: 1)
    }

    private func showPlacementEditor(for position: KeyPosition? = nil) {
        if let position,
           let data = editingItem.keys[position],
           case let .gridFit(x, y) = position {
            placementEditorTarget = .init(
                originalPosition: position,
                placement: .init(
                    x: x,
                    y: y,
                    width: data.width,
                    height: data.height
                )
            )
        } else {
            placementEditorTarget = .init(
                originalPosition: nil,
                placement: defaultKeyPlacement()
            )
        }
    }

    private func applyPlacement(
        _ placement: GridFitKeyPlacement,
        replacing originalPosition: KeyPosition?
    ) {
        let keyData: UserMadeKeyData
        if let originalPosition,
           let originalData = editingItem.keys.removeValue(
               forKey: originalPosition
           ) {
            editingItem.emptyKeys.remove(originalPosition)
            keyData = originalData
        } else {
            keyData = .init(model: .custom(.empty), width: 1, height: 1)
        }

        let overlappingDeletedKeys = editingItem.emptyKeys.filter { position in
            guard let data = editingItem.keys[position],
                  let frame = gridFrame(position: position, data: data) else {
                return false
            }
            return gridFramesIntersect(frame, placement.frame)
        }
        for position in overlappingDeletedKeys {
            editingItem.emptyKeys.remove(position)
            editingItem.keys[position] = nil
        }

        editingItem.keys[.gridFit(x: placement.x, y: placement.y)] = .init(
            model: keyData.model,
            width: placement.width,
            height: placement.height
        )
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
                    Button("キーを追加", systemImage: "plus.square") {
                        showPlacementEditor()
                    }
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
                        Button {
                            editingItem.emptyKeys.remove(.gridFit(x: x, y: y))
                        } label: {
                            view.disabled(true)
                                .opacity(0)
                                .overlay {
                                    Rectangle().stroke(style: .init(lineWidth: 2, dash: [5]))
                                }
                                .overlay {
                                    Image(systemName: "arrow.uturn.backward.circle")
                                        .foregroundStyle(.accentColor)
                                }
                        }
                    } else {
                        NavigationLink {
                            GridFitCustardKeyEditor(
                                keyData: $editingItem.keys[
                                    .gridFit(x: x, y: y)
                                ]
                            ) {
                                showPlacementEditor(
                                    for: .gridFit(x: x, y: y)
                                )
                            }
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
                            Button(
                                "配置を変更",
                                systemImage:
                                    "arrow.up.left.and.arrow.down.right"
                            ) {
                                showPlacementEditor(
                                    for: .gridFit(x: x, y: y)
                                )
                            }
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
            normalizeEmptyKeys()
            if !self.baseSelectionSheetState.hasShown {
                self.baseSelectionSheetState.showBaseSelectionSheet = true
            }
        }
        .sheet(
            isPresented: self.$baseSelectionSheetState.showBaseSelectionSheet,
            onDismiss: {
                self.baseSelectionSheetState.hasShown = true
            },
            content: {
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
        )
        .sheet(item: $placementEditorTarget) { target in
            GridFitKeyPlacementEditor(
                initialPlacement: target.placement,
                horizontalCount: layout.rowCount,
                verticalCount: layout.columnCount,
                occupied: activeKeyFrames(
                    excluding: target.originalPosition
                ),
                isNewKey: target.originalPosition == nil
            ) { placement in
                applyPlacement(
                    placement,
                    replacing: target.originalPosition
                )
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
        var frames = editingItem.keys.compactMap { position, data in
            gridFrame(position: position, data: data)
        }
        (0..<layout.rowCount).forEach {x in
            (0..<layout.columnCount).forEach {y in
                let position = KeyPosition.gridFit(
                    x: Double(x),
                    y: Double(y)
                )
                let frame = GridFitPositionSpecifier(
                    x: Double(x),
                    y: Double(y)
                )
                guard !editingItem.keys.keys.contains(position),
                      !frames.contains(where: {
                          gridFramesIntersect($0, frame)
                      }) else {
                    return
                }
                editingItem.keys[position] = .init(
                    model: .custom(.empty),
                    width: 1,
                    height: 1
                )
                frames.append(frame)
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
                if let data = editingItem.keys[key],
                   isEmptyUnitKey(data) {
                    editingItem.keys[key] = nil
                    editingItem.emptyKeys.remove(key)
                }
            }
        }
    }

    private func normalizeEmptyKeys() {
        editingItem.emptyKeys = editingItem.emptyKeys.filter {
            editingItem.keys[$0] != nil
        }
        let activeFrames = activeKeyFrames()
        let obsoletePositions = editingItem.emptyKeys.filter { position in
            guard let data = editingItem.keys[position],
                  isEmptyUnitKey(data),
                  let frame = gridFrame(position: position, data: data) else {
                return false
            }
            return activeFrames.contains(where: {
                gridFramesIntersect($0, frame)
            })
        }
        for position in obsoletePositions {
            editingItem.emptyKeys.remove(position)
            editingItem.keys[position] = nil
        }
    }

    private func isEmptyUnitKey(_ data: UserMadeKeyData) -> Bool {
        data.model == .custom(.empty)
            && data.width == 1
            && data.height == 1
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

@MainActor
private struct GridFitCustardKeyEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Binding private var keyData: UserMadeKeyData
    @State private var opensPlacementEditorOnDismiss = false

    private let onEditPlacement: () -> Void

    init(
        keyData: Binding<UserMadeKeyData>,
        onEditPlacement: @escaping () -> Void
    ) {
        self._keyData = keyData
        self.onEditPlacement = onEditPlacement
    }

    var body: some View {
        CustardInterfaceKeyEditor(data: $keyData) {
            opensPlacementEditorOnDismiss = true
            dismiss()
        }
        .onDisappear {
            if opensPlacementEditorOnDismiss {
                opensPlacementEditorOnDismiss = false
                onEditPlacement()
            }
        }
    }
}

@MainActor
private struct GridFitKeyPlacementEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var xText: String
    @State private var yText: String
    @State private var widthText: String
    @State private var heightText: String
    @State private var usesFineAdjustment = false

    private let horizontalCount: Int
    private let verticalCount: Int
    private let occupied: [GridFitPositionSpecifier]
    private let isNewKey: Bool
    private let onSave: (GridFitKeyPlacement) -> Void

    init(
        initialPlacement: GridFitKeyPlacement,
        horizontalCount: Int,
        verticalCount: Int,
        occupied: [GridFitPositionSpecifier],
        isNewKey: Bool,
        onSave: @escaping (GridFitKeyPlacement) -> Void
    ) {
        self._xText = State(initialValue: String(initialPlacement.x))
        self._yText = State(initialValue: String(initialPlacement.y))
        self._widthText = State(initialValue: String(initialPlacement.width))
        self._heightText = State(initialValue: String(initialPlacement.height))
        self.horizontalCount = horizontalCount
        self.verticalCount = verticalCount
        self.occupied = occupied
        self.isNewKey = isNewKey
        self.onSave = onSave
    }

    private var placement: GridFitKeyPlacement? {
        guard let x = decimalValue(xText),
              let y = decimalValue(yText),
              let width = decimalValue(widthText),
              let height = decimalValue(heightText),
              x.isFinite,
              y.isFinite,
              width.isFinite,
              height.isFinite else {
            return nil
        }
        return .init(x: x, y: y, width: width, height: height)
    }

    private var inputErrorMessage: String? {
        guard let placement else {
            return "すべての項目に数値を入力してください"
        }
        guard placement.width > 0, placement.height > 0 else {
            return "横幅と縦幅は0より大きくしてください"
        }
        guard !occupied.contains(where: {
            $0.x == placement.x && $0.y == placement.y
        }) else {
            return "同じX座標・Y座標のキーがすでにあります"
        }
        return nil
    }

    private var adjustmentStep: Double {
        usesFineAdjustment ? 0.1 : 1
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("配置プレビュー") {
                    placementPreview
                    if let inputErrorMessage {
                        Label(
                            inputErrorMessage,
                            systemImage: "exclamationmark.triangle"
                        )
                        .foregroundStyle(.red)
                    }
                }
                Section("位置") {
                    decimalStepperField("X座標", text: $xText)
                    decimalStepperField("Y座標", text: $yText)
                    movementButtons
                    Text("左上をX: 0、Y: 0とするグリッド座標です")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Section("サイズ") {
                    decimalStepperField(
                        "横幅",
                        text: $widthText,
                        mustRemainPositive: true
                    )
                    decimalStepperField(
                        "縦幅",
                        text: $heightText,
                        mustRemainPositive: true
                    )
                }
                Section {
                    Toggle(
                        "0.1刻みで微調整",
                        isOn: $usesFineAdjustment
                    )
                }
            }
            .navigationTitle(isNewKey ? "キーを追加" : "キーの配置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") {
                        guard let placement, inputErrorMessage == nil else {
                            return
                        }
                        onSave(placement)
                        dismiss()
                    }
                    .disabled(inputErrorMessage != nil)
                }
            }
        }
    }

    private var placementPreview: some View {
        GeometryReader { geometry in
            let unitWidth = geometry.size.width
                / CGFloat(max(horizontalCount, 1))
            let unitHeight = geometry.size.height
                / CGFloat(max(verticalCount, 1))
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondarySystemBackground)
                ForEach(Array(occupied.enumerated()), id: \.offset) { _, frame in
                    RoundedRectangle(cornerRadius: 5)
                    .fill(Color.secondary.opacity(0.35))
                    .frame(
                        width: previewKeyWidth(
                            frame,
                            unitWidth: unitWidth
                        ),
                        height: previewKeyHeight(
                            frame,
                            unitHeight: unitHeight
                        )
                    )
                    .offset(
                        x: unitWidth * CGFloat(frame.x) + 2,
                        y: unitHeight * CGFloat(frame.y) + 2
                    )
                }
                if let placement {
                    let frame = placement.frame
                    RoundedRectangle(cornerRadius: 5)
                    .fill(Color.accentColor.opacity(0.75))
                    .frame(
                        width: previewKeyWidth(
                            frame,
                            unitWidth: unitWidth
                        ),
                        height: previewKeyHeight(
                            frame,
                            unitHeight: unitHeight
                        )
                    )
                    .offset(
                        x: unitWidth * CGFloat(frame.x) + 2,
                        y: unitHeight * CGFloat(frame.y) + 2
                    )
                }
            }
            .clipped()
        }
        .frame(height: 100)
    }

    private var movementButtons: some View {
        Grid(horizontalSpacing: 12, verticalSpacing: 8) {
            GridRow {
                Color.clear.frame(width: 44, height: 1)
                movementButton(
                    "上へ移動",
                    systemImage: "arrow.up",
                    x: 0,
                    y: -adjustmentStep
                )
                Color.clear.frame(width: 44, height: 1)
            }
            GridRow {
                movementButton(
                    "左へ移動",
                    systemImage: "arrow.left",
                    x: -adjustmentStep,
                    y: 0
                )
                movementButton(
                    "下へ移動",
                    systemImage: "arrow.down",
                    x: 0,
                    y: adjustmentStep
                )
                movementButton(
                    "右へ移動",
                    systemImage: "arrow.right",
                    x: adjustmentStep,
                    y: 0
                )
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func movementButton(
        _ title: LocalizedStringKey,
        systemImage: String,
        x: Double,
        y: Double
    ) -> some View {
        Button {
            adjustText($xText, by: x)
            adjustText($yText, by: y)
        } label: {
            Label(title, systemImage: systemImage)
                .labelStyle(.iconOnly)
                .frame(width: 44, height: 36)
        }
        .buttonStyle(.bordered)
    }

    private func previewKeyWidth(
        _ frame: GridFitPositionSpecifier,
        unitWidth: CGFloat
    ) -> CGFloat {
        max(4, unitWidth * CGFloat(frame.width) - 4)
    }

    private func previewKeyHeight(
        _ frame: GridFitPositionSpecifier,
        unitHeight: CGFloat
    ) -> CGFloat {
        max(4, unitHeight * CGFloat(frame.height) - 4)
    }

    private func decimalStepperField(
        _ title: LocalizedStringKey,
        text: Binding<String>,
        mustRemainPositive: Bool = false
    ) -> some View {
        Stepper {
            HStack {
                Text(title)
                Spacer()
                TextField("0", text: text)
                    .frame(minWidth: 64, maxWidth: 100)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
            }
        } onIncrement: {
            adjustText(
                text,
                by: adjustmentStep,
                mustRemainPositive: mustRemainPositive
            )
        } onDecrement: {
            adjustText(
                text,
                by: -adjustmentStep,
                mustRemainPositive: mustRemainPositive
            )
        }
    }

    private func adjustText(
        _ text: Binding<String>,
        by delta: Double,
        mustRemainPositive: Bool = false
    ) {
        guard let value = decimalValue(text.wrappedValue) else {
            return
        }
        let adjusted = normalized(value + delta)
        guard !mustRemainPositive || adjusted > 0 else {
            return
        }
        text.wrappedValue = decimalString(adjusted)
    }

    private func normalized(_ value: Double) -> Double {
        (value * 1_000_000).rounded() / 1_000_000
    }

    private func decimalString(_ value: Double) -> String {
        String(normalized(value))
    }

    private func decimalValue(_ text: String) -> Double? {
        Double(text.replacingOccurrences(of: ",", with: "."))
    }
}
