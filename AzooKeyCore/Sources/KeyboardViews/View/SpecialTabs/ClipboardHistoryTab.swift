//
//  ClipboardHistoryTab.swift
//  azooKey
//
//  Created by ensan on 2023/02/26.
//  Copyright © 2023 ensan. All rights reserved.
//

import SwiftUI
import SwiftUIUtils
import SwiftUtils

private final class ClipboardHistory: ObservableObject {
    @Published private(set) var pinnedItems: [ClipboardHistoryItem] = []
    @Published private(set) var notPinnedItems: [ClipboardHistoryItem] = []

    func updatePinnedItems(manager: inout ClipboardHistoryManager, _ process: (inout [ClipboardHistoryItem]) -> Void) {
        var copied = self.pinnedItems
        process(&copied)
        manager.items = copied + self.notPinnedItems
    }

    func updateNotPinnedItems(manager: inout ClipboardHistoryManager, _ process: (inout [ClipboardHistoryItem]) -> Void) {
        var copied = self.notPinnedItems
        process(&copied)
        manager.items = self.pinnedItems + copied
    }

    func updateBothItems(manager: inout ClipboardHistoryManager, _ process: (inout [ClipboardHistoryItem], inout [ClipboardHistoryItem]) -> Void) {
        var pinnedItems = self.pinnedItems
        var notPinnedItems = self.notPinnedItems
        process(&pinnedItems, &notPinnedItems)
        manager.items = pinnedItems + notPinnedItems
    }

    func reload(manager: ClipboardHistoryManager) {
        let (pinned, notPinned) = partitionItems(manager.items)
        self.pinnedItems = pinned.sorted(by: >)
        self.notPinnedItems = notPinned.sorted(by: >)
        debug("reload", manager.items)
    }

    private func partitionItems(_ items: [ClipboardHistoryItem]) -> (pinned: [ClipboardHistoryItem], notPinned: [ClipboardHistoryItem]) {
        var pinnedItems: [ClipboardHistoryItem] = []
        var notPinnedItems: [ClipboardHistoryItem] = []

        for item in items {
            if item.pinnedDate != nil {
                pinnedItems.append(item)
            } else {
                notPinnedItems.append(item)
            }
        }

        return (pinnedItems, notPinnedItems)
    }
}

@MainActor
struct ClipboardHistoryTab<Extension: ApplicationSpecificKeyboardViewExtension>: View {
    @EnvironmentObject private var variableStates: VariableStates
    @StateObject private var target = ClipboardHistory()
    @Environment(Extension.Theme.self) private var theme
    @Environment(\.userActionManager) private var action


    init() {}
    private var listRowBackgroundColor: Color {
        // クリアテーマの場合は半透明の暗い背景を使用
        if case .dynamic(.clear, .normal) = theme.resultBackgroundColor {
            return Color.black.opacity(0.3)
        } else {
            return theme.prominentBackgroundColor
        }
    }

    @ViewBuilder
    private func tileView(_ item: ClipboardHistoryItem, index: Int?, pinned: Bool = false) -> some View {
        ClipboardTileView<Extension>(
            item: item,
            index: index,
            pinned: pinned,
            backgroundColor: listRowBackgroundColor,
            onTap: { handleTileInput(item) },
            onPin: { pinItem(item: item, at: $0) },
            onUnpin: { unpinItem(item: item, at: $0) },
            onDelete: { deleteItem(at: $0, pinned: pinned) }
        )
    }

    private func handleTileInput(_ item: ClipboardHistoryItem) {
        switch item.content {
        case .text(let string):
            action.registerAction(.input(string), variableStates: variableStates)
            variableStates.undoAction = .init(action: .replaceLastCharacters([string: ""]), textChangedCount: variableStates.textChangedCount)
            KeyboardFeedback<Extension>.click()
        }
    }

    private func deleteItem(at index: Int, pinned: Bool) {
        if pinned {
            self.target.updatePinnedItems(manager: &variableStates.clipboardHistoryManager) {
                $0.remove(at: index)
            }
        } else {
            self.target.updateNotPinnedItems(manager: &variableStates.clipboardHistoryManager) {
                $0.remove(at: index)
            }
        }
    }

    private var tileGridView: some View {
        ScrollView {
            VStack(spacing: 12) {
                if !self.target.pinnedItems.isEmpty {
                    ClipboardSection(
                        title: "ピン留め",
                        items: self.target.pinnedItems,
                        isPinned: true,
                        tileView: tileView
                    )
                }

                if self.target.notPinnedItems.isEmpty {
                    EmptyHistoryView()
                } else {
                    ClipboardSection(
                        title: "履歴",
                        items: self.target.notPinnedItems,
                        isPinned: false,
                        tileView: tileView
                    )
                }
            }
            .padding(.vertical, 12)
        }
    }

    private func enterKey(_ design: TabDependentDesign) -> some View {
        SimpleKeyView<Extension>(model: SimpleEnterKeyModel<Extension>(), tabDesign: design)
    }
    private func deleteKey(_ design: TabDependentDesign) -> some View {
        SimpleKeyView<Extension>(model: SimpleKeyModel<Extension>(keyLabelType: .image("delete.left"), unpressedKeyColorType: .special, pressActions: [.delete(1)], longPressActions: .init(repeat: [.delete(1)])), tabDesign: design)
    }
    private func backTabKey(_ design: TabDependentDesign) -> some View {
        SimpleKeyView<Extension>(model: SimpleKeyModel<Extension>(keyLabelType: .text("戻る"), unpressedKeyColorType: .special, pressActions: [.moveTab(.system(.last_tab))], longPressActions: .none), tabDesign: design)
    }

    var body: some View {
        Group {
            switch variableStates.keyboardOrientation {
            case .vertical:
                VStack {
                    tileGridView
                    HStack {
                        let design = TabDependentDesign(width: 3, height: 7, interfaceSize: variableStates.interfaceSize, orientation: .vertical)
                        backTabKey(design)
                        enterKey(design)
                        deleteKey(design)
                    }
                }
            case .horizontal:
                HStack {
                    tileGridView
                    VStack {
                        let design = TabDependentDesign(width: 8, height: 3, interfaceSize: variableStates.interfaceSize, orientation: .horizontal)
                        backTabKey(design)
                        deleteKey(design)
                        enterKey(design)
                    }
                }
            }
        }
        .font(Design.fonts.resultViewFont(theme: theme, userSizePrefrerence: Extension.SettingProvider.resultViewFontSize))
        .foregroundStyle(theme.resultTextColor.color)
        .onAppear {
            self.target.reload(manager: variableStates.clipboardHistoryManager)
        }
        .onChange(of: variableStates.clipboardHistoryManager.items) { _ in
            self.target.reload(manager: variableStates.clipboardHistoryManager)
        }
    }

    private func unpinItem(item: ClipboardHistoryItem, at index: Int) {
        self.target.updateBothItems(manager: &variableStates.clipboardHistoryManager) { (pinned, notPinned) in
            pinned.remove(at: index)
            var item = item
            item.pinnedDate = nil
            notPinned.append(item)
            notPinned.sort(by: >)
        }
    }
    private func pinItem(item: ClipboardHistoryItem, at index: Int) {
        self.target.updateBothItems(manager: &variableStates.clipboardHistoryManager) { (pinned, notPinned) in
            notPinned.remove(at: index)
            var item = item
            item.pinnedDate = .now
            pinned.append(item)
            pinned.sort(by: >)
        }
    }
}

private struct ClipboardTileView<Extension: ApplicationSpecificKeyboardViewExtension>: View {
    let item: ClipboardHistoryItem
    let index: Int?
    let pinned: Bool
    let backgroundColor: Color
    let onTap: () -> Void
    let onPin: (Int) -> Void
    let onUnpin: (Int) -> Void
    let onDelete: (Int) -> Void
    @Environment(Extension.Theme.self) private var theme

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .strokeAndFill(
                fillContent: backgroundColor,
                strokeContent: pinned ? Color.orange : Color.clear,
                lineWidth: pinned ? 2 : 0
            )
            .padding(2)
            .overlay {
                switch item.content {
                case .text(let string):
                    TextTileContent(string: string, textColor: theme.textColor.color)
                }
            }
            .frame(width: 140, height: 100)
        .onTapGesture {
            onTap()
        }
        .contextMenu {
            if pinned {
                Button {
                    guard let index else {
                        return
                    }
                    onUnpin(index)
                } label: {
                    Label("固定解除", systemImage: "pin.slash")
                }
            } else {
                Button {
                    guard let index else {
                        return
                    }
                    onPin(index)
                } label: {
                    Label("固定", systemImage: "pin")
                }
            }
            Button(role: .destructive) {
                guard let index else {
                    return
                }
                onDelete(index)
            } label: {
                Label("削除", systemImage: "trash")
            }
        }
    }
}


private struct TextTileContent: View {
    let string: String
    let textColor: Color

    var body: some View {
        Text(string)
            .font(.system(size: 12))
            .foregroundColor(textColor)
            .lineLimit(5)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(8)
            .frame(height: 100)
    }
}

private struct ClipboardSection<TileView: View>: View {
    let title: LocalizedStringKey
    let items: [ClipboardHistoryItem]
    let isPinned: Bool
    let tileView: (ClipboardHistoryItem, Int?, Bool) -> TileView

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 12)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(items.indices, id: \.self) { index in
                        let item = items[index]
                        tileView(item, index, isPinned)
                    }
                }
                .padding(.horizontal, 12)
            }
        }
    }
}

private struct EmptyHistoryView: View {
    var body: some View {
        VStack {
            Text("テキストをコピーするとここに追加されます")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(16)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
    }
}