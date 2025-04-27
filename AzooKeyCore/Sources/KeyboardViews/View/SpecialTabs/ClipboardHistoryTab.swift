//
//  ClipboardHistoryTab.swift
//  azooKey
//
//  Created by ensan on 2023/02/26.
//  Copyright © 2023 ensan. All rights reserved.
//

@preconcurrency import LinkPresentation
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
        self.pinnedItems = []
        self.notPinnedItems = []
        for item in manager.items {
            if item.pinnedDate != nil {
                self.pinnedItems.append(item)
            } else {
                self.notPinnedItems.append(item)
            }
        }
        self.pinnedItems.sort(by: >)
        self.notPinnedItems.sort(by: >)
        debug("reload", manager.items)
    }
}

@MainActor
struct ClipboardHistoryTab<Extension: ApplicationSpecificKeyboardViewExtension>: View {
    @EnvironmentObject private var variableStates: VariableStates
    @StateObject private var target = ClipboardHistory()
    @Environment(Extension.Theme.self) private var theme
    @Environment(\.userActionManager) private var action

    @State private var cacheStore = MetadataCacheStore()

    init() {}
    private var listRowBackgroundColor: Color {
        theme.prominentBackgroundColor
    }

    @ViewBuilder
    private func listItemView(_ item: ClipboardHistoryItem, index: Int?, pinned: Bool = false) -> some View {
        Group {
            switch item.content {
            case .text(let string):
                HStack {
                    if string.hasPrefix("https://") || string.hasPrefix("http://"), let url = URL(string: string) {
                        RichLinkView(url: url, options: [.icon], cacheStore: $cacheStore)
                            .padding(.vertical, 2)
                    } else {
                        if pinned {
                            HStack {
                                Image(systemName: "pin.circle.fill")
                                    .foregroundStyle(.orange)
                                Text(string)
                                    .lineLimit(2)
                            }
                        } else {
                            Text(string)
                                .lineLimit(2)
                        }
                    }
                    Spacer()
                    Button("入力") {
                        action.registerAction(.input(string), variableStates: variableStates)
                        variableStates.undoAction = .init(action: .replaceLastCharacters([string: ""]), textChangedCount: variableStates.textChangedCount)
                        KeyboardFeedback<Extension>.click()
                    }
                    .buttonStyle(.bordered)
                }
                .contextMenu {
                    Group {
                        Button {
                            action.registerAction(.input(string), variableStates: variableStates)
                            variableStates.undoAction = .init(action: .replaceLastCharacters([string: ""]), textChangedCount: variableStates.textChangedCount)
                        } label: {
                            Label("入力する", systemImage: "text.badge.plus")
                        }
                        Button {
                            UIPasteboard.general.string = string
                        } label: {
                            Label("コピーする", systemImage: "doc.on.doc")
                        }
                        if pinned {
                            Button {
                                guard let index else { return }
                                self.unpinItem(item: item, at: index)
                            } label: {
                                Label("固定を解除", systemImage: "pin.slash")
                            }
                        } else {
                            Button {
                                guard let index else { return }
                                self.pinItem(item: item, at: index)
                            } label: {
                                Label("ピンで固定する", systemImage: "pin")
                            }
                        }
                        Button(role: .destructive) {
                            guard let index else { return }
                            if pinned {
                                self.target.updatePinnedItems(manager: &variableStates.clipboardHistoryManager) {
                                    $0.remove(at: index)
                                }
                            } else {
                                self.target.updateNotPinnedItems(manager: &variableStates.clipboardHistoryManager) {
                                    $0.remove(at: index)
                                }
                            }
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                    }
                }

            }
        }
        .listRowBackground(
            Rectangle()
                .foregroundStyle(listRowBackgroundColor)
        )
        .listRowInsets(EdgeInsets())
        .padding(.leading, 7)
        .padding(.trailing, 2)
    }

    private var listView: some View {
        List {
            if !self.target.pinnedItems.isEmpty {
                Section {
                    ForEach(self.target.pinnedItems.indices, id: \.self) { index in
                        let item = self.target.pinnedItems[index]
                        listItemView(item, index: index, pinned: true)
                            .swipeActions(edge: .leading) {
                                Button {
                                    self.unpinItem(item: item, at: index)
                                } label: {
                                    Label("固定を解除", systemImage: "pin.slash.fill")
                                        .labelStyle(.iconOnly)
                                }
                                .tint(.orange)
                            }
                    }
                    .onDelete { indices in
                        self.target.updatePinnedItems(manager: &variableStates.clipboardHistoryManager) {
                            $0.remove(atOffsets: indices)
                        }
                    }
                }
            }
            if self.target.notPinnedItems.isEmpty {
                listItemView(.init(content: .text("テキストをコピーするとここに追加されます"), createdData: .now), index: nil)
            } else {
                Section {
                    ForEach(self.target.notPinnedItems.indices, id: \.self) { index in
                        let item = self.target.notPinnedItems[index]
                        listItemView(item, index: index)
                            .swipeActions(edge: .leading) {
                                Button {
                                    self.pinItem(item: item, at: index)
                                } label: {
                                    Label("ピンで固定する", systemImage: "pin.fill")
                                        .labelStyle(.iconOnly)
                                }
                                .tint(.orange)
                            }
                    }
                    .onDelete { indices in
                        self.target.updateNotPinnedItems(manager: &variableStates.clipboardHistoryManager) {
                            $0.remove(atOffsets: indices)
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
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
                    listView
                    HStack {
                        let design = TabDependentDesign(width: 3, height: 7, interfaceSize: variableStates.interfaceSize, orientation: .vertical)
                        backTabKey(design)
                        enterKey(design)
                        deleteKey(design)
                    }
                }
            case .horizontal:
                HStack {
                    listView
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

private struct MetadataCacheStore: Copyable {
    private var cache: [String: LPLinkMetadata] = [:]
    mutating func cache(metadata: LPLinkMetadata) {
        cache[metadata.url!.absoluteString] = metadata
    }
    func get(urlString: String) -> LPLinkMetadata? {
        cache[urlString]
    }
}

private struct RichLinkView: UIViewRepresentable {
    init(url: URL, options: [RichLinkView.MetadataOption] = [], cacheStore: Binding<MetadataCacheStore>) {
        self.url = url
        self.options = options
        self._cacheStore = cacheStore
    }

    class UIViewType: LPLinkView {
        override var intrinsicContentSize: CGSize { CGSize(width: 0, height: super.intrinsicContentSize.height) }
    }

    enum MetadataOption: Int8, Equatable {
        case icon, image, video
    }

    var url: URL
    var options: [MetadataOption] = []
    @Binding var cacheStore: MetadataCacheStore

    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIViewType {
        if let cachedData = self.cacheStore.get(urlString: url.absoluteString) {
            return UIViewType(metadata: cachedData)
        }
        return UIViewType(url: url)
    }

    func updateUIView(_ uiView: UIViewType, context: UIViewRepresentableContext<Self>) {
        if let cachedData = self.cacheStore.get(urlString: url.absoluteString) {
            uiView.metadata = cachedData
            uiView.sizeToFit()
        } else {
            Task {
                let metadata = try await LPMetadataProvider().startFetchingMetadata(for: url)
                if !options.contains(.video) {
                    metadata.videoProvider = nil
                    metadata.remoteVideoURL = nil
                }
                if !options.contains(.image) {
                    metadata.imageProvider = nil
                }
                if !options.contains(.icon) {
                    metadata.iconProvider = nil
                }
                self.cacheStore.cache(metadata: metadata)
                // このわずかな遅延を入れると処理が安定する
                try await Task.sleep(nanoseconds: 1_000)
                uiView.metadata = metadata
                uiView.sizeToFit()
            }
        }
    }
}

extension LPLinkMetadata: @unchecked @retroactive Sendable {}
