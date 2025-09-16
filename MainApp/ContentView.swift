//
//  ContentView.swift
//  MainApp
//
//  Created by ensan on 2020/09/03.
//  Copyright © 2020 ensan. All rights reserved.
//

import AzooKeyUtils
import KeyboardViews
import SwiftUI

@MainActor
struct ContentView: View {
    private enum TabSelection {
        case tips, theme, customize, settings
    }
    @EnvironmentObject private var appStates: MainAppStates
    @State private var selection: TabSelection = .tips
    @State private var messageManager = MessageManager()
    @State private var showWalkthrough = false
    @State private var importFileURL: URL?

    var body: some View {
        ZStack {
            TabView(selection: $selection) {
                TipsTabView()
                    .tabItem {
                        TabItem(title: "使い方", systemImage: "lightbulb.fill")
                    }
                    .tag(TabSelection.tips)
                ThemeTabView()
                    .tabItem {
                        TabItem(title: "着せ替え", systemImage: "photo")
                    }
                    .tag(TabSelection.theme)
                CustomizeTabView()
                    .tabItem {
                        TabItem(title: "拡張", systemImage: "gearshape.2.fill")
                    }
                    .tag(TabSelection.customize)
                SettingTabView()
                    .tabItem {
                        TabItem(title: "設定", systemImage: "wrench.fill")
                    }
                    .tag(TabSelection.settings)
            }
            .onAppear {
                if appStates.isKeyboardActivated && !appStates.tutorialFinishedSuccessfully() {
                    appStates.requireFirstOpenView = true
                }
            }
            .task {
                do {
                    try await HotfixDictionaryV1.updateIfRequired()
                } catch {
                    print(error)
                }
                UserDictionaryMigrationRunner.runIfNeeded()
            }
            .fullScreenCover(isPresented: $appStates.requireFirstOpenView, content: {
                // キーボードは有効化されているが正しく終了していない場合
                if appStates.isKeyboardActivated && !appStates.tutorialFinishedSuccessfully() {
                    // 「最初の設定」を再表示する
                    EnableAzooKeyView(resumeProgress: .setting)
                } else {
                    // 最初からやる
                    EnableAzooKeyView()
                }
            })
            .onChange(of: selection) { (_, value) in
                if value == .customize {
                    if appStates.internalSettingManager.walkthroughState.shouldDisplay(identifier: .extensions) {
                        self.showWalkthrough = true
                    }
                }
            }
            .onOpenURL { url in
                if url.scheme == "azooKey" {
                    // Deep link handling for azooKey scheme
                    let host = url.host?.lowercased()
                    let last = url.lastPathComponent.lowercased()
                    if host == "settings" && last == "zenzai" {
                        // Switch to Settings tab and request navigation to Zenzai settings
                        selection = .settings
                        appStates.deepLink = .settingsZenzai
                        return
                    }
                }
                // Non-azooKey scheme: treat as file import
                if url.scheme != "azooKey" {
                    importFileURL = url
                }
            }
            .sheet(isPresented: $showWalkthrough, content: {
                CustomizeTabWalkthroughView(isShowing: $showWalkthrough)
                    .background(Color.background)
            })
            ForEach(messageManager.necessaryMessages, id: \.id) {data in
                if messageManager.requireShow(data.id) {
                    switch data.id {
                    case .mock, .ver3_0_zenzai_introduction:
                        EmptyView()
                    case .ver2_1_emoji_tab:
                        DataUpdateView(id: data.id, manager: $messageManager) {
                            var manager = CustardManager.load()
                            guard var tabBarData = try? manager.tabbar(identifier: 0) else {
                                return
                            }
                            if tabBarData.items.contains(where: {$0.actions.contains(.moveTab(.system(.emoji_tab)))}) {
                                return
                            }
                            tabBarData.items.append(.init(label: .text("絵文字"), pinned: true, actions: [.moveTab(.system(.emoji_tab))]))
                            tabBarData.lastUpdateDate = .now
                            try? manager.saveTabBarData(tabBarData: tabBarData)
                        }
                    case .ver1_9_user_dictionary_update, .iOS16_4_new_emoji, .iOS17_4_new_emoji, .iOS18_4_new_emoji:
                        // 絵文字を更新する
                        DataUpdateView(id: data.id, manager: $messageManager) {
                            AdditionalDictManager().userDictUpdate()
                        }
                    }
                }
            }
            if importFileURL != nil {
                URLImportCustardView(manager: $appStates.custardManager, url: $importFileURL)
            }
        }
    }
}

private struct TabItem: View {
    init(title: LocalizedStringKey, systemImage: String) {
        self.title = title
        self.systemImage = systemImage
    }

    private let title: LocalizedStringKey
    private let systemImage: String

    var body: some View {
        VStack {
            Image(systemName: systemImage).font(.system(size: 20, weight: .light))
                .foregroundStyle(.systemGray2)
            Text(title)
        }
    }
}
