//
//  CustardManager.swift
//  azooKey
//
//  Created by ensan on 2021/02/21.
//  Copyright © 2021 ensan. All rights reserved.
//

import CryptoKit
import CustardKit
import Foundation
import enum KanaKanjiConverterModule.KeyboardLanguage
import KeyboardViews
import SwiftUtils

public struct CustardInternalMetaData: Codable {
    public init(origin: CustardInternalMetaData.Origin) {
        self.origin = origin
    }

    public var origin: Origin
    public var shareLink: String?

    public enum Origin: String, Codable {
        case userMade
        case imported
    }
}

public struct CustardManagerIndex: Codable {
    public var availableCustards: [String] = []
    public var availableTabBars: [Int] = []
    public var metadata: [String: CustardInternalMetaData] = [:]

    enum CodingKeys: CodingKey {
        case availableCustards
        case availableTabBars
        case metadata
    }

    public init(availableCustards: [String] = [], availableTabBars: [Int] = [], metadata: [String: CustardInternalMetaData] = [:]) {
        self.availableCustards = availableCustards
        self.availableTabBars = availableTabBars
        self.metadata = metadata
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(availableCustards, forKey: .availableCustards)
        try container.encode(availableTabBars, forKey: .availableTabBars)
        try container.encode(metadata, forKey: .metadata)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.availableCustards = try container.decode([String].self, forKey: .availableCustards)
        self.availableTabBars = try container.decode([Int].self, forKey: .availableTabBars)
        self.metadata = try container.decode([String: CustardInternalMetaData].self, forKey: .metadata)
    }
}

public enum CustardManagerError: Error {
    case duplicateIdentifier
}

public struct CustardManager: CustardManagerProtocol {
    public struct EditorState: Sendable, Hashable, Codable {
        public var copiedKey: UserMadeKeyData?
    }

    public var editorState = EditorState()
    private static let directoryName = "custard/"
    private var index = CustardManagerIndex()

    private static func fileName(_ identifier: String) -> String {
        let hash = SHA256.hash(data: identifier.data(using: .utf8) ?? Data())
        let value16 = hash.map {String($0, radix: 16, uppercase: true)}.joined()
        return value16
    }

    private static func fileURL(name: String) -> URL {
        let directoryPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: SharedStore.appGroupKey)!
        let url = directoryPath.appendingPathComponent(directoryName + name)
        return url
    }

    private static func directoryExistCheck() {
        guard let directoryPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: SharedStore.appGroupKey) else {
            debug("container is unavailable")
            return
        }
        let filePath = directoryPath.appendingPathComponent(directoryName).path
        if !FileManager.default.fileExists(atPath: filePath) {
            do {
                debug("ファイルを新規作成")
                try FileManager.default.createDirectory(atPath: filePath, withIntermediateDirectories: true)
            } catch {
                debug(error)
            }
        }
    }

    public static func load() -> Self {
        directoryExistCheck()
        let themeIndexURL = fileURL(name: "index.json")
        do {
            let data = try Data(contentsOf: themeIndexURL)
            let index = try JSONDecoder().decode(CustardManagerIndex.self, from: data)
            return self.init(index: index)
        } catch {
            debug(error)
            return self.init(index: CustardManagerIndex())
        }
    }

    public func save() {
        let indexURL = Self.fileURL(name: "index.json")
        do {
            let data = try JSONEncoder().encode(self.index)
            try data.write(to: indexURL, options: .atomicWrite)
        } catch {
            debug(error)
        }
    }

    public func userMadeCustardData(identifier: String) throws -> UserMadeCustard {
        let fileName = Self.fileName(identifier)
        let fileURL = Self.fileURL(name: "\(fileName)_edit.json")
        let data = try Data(contentsOf: fileURL)
        var userMadeCustard = try JSONDecoder().decode(UserMadeCustard.self, from: data)
        if case .tenkey(var value) = userMadeCustard,
           let custard = try? self.custard(identifier: identifier) {
            value.keyStyle = .init(custard.interface.keyStyle)
            userMadeCustard = .tenkey(value)
        }
        return userMadeCustard
    }

    public func custard(identifier: String) throws -> Custard {
        let fileName = Self.fileName(identifier)
        let fileURL = Self.fileURL(name: "\(fileName)_main.custard")
        let data = try Data(contentsOf: fileURL)
        let custard = try JSONDecoder().decode(Custard.self, from: data)
        return custard
    }

    public func custardFileIfExist(identifier: String) throws -> URL {
        let fileName = Self.fileName(identifier)
        let fileURL = Self.fileURL(name: "\(fileName)_main.custard")
        _ = try Data(contentsOf: fileURL)
        return fileURL
    }

    public func tabbar(identifier: Int) throws -> TabBarData {
        let fileURL = Self.fileURL(name: "tabbar_\(identifier).tabbar")
        let data = try Data(contentsOf: fileURL)
        let custard = try JSONDecoder().decode(TabBarData.self, from: data)
        return custard
    }

    public func checkTabExistInTabBar(identifier: Int = 0, tab: TabData) -> Bool {
        guard let tabbar = try? self.tabbar(identifier: identifier) else {
            return false
        }
        return tabbar.items.contains(where: {$0.actions == [.moveTab(tab)]})
    }

    public mutating func addTabBar(identifier: Int = 0, item: TabBarItem) throws {
        let tabbar: TabBarData
        if let loaded = try? self.tabbar(identifier: identifier) {
            tabbar = loaded
        } else {
            tabbar = .default
        }
        var newTabBar = tabbar
        newTabBar.items.append(item)
        try self.saveTabBarData(tabBarData: newTabBar)
    }

    public mutating func saveCustard(custard: Custard, metadata: CustardInternalMetaData, userData: UserMadeCustard? = nil, updateTabBar: Bool = false) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(custard)
        let fileName = Self.fileName(custard.identifier)
        let fileURL = Self.fileURL(name: "\(fileName)_main.custard")
        try data.write(to: fileURL)
        if let userData {
            let fileURL = Self.fileURL(name: "\(fileName)_edit.json")
            let data = try encoder.encode(userData)
            try data.write(to: fileURL)
        }

        if !self.index.availableCustards.contains(custard.identifier) {
            self.index.availableCustards.append(custard.identifier)
        }

        if updateTabBar && !self.checkTabExistInTabBar(tab: .custom(custard.identifier)) {
            try self.addTabBar(item: .init(label: .text(custard.metadata.display_name), pinned: false, actions: [.moveTab(.custom(custard.identifier))]))
        }

        self.index.metadata[custard.identifier] = metadata
        self.save()
    }

    public func loadCustardShareLink(custardId: String) -> String? {
        self.index.metadata[custardId]?.shareLink
    }

    public mutating func saveCustardShareLink(custardId: String, shareLink: String) {
        self.index.metadata[custardId]?.shareLink = shareLink
        self.save()
    }

    public mutating func saveTabBarData(tabBarData: TabBarData) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(tabBarData)
        let fileURL = Self.fileURL(name: "tabbar_\(tabBarData.identifier).tabbar")
        try data.write(to: fileURL)
        if !self.index.availableTabBars.contains(tabBarData.identifier) {
            self.index.availableTabBars.append(tabBarData.identifier)
        }
        self.save()
    }

    public mutating func removeCustard(identifier: String) {
        do {
            let fileName = Self.fileName(identifier)
            self.index.availableCustards.removeAll {$0 == identifier}
            self.index.metadata.removeValue(forKey: identifier)
            let fileURL = Self.fileURL(name: "\(fileName)_main.custard")
            try FileManager.default.removeItem(atPath: fileURL.path)
            let editFileURL = Self.fileURL(name: "\(fileName)_edit.json")
            try? FileManager.default.removeItem(atPath: editFileURL.path)
            self.save()
        } catch {
            debug(error)
        }
    }

    public mutating func duplicateCustard(identifier: String) throws {
        var newIdentifier = "\(identifier)_copy"
        var count = 1
        while true {
            if !self.availableCustards.contains(newIdentifier) {
                break
            }
            newIdentifier = "\(identifier)_copy_#\(count)"
            count += 1
        }

        var metadata = self.index.metadata[identifier] ?? .init(origin: .userMade)
        metadata.shareLink = nil

        var custard = try self.custard(identifier: identifier)
        custard.identifier = newIdentifier
        custard.metadata.display_name = newIdentifier

        try self.saveCustard(custard: custard, metadata: metadata)
    }

    public mutating func renameCustard(from oldIdentifier: String, to newIdentifier: String) throws {
        guard oldIdentifier != newIdentifier else {
            return
        }
        if self.index.availableCustards.contains(newIdentifier) {
            throw CustardManagerError.duplicateIdentifier
        }
        var metadata = self.index.metadata[oldIdentifier] ?? .init(origin: .userMade)
        metadata.shareLink = nil
        var custard = try self.custard(identifier: oldIdentifier)
        custard.identifier = newIdentifier
        custard.metadata.display_name = newIdentifier
        var userData = try? self.userMadeCustardData(identifier: oldIdentifier)
        if var data = userData {
            data.rename(to: newIdentifier)
            userData = data
        }
        try self.saveCustard(custard: custard, metadata: metadata, userData: userData, updateTabBar: false)
        self.index.availableCustards.removeAll {$0 == oldIdentifier}
        self.index.metadata.removeValue(forKey: oldIdentifier)
        let fileName = Self.fileName(oldIdentifier)
        let fileURL = Self.fileURL(name: "\(fileName)_main.custard")
        try? FileManager.default.removeItem(atPath: fileURL.path)
        let editFileURL = Self.fileURL(name: "\(fileName)_edit.json")
        try? FileManager.default.removeItem(atPath: editFileURL.path)

        for tabBarIdentifier in self.availableTabBars {
            do {
                var tabbar = try self.tabbar(identifier: tabBarIdentifier)
                var changed = false
                tabbar.items = tabbar.items.map { item in
                    var itemChanged = false
                    var label = item.label
                    if case let .text(text) = label, text == oldIdentifier {
                        label = .text(newIdentifier)
                        itemChanged = true
                    }
                    let newActions = item.actions.map { action -> CodableActionData in
                        if case .moveTab(.custom(let value)) = action, value == oldIdentifier {
                            itemChanged = true
                            return .moveTab(.custom(newIdentifier))
                        }
                        return action
                    }
                    if itemChanged {
                        changed = true
                        return TabBarItem(label: label, pinned: item.pinned, actions: newActions)
                    } else {
                        return item
                    }
                }
                if changed {
                    try self.saveTabBarData(tabBarData: tabbar)
                }
            } catch {
                debug(error)
            }
        }
        self.save()
    }

    public mutating func removeTabBar(identifier: Int) {
        do {
            let fileURL = Self.fileURL(name: "tabbar_\(identifier).tabbar")
            try FileManager.default.removeItem(atPath: fileURL.path)
            self.index.availableTabBars = self.index.availableTabBars.filter {$0 != identifier}
            self.save()
        } catch {
            debug(error)
        }
    }

    public func availableCustard(for language: KeyboardLanguage) -> [String] {
        switch language {
        case .ja_JP:
            return self.availableCustards.compactMap {
                do {
                    let custard = try self.custard(identifier: $0)
                    if custard.language == .ja_JP {
                        return custard.identifier
                    }
                } catch {
                    debug(error)
                }
                return nil
            }
        case .el_GR:
            return self.availableCustards.compactMap {
                do {
                    let custard = try self.custard(identifier: $0)
                    if custard.language == .el_GR {
                        return custard.identifier
                    }
                } catch {
                    debug(error)
                }
                return nil
            }
        case .en_US:
            return self.availableCustards.compactMap {
                do {
                    let custard = try self.custard(identifier: $0)
                    if custard.language == .en_US {
                        return custard.identifier
                    }
                } catch {
                    debug(error)
                }
                return nil
            }
        case .none:
            return []
        }
    }

    public var availableCustards: [String] {
        index.availableCustards
    }

    public var availableTabBars: [Int] {
        index.availableTabBars
    }

    public var metadata: [String: CustardInternalMetaData] {
        index.metadata
    }

}
