//
//  TabNavigationEditView.swift
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
import SwiftUtils
import SwiftUIUtils

struct EditingTabBarItem: Identifiable, Equatable {
    let id = UUID()
    var label: TabBarItemLabelType
    var actions: [CodableActionData]
    var pinned: Bool
    var disclosed: Bool

    init(label: TabBarItemLabelType, pinned: Bool, actions: [CodableActionData], disclosed: Bool = false) {
        self.label = label
        self.pinned = pinned
        self.actions = actions
        self.disclosed = disclosed
    }
}

struct EditingTabBarView: View {
    @Binding private var manager: CustardManager
    @State private var items: [EditingTabBarItem] = []
    @State private var editMode = EditMode.inactive
    @State private var lastUpdateDate: Date

    init(manager: Binding<CustardManager>) {
        let tabBarData = (try? manager.wrappedValue.tabbar(identifier: 0)) ?? .default
        self._items = State(initialValue: tabBarData.items.indices.map { i in
            EditingTabBarItem(
                label: tabBarData.items[i].label,
                pinned: tabBarData.items[i].pinned,
                actions: tabBarData.items[i].actions
            )
        })
        self._lastUpdateDate = State(initialValue: tabBarData.lastUpdateDate ?? .now)
        self._manager = manager
    }

    private static let anchorId = "BOTTOM_ANCHOR"
    var body: some View {
        ScrollViewReader { proxy in
            Form {
                Text("タブバーを編集し、タブの並び替え、削除、追加を行ったり、文字の入力やカーソルの移動など様々な機能を追加することができます。")
                Section {
                    Button("アイテムを追加", systemImage: "plus") {
                        withAnimation(.interactiveSpring()) {
                            let item = EditingTabBarItem(
                                label: .text("アイテム"),
                                pinned: false,
                                actions: [.moveTab(.system(.user_japanese))]
                            )
                            self.items.append(item)
                            proxy.scrollTo(Self.anchorId, anchor: .bottom)
                        }
                    }
                }
                Section(header: Text("アイテム")) {
                    DisclosuringList($items) { $item in
                        let item = $item.wrappedValue
                        Toggle("このアイテムをピン留め", isOn: $item.pinned)
                        TabNavigationViewItemLabelTypePicker(item: $item)
                        HStack {
                            Spacer()
                            TabNavigationViewItemLabelEditView("ラベルを設定", label: $item.label)
                        }
                        NavigationLink {
                            CodableActionDataEditor($item.actions, availableCustards: manager.availableCustards)
                        } label: {
                            Label("アクション", systemImage: "terminal")
                            Text(makeLabelText(item: item))
                                .foregroundStyle(.gray)
                        }
                    } label: { $item in
                        let item = $item.wrappedValue
                        HStack {
                            if item.pinned {
                                Label("ピン留め済み", systemImage: "pin.circle.fill")
                                    .foregroundStyle(.blue)
                                    .labelStyle(.iconOnly)
                            }
                            label(labelType: item.label)
                                .contextMenu {
                                    Button("削除", systemImage: "trash", role: .destructive) {
                                        items.removeAll(where: {$0.id == item.id})
                                    }
                                }
                        }
                    }
                    .onDelete(perform: delete)
                    .onMove(perform: move)
                }
                Section(header: Text("便利なボタンを追加")) {
                    Button("片手モードをオン", systemImage: "aspectratio") {
                        withAnimation(.interactiveSpring()) {
                            self.items.append(EditingTabBarItem(label: .image("aspectratio"), pinned: false, actions: [.enableResizingMode]))
                        }
                    }
                    .id(Self.anchorId)  // ココに付けると自動スクロールが機能する
                    Button("絵文字タブを表示", systemImage: "face.smiling") {
                        withAnimation(.interactiveSpring()) {
                            self.items.append(EditingTabBarItem(label: .image("face.smiling"), pinned: false, actions: [.moveTab(.system(.emoji_tab))]))
                        }
                    }
                    Button("カーソルバーを表示", systemImage: "arrowtriangle.left.and.line.vertical.and.arrowtriangle.right") {
                        withAnimation(.interactiveSpring()) {
                            self.items.append(
                                EditingTabBarItem(
                                    label: .image("arrowtriangle.left.and.line.vertical.and.arrowtriangle.right"),
                                    pinned: false,
                                    actions: [.toggleCursorBar]
                                )
                            )
                        }
                    }
                    Button("キーボードを閉じる", systemImage: "keyboard.chevron.compact.down") {
                        withAnimation(.interactiveSpring()) {
                            self.items.append(EditingTabBarItem(label: .image("keyboard.chevron.compact.down"), pinned: false, actions: [.dismissKeyboard]))
                        }
                    }
                    Button("azooKeyを開く", systemImage: "gearshape") {
                        withAnimation(.interactiveSpring()) {
                            self.items.append(
                                EditingTabBarItem(
                                    label: .image("gearshape"),
                                    pinned: false,
                                    actions: [.launchApplication(.init(scheme: .azooKey, target: ""))]
                                )
                            )
                        }
                    }
                }
            }
            .onAppear {
                if let tabBarData = try? manager.tabbar(identifier: 0), tabBarData.lastUpdateDate != self.lastUpdateDate {
                    self.items = tabBarData.items.indices.map { i in
                        EditingTabBarItem(
                            label: tabBarData.items[i].label,
                            pinned: tabBarData.items[i].pinned,
                            actions: tabBarData.items[i].actions
                        )
                    }
                }
            }
            .onChange(of: items) { (_, newValue) in
                self.save(newValue)
            }
            .navigationBarTitle(Text("タブバーの編集"), displayMode: .inline)
            .navigationBarItems(trailing: editButton)
            .environment(\.editMode, $editMode)
        }
    }

    @ViewBuilder private func label(labelType: TabBarItemLabelType) -> some View {
        switch labelType {
        case let .text(text):
            Text(text)
        case let .image(image):
            Image(systemName: image)
        }
    }

    private func makeLabelText(item: EditingTabBarItem) -> LocalizedStringKey {
        if let label = item.actions.first?.label {
            if item.actions.count > 1 {
                return "\(label, color: .gray)など"
            } else {
                return "\(label, color: .gray)"
            }
        }
        return "動作なし"
    }

    private func save(_ items: [EditingTabBarItem]) {
        do {
            debug("EditingTabBarView.save")
            let newLastUpdateDate: Date = .now
            let tabBarData = TabBarData(identifier: 0, lastUpdateDate: newLastUpdateDate, items: items.map {
                TabBarItem(label: $0.label, pinned: $0.pinned, actions: $0.actions)
            })
            try manager.saveTabBarData(tabBarData: tabBarData)
            self.lastUpdateDate = newLastUpdateDate
        } catch {
            debug(error)
        }
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

    private func delete(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }

    private func move(source: IndexSet, destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
    }
}

private struct TabNavigationViewItemLabelTypePicker: View {
    @Binding private var item: EditingTabBarItem
    init(item: Binding<EditingTabBarItem>) {
        self._item = item
    }

    var body: some View {
        let labelType = Binding(
            get: {
                self.item.label.labelType
            },
            set: { (newValue: TabBarItemLabelType.LabelType) in
                switch (self.item.label, newValue) {
                case (.text, .text), (.image, .image):
                    break
                case (.image, .text):
                    self.item.label = .text("")
                case (.text, .image):
                    self.item.label = .image("circle.fill")
                }
            }
        )
        Picker("ラベルの種類", selection: labelType) {
            Label("ラベル", systemImage: "square.text.square.fill").tag(TabBarItemLabelType.LabelType.text)
            Label("アイコン", systemImage: "heart.text.square.fill").tag(TabBarItemLabelType.LabelType.image)
        }
        .pickerStyle(.menu)
        .labelStyle(.titleOnly)
    }
}

private struct TabNavigationViewItemLabelEditView: View {
    @Binding private var label: TabBarItemLabelType
    @State private var labelText = ""

    private let placeHolder: LocalizedStringKey

    init(_ placeHolder: LocalizedStringKey, label: Binding<TabBarItemLabelType>) {
        self.placeHolder = placeHolder
        self._label = label
        switch label.wrappedValue {
        case let .text(text):
            self._labelText = State(initialValue: text)
        case let .image(symbolName):
            self._labelText = State(initialValue: symbolName)
        }
    }

    var body: some View {
        switch self.label.labelType {
        case .text:
            TextField(placeHolder, text: $labelText)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.done)
                .onChange(of: labelText) { (_, value) in
                    label = .text(value)
                }
        case .image:
            SystemIconCompactPicker(icon: $labelText, recommendation: [
                "keyboard.chevron.compact.down",
                "keyboard.chevron.compact.down.fill",
                "face.smiling",
                "face.smiling.inverse",
                "arrow.up.forward.app",
                "arrowtriangle.left.and.line.vertical.and.arrowtriangle.right",
                "arrowtriangle.left.and.line.vertical.and.arrowtriangle.right.fill",
                "list.bullet",
                "aspectratio",
                "xmark",
                "textformat.abc",
                "abc",
                "textformat.123",
                "doc.badge.clock",
                "gearshape",
            ])
            .onChange(of: labelText) { (_, value) in
                label = .image(value)
            }
        }
    }
}
