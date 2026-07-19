//
//  App.swift
//  App
//
//  Created by ensan on 2021/08/22.
//  Copyright © 2021 ensan. All rights reserved.
//

import AzooKeyUtils
import KeyboardViews
import SwiftUI

final class MainAppStates: ObservableObject {
    enum DeepLinkDestination: Equatable {
        case settingsZenzai
    }
    /// キーボードが有効化（キーボードリストに追加）されているかどうかを示す
    @Published var isKeyboardActivated: Bool
    @Published var requireFirstOpenView: Bool
    @Published var japaneseLayout: LanguageLayout = .flick
    @Published var englishLayout: LanguageLayout = .flick
    @Published var custardManager: CustardManager
    @Published var internalSettingManager = ContainerInternalSetting()
    @Published var requestReviewManager = RequestReviewManager()
    @Published var deepLink: DeepLinkDestination?

    @MainActor init() {
        let keyboardActivation = SharedStore.checkKeyboardActivation()
        self.isKeyboardActivated = keyboardActivation
        self.requireFirstOpenView = !keyboardActivation
        @KeyboardSetting(.japaneseKeyboardLayout) var japaneseKeyboardLayout
        self.japaneseLayout = japaneseKeyboardLayout
        @KeyboardSetting(.englishKeyboardLayout) var englishKeyboardLayout
        self.englishLayout = englishKeyboardLayout
        self.custardManager = CustardManager.load()
        SemiStaticStates.shared.setHapticsAvailable()
        SemiStaticStates.shared.setScreenWidth(UIScreen.main.bounds.width)
    }

    func setTutorialProgress(_ progress: EnableAzooKeyViewProgress) {
        UserDefaults.standard.set(progress.rawValue, forKey: "tutorial_progress")
    }
    private func resumeTutorialProgress() -> EnableAzooKeyViewProgress? {
        if let progressString = UserDefaults.standard.string(forKey: "tutorial_progress") {
            return EnableAzooKeyViewProgress(rawValue: progressString)
        } else {
            return nil
        }
    }
    func tutorialFinishedSuccessfully() -> Bool {
        if let progress = resumeTutorialProgress() {
            // finishで終わっていない場合、適切ではない
            return progress == .finish
        } else {
            return true
        }
    }
}

@main
struct MainApp: App {
    @StateObject private var appStates = MainAppStates()
    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(appStates)
                .onAppear {
                    // MARK: セットアップ
                    SemiStaticStates.shared.setup()
                    SharedStore.setInitialAppVersion()
                    SharedStore.setLastAppVersion()
                    // 本体アプリで特定の作業を行わなずにDoneにできる場合。
                    var messageManager = MessageManager()
                    messageManager.getMessagesContainerAppShouldMakeWhichDone().forEach {
                        messageManager.done($0.id)
                    }
                    // 設定を上書きする
                    if let initialVersion = SharedStore.initialAppVersion, initialVersion > .azooKey_v2_2_2 {
                        // Version 2.2.3以降にインストールしたユーザにはこのオプションを有効化しない
                        KeepDeprecatedShiftKeyBehavior.value = false
                    }
                }
        }
    }
}
