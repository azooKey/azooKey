//
//  SearchQueriedView.swift
//  azooKey
//
//  Created by miwa on 2024/04/07.
//  Copyright © 2024 DevEn3. All rights reserved.
//

import SwiftUI

private struct SearchQueryEnvironmentKey: EnvironmentKey {
    typealias Value = String?

    static let defaultValue: Value = nil
}

private extension EnvironmentValues {
    var searchQuery: String? {
        get {
            self[SearchQueryEnvironmentKey.self]
        }
        set {
            self[SearchQueryEnvironmentKey.self] = newValue
        }
    }
}

private struct SearchKeysPreferenceKey: PreferenceKey {
    typealias Value = Key
    static let defaultValue: Key = .uninitialized
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value.merge(to: nextValue())
    }
}

private enum Key: Sendable, Equatable {
    case uninitialized
    case always
    case prefixMatch(Set<String>)

    mutating func merge(to key: Self) {
        switch self {
        case .uninitialized:
            self = key
        case .always: break
        case .prefixMatch(let keys):
            self = switch key {
            case .uninitialized: self
            case .always: .always
            case .prefixMatch(let newKeys): .prefixMatch(keys.union(newKeys))
            }
        }
    }
}

private struct SearchQueriedItemView<T: View>: View {
    @Environment(\.searchQuery) private var searchQuery

    init(content: T, key: Key) {
        self.content = content
        self.key = key
    }

    private var content: T
    private var key: Key

    var body: some View {
        let isShown = switch self.key {
        case .uninitialized, .always: true
        case .prefixMatch(let keys):
            if let searchQuery {
                keys.contains(where: {$0.hasPrefix(searchQuery)})
            } else {
                true
            }
        }
        Group {
            if isShown {
                content
            }
        }
    }
}

private struct SearchQueryInheritedView<T: View>: View {
    init(content: T) {
        self.content = content
    }
    @State private var key: Key = .uninitialized
    @Environment(\.searchQuery) private var searchQuery

    var content: T
    var body: some View {
        let isShown = switch self.key {
        case .uninitialized, .always: true
        case .prefixMatch(let keys):
            if let searchQuery {
                keys.contains(where: {$0.hasPrefix(searchQuery)})
            } else {
                true
            }
        }
        Group {
            if isShown {
                content
                    .environment(\.searchQuery, self.key == .uninitialized ? nil : searchQuery)
            }
        }
        .onPreferenceChange(SearchKeysPreferenceKey.self) { anotherKey in
            Task { @MainActor in
                self.key.merge(to: anotherKey)
            }
        }
    }
}

extension View {
    func searchQuery(_ text: String?) -> some View {
        self.environment(\.searchQuery, text)
    }
}

extension View {
    @ViewBuilder func searchKeys(_ keys: String...) -> some View {
        let katakanaKey: Key = .prefixMatch(Set(keys.map {$0.toKatakana()}))
        SearchQueriedItemView(content: self, key: katakanaKey)
            .preference(key: SearchKeysPreferenceKey.self, value: katakanaKey)
    }
    func searchAlways() -> some View {
        SearchQueriedItemView(content: self, key: .always)
            .preference(key: SearchKeysPreferenceKey.self, value: .always)
    }
    func inheritSearchKeys() -> some View {
        SearchQueryInheritedView(content: self)
    }
}
