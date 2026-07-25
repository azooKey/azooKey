//
//  ClipboardHistoryManager.swift
//  azooKey
//
//  Created by ensan on 2023/02/26.
//  Copyright © 2023 ensan. All rights reserved.
//

import Foundation
import SwiftUtils
import class UIKit.UIPasteboard

struct ClipboardHistoryItem: Equatable, Comparable, Hashable, Codable, Identifiable {
    var content: Content
    var createdData: Date
    var pinnedDate: Date?

    static func < (lhs: ClipboardHistoryItem, rhs: ClipboardHistoryItem) -> Bool {
        if let rPinnedDate = rhs.pinnedDate {
            if let lPinnedDate = lhs.pinnedDate {
                return lPinnedDate < rPinnedDate
            }
            return true
        }
        return lhs.createdData < rhs.createdData
    }

    var id: Int {
        self.createdData.hashValue
    }
    enum Content: Hashable, Codable {
        case text(String)
    }
}

public struct ClipboardHistoryManager {

    var items: [ClipboardHistoryItem] = []
    var config: any ClipboardHistoryManagerConfiguration
    private var collapsed = false
    private var previousChangedCount = 0

    @MainActor private var enabled: Bool {
        config.enabled
    }

    init(config: any ClipboardHistoryManagerConfiguration) {
        self.config = config
        // TODO: メモリ対策をやる必要がある。
        do {
            self.items = try Self.load(config: config)
            self.collapsed = false
        } catch {
            debug("ClipboardHistoryManager.init: load failed", error)
            self.items = []
            self.collapsed = true
        }
        self.sort()
    }

    public mutating func reload() {
        do {
            let newItems = try Self.load(config: config)
            self.items = newItems
            self.collapsed = false
        } catch {
            debug("ClipboardHistoryManager.reload: load failed", error)
            self.collapsed = true
        }
    }

    @MainActor func save() {
        // 読み込みに失敗している場合は上書きを行わない
        guard !self.collapsed else {
            return
        }
        // 有効化されていなければ上書きしない
        guard self.enabled else {
            return
        }
        do {
            try Self.save(self.items, config: config)
        } catch {
            debug("ClipboardHistoryManager.init: save failed", error)
        }
    }

    private mutating func sort() {
        self.items.sort(by: >)
    }

    @MainActor public mutating func checkUpdate() {
        guard self.enabled else {
            return
        }
        if UIPasteboard.general.changeCount == self.previousChangedCount {
            return
        }
        if !UIPasteboard.general.hasStrings {
            return
        }
        self.previousChangedCount = UIPasteboard.general.changeCount

        if let string = UIPasteboard.general.string {
            var item = ClipboardHistoryItem(content: .text(string), createdData: Date())
            if let index = self.items.firstIndex(where: {item.content == $0.content}) {
                let oldItem = self.items.remove(at: index)
                if oldItem.pinnedDate != nil {
                    item.pinnedDate = Date()
                }
            }
            if self.items.isEmpty {
                self.items.append(item)
            } else if let index = self.items.firstIndex(where: { item > $0 }) {
                self.items.insert(item, at: index)
            } else {
                self.items.append(item)
            }
        }
        // 増えすぎないように削除する
        while self.items.count > config.maxCount {
            self.items.removeLast()
        }
    }

    private static func historyFileURL(config: any ClipboardHistoryManagerConfiguration) -> URL? {
        config.saveDirectory?.appendingPathComponent("clipboard_history.json", isDirectory: false)
    }

    static func load(config: any ClipboardHistoryManagerConfiguration) throws -> [ClipboardHistoryItem] {
        guard let historyFileURL = historyFileURL(config: config) else {
            throw IOError.sharedDirectoryInaccessible
        }
        let encoded: Data
        do {
            encoded = try Data(contentsOf: historyFileURL)
        } catch let error as NSError {
            // "No such file or directory"
            if error.code != 260 {
                throw error
            }
            return []
        }
        let items = try JSONDecoder().decode([ClipboardHistoryItem].self, from: encoded)
        return items
    }

    enum IOError: Error {
        /// フルアクセスが存在しない
        case lackFullAccess
        /// 共有ディレクトリにアクセスできない
        case sharedDirectoryInaccessible
    }

    @MainActor static func save(_ items: [ClipboardHistoryItem], config: any ClipboardHistoryManagerConfiguration) throws {
        // jsonファイルとして共有空間に保存する
        // FullAccessがない場合は不可能なので`fail`にする
        guard SemiStaticStates.shared.hasFullAccess else {
            throw IOError.lackFullAccess
        }
        guard let historyFileURL = historyFileURL(config: config) else {
            throw IOError.sharedDirectoryInaccessible
        }
        let encoder = JSONEncoder()
        let encoded = try encoder.encode(items)

        try encoded.write(to: historyFileURL)
    }
}

#if DEBUG
extension ClipboardHistoryItem.Content: CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
        case .text(let string): return string
        }
    }
}
#endif

public protocol ClipboardHistoryManagerConfiguration {
    @MainActor var enabled: Bool { get }
    var saveDirectory: URL? { get }
    var maxCount: Int { get }
}
