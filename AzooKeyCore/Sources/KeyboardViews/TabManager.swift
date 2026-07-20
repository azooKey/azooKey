//
//  TabManager.swift
//  azooKey
//
//  Created by ensan on 2021/02/20.
//  Copyright © 2021 ensan. All rights reserved.
//

import CustardKit
import Foundation
import enum KanaKanjiConverterModule.InputStyle
import enum KanaKanjiConverterModule.KeyboardLanguage
import SwiftUI

extension TabData {
    @MainActor
    func tab(config: any TabManagerConfiguration) -> KeyboardTab {
        switch self {
        case let .system(tab):
            if StandardKeyboardCatalog.standardTabs.contains(tab) {
                return .resolved(.standard(tab))
            }
            switch tab {
            case .user_japanese:
                return .userDependent(.japanese)
            case .user_english:
                return .userDependent(.english)
            case .last_tab:
                return .lastTab
            case .clipboard_history_tab:
                return .resolved(.clipboardHistory)
            case .emoji_tab:
                return .resolved(.emoji)
            case .flick_japanese,
                 .flick_english,
                 .flick_numbersymbols,
                 .qwerty_japanese,
                 .qwerty_english,
                 .qwerty_numbers,
                 .qwerty_symbols:
                preconditionFailure(
                    "Standard keyboard is missing from the catalog"
                )
            }
        case let .custom(identifier):
            if let custard = try? config.custardManager.custard(identifier: identifier) {
                return .resolved(.custard(custard))
            } else {
                return .resolved(.custard(.errorMessage))
            }
        }
    }
}

public struct TabManager {
    var config: any TabManagerConfiguration
    public var tab: ManagerTab {
        if let temporalTab {
            return temporalTab
        } else {
            return currentTab
        }
    }

    @MainActor init(config: any TabManagerConfiguration) {
        self.config = config
        self.currentTab = Self.getDefaultTab(config: config).managerTab
    }
    /// メインのタブ。
    private var currentTab: ManagerTab
    /// 一時的に表示を切り替えるタブ。lastTabに反映されない。
    private var temporalTab: ManagerTab?
    private var lastTab: ManagerTab?

    public enum ManagerTab {
        case resolved(ResolvedTab)
        case userDependent(KeyboardTab.UserDependentTab)
    }

    @MainActor static func resolvedTab(
        of tab: ManagerTab,
        config: any TabManagerConfiguration
    ) -> ResolvedTab {
        switch tab {
        case let .resolved(tab):
            return tab
        case let .userDependent(tab):
            return actualTab(of: tab, config: config)
        }
    }

    @MainActor public func resolvedTab() -> ResolvedTab {
        Self.resolvedTab(of: self.tab, config: config)
    }

    @MainActor static func actualTab(
        of tab: KeyboardTab.UserDependentTab,
        config: any TabManagerConfiguration
    ) -> ResolvedTab {
        // ユーザの設定に合わせて遷移先のタブ(非user_dependent)を返す
        let (layout, flick, qwerty):
            (LanguageLayout, TabData.SystemTab, TabData.SystemTab) = switch tab {
        case .english:
            (config.englishLayout, .flick_english, .qwerty_english)
        case .japanese:
            (config.japaneseLayout, .flick_japanese, .qwerty_japanese)
        }
        switch layout {
        case .flick:
            return .standard(flick)
        case .qwerty:
            return .standard(qwerty)
        case let .custard(identifier):
            return .custard(
                (try? config.custardManager.custard(identifier: identifier))
                    ?? .errorMessage
            )
        }
    }

    @MainActor func isCurrentTab(tab: KeyboardTab) -> Bool {
        switch tab {
        case let .resolved(actualTab):
            return Self.resolvedTab(of: self.tab, config: config) == actualTab
        case let .userDependent(type):
            return Self.actualTab(of: type, config: config) == Self.resolvedTab(of: self.tab, config: config)
        case .lastTab:
            return false
        }
    }

    @MainActor mutating func initialize(variableStates: VariableStates) {
        switch lastTab {
        case .none:
            self.moveTab(to: .userDependent(.japanese), variableStates: variableStates)
        case let .resolved(tab):
            self.moveTab(to: tab, variableStates: variableStates)
        case let .userDependent(tab):
            self.moveTab(to: .userDependent(tab), variableStates: variableStates)
        }
    }

    mutating func closeKeyboard() {
        self.lastTab = self.currentTab
    }

    @MainActor mutating private func moveTab(
        to destination: ResolvedTab,
        variableStates: VariableStates
    ) {
        // VariableStateの状態を遷移先のタブに合わせて適切に変更する
        variableStates.setInputStyle(destination.inputStyle)
        if let language = destination.language {
            variableStates.keyboardLanguage = language
        }

        // selfの状態を更新する
        self.temporalTab = nil
        self.lastTab = self.currentTab
        self.currentTab = .resolved(destination)
    }

    @MainActor private func updateVariableStates(_ variableStates: VariableStates, inputStyle: InputStyle, language: KeyboardLanguage?) {
        // VariableStateの状態を遷移先のタブに合わせて適切に変更する
        variableStates.setInputStyle(inputStyle)
        if let language {
            variableStates.keyboardLanguage = language
        }
        variableStates.updateResizingState()
    }

    @MainActor private static func getDefaultTab(
        config: any TabManagerConfiguration
    ) -> (resolvedTab: ResolvedTab, managerTab: ManagerTab) {
        (
            actualTab(
                of: KeyboardTab.UserDependentTab.japanese,
                config: config
            ),
            .userDependent(.japanese)
        )
    }

    @MainActor mutating func setTemporalTab(_ destination: KeyboardTab, variableStates: VariableStates) {
        let actualTab: ResolvedTab
        switch destination {
        case let .resolved(tab):
            self.updateVariableStates(variableStates, inputStyle: tab.inputStyle, language: tab.language)
            self.temporalTab = .resolved(tab)
        case let .userDependent(tab):
            actualTab = Self.actualTab(of: tab, config: config)
            self.updateVariableStates(variableStates, inputStyle: actualTab.inputStyle, language: actualTab.language)
            self.temporalTab = .userDependent(tab)
        case .lastTab:
            if let lastTab {
                actualTab = Self.resolvedTab(of: lastTab, config: config)
                self.temporalTab = lastTab
            } else {
                (actualTab, self.temporalTab) = Self.getDefaultTab(config: config)
            }
            self.updateVariableStates(variableStates, inputStyle: actualTab.inputStyle, language: actualTab.language)
        }
    }

    @MainActor mutating func moveTab(to destination: KeyboardTab, variableStates: VariableStates) {
        switch destination {
        case let .resolved(tab):
            self.updateVariableStates(variableStates, inputStyle: tab.inputStyle, language: tab.language)
            self.lastTab = self.currentTab
            self.currentTab = .resolved(tab)
        // Custard内の変数の初期化を実行
        //            if case let .custard(custard) = tab {
        //                for value in custard.logics.initial_values {
        //                    if case let .bool(bool) = value.value {
        //                        variableStates.boolStates.initializeState(value.name, with: bool)
        //                    }
        //                }
        //            }
        case let .userDependent(tab):
            let actualTab = Self.actualTab(of: tab, config: config)
            self.updateVariableStates(variableStates, inputStyle: actualTab.inputStyle, language: actualTab.language)
            self.lastTab = self.currentTab
            self.currentTab = .userDependent(tab)

        case .lastTab:
            // 適切なタブを取得する
            let actualTab: ResolvedTab
            if let lastTab,
               Self.resolvedTab(of: lastTab, config: config)
                   != Self.resolvedTab(of: currentTab, config: config) {
                actualTab = Self.resolvedTab(of: lastTab, config: config)
                self.currentTab = .resolved(actualTab)
            } else {
                (actualTab, self.currentTab) = Self.getDefaultTab(config: config)
            }
            self.updateVariableStates(variableStates, inputStyle: actualTab.inputStyle, language: actualTab.language)
            self.lastTab = nil
        }
        self.temporalTab = nil
    }
}

public protocol TabManagerConfiguration {
    @MainActor var japaneseLayout: LanguageLayout { get }
    @MainActor var englishLayout: LanguageLayout { get }
    var custardManager: any CustardManagerProtocol { get }
}
