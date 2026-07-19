//
//  EnableAzooKeyView.swift
//  MainApp
//
//  Created by ensan on 2020/11/18.
//  Copyright © 2020 ensan. All rights reserved.
//

import AzooKeyUtils
import SwiftUI
import SwiftUIUtils
import func SwiftUtils.debug

enum EnableAzooKeyViewProgress: String, Hashable, Codable, Sendable {
    case menu
    case append
    case setting
    case finish
}

@MainActor
struct EnableAzooKeyView: View {
    @EnvironmentObject private var appStates: MainAppStates
    @State private var step: EnableAzooKeyViewProgress = .menu {
        didSet {
            self.appStates.setTutorialProgress(step)
        }
    }
    @State private var text = ""
    @State private var showDoneMessage = false

    init(resumeProgress: EnableAzooKeyViewProgress? = nil) {
        if let resumeProgress {
            self._step = .init(initialValue: resumeProgress)
        }
    }

    var body: some View {
        ScrollView {
            ScrollViewReader {value in
                CenterAlignedView(padding: 30) {
                    switch self.step {
                    case .menu:
                        VStack(alignment: .leading, spacing: 20) {
                            Spacer()
                            CenterAlignedView {
                                HeaderLogoView()
                            }
                            EnableAzooKeyViewText("azooKeyを使う前に、iPhoneのキーボードのリストにazooKeyを追加する必要があります", with: "exclamationmark.triangle.fill")
                            CenterAlignedView {
                                EnableAzooKeyViewButton("手順を見る", systemName: "arrowtriangle.right.fill") {
                                    self.step = .append
                                }
                            }
                        }
                        .onAppear {
                            value.scrollTo(0, anchor: .top)
                        }
                    case .append:
                        VStack(alignment: .leading, spacing: 20) {

                            EnableAzooKeyViewHeader("追加する")
                            EnableAzooKeyViewText("下にスクロールして「追加する」を押して", with: "plus.circle")
                            EnableAzooKeyViewText("「キーボード」を押して", with: "keyboard")
                            CenterAlignedView {
                                EnableAzooKeyViewImage(.initSettingKeyboardImageHand)
                            }
                            EnableAzooKeyViewText("azooKeyをオンにして", with: "square.and.line.vertical.and.square.fill")
                            CenterAlignedView {
                                EnableAzooKeyViewImage(.initSettingAzooKeySwitchImageHand)
                            }
                            EnableAzooKeyViewText("このアプリを再び開いてください", with: "arrow.turn.down.left")
                            CenterAlignedView {
                                EnableAzooKeyViewButton("追加する", systemName: "plus.circle") {
                                    if let url = URL(string: UIApplication.openSettingsURLString) {
                                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                                    }
                                }
                            }
                            EnableAzooKeyViewText("この設定をしないとキーボードが使えません", with: "exclamationmark.triangle.fill")
                            CenterAlignedView {
                                EnableAzooKeyViewButton("閉じる", systemName: "xmark", style: .destructive) {
                                    appStates.requireFirstOpenView = false
                                }
                            }
                        }
                        .onAppear {
                            value.scrollTo(0, anchor: .top)
                        }
                    case .setting:
                        VStack(alignment: .leading, spacing: 20) {
                            EnableAzooKeyViewHeader("最初の設定")
                            Group {
                                Divider()
                                EnableAzooKeyViewText("キーボードの種類をお選びください", with: "keyboard")
                                LanguageLayoutSettingView(.japaneseKeyboardLayout, setTogether: true)
                            }
                            Group {
                                Divider()
                                EnableAzooKeyViewText("ライブ変換を使用しますか？", with: "character.cursor.ibeam")
                                BoolSettingView(.liveConversion)
                            }
                            Group {
                                Divider()
                                EnableAzooKeyViewText("Zenzai（高性能端末向けの高精度なニューラルかな漢字変換システム）を使用しますか？", with: "z.square.fill")
                                BoolSettingView(.zenzaiEnable)
                            }
                            Divider()
                            EnableAzooKeyViewText("設定は「設定タブ」でいつでも変えられます", with: "gearshape")
                            CenterAlignedView {
                                EnableAzooKeyViewButton("完了", systemName: "checkmark") {
                                    self.step = .finish
                                }
                            }
                        }
                        .onAppear {
                            value.scrollTo(0, anchor: .top)
                        }

                    case .finish:
                        VStack(alignment: .leading, spacing: 20) {
                            EnableAzooKeyViewHeader("azooKeyが使えます！")
                            EnableAzooKeyViewText("準備は完了です！", with: "checkmark")
                            if showDoneMessage {
                                EnableAzooKeyViewText("azooKeyが開かれました！", with: "checkmark")
                                CenterAlignedView {
                                    EnableAzooKeyViewButton("始める", systemName: "arrowshape.turn.up.right.fill") {
                                        appStates.requireFirstOpenView = false
                                    }
                                }
                            } else {
                                EnableAzooKeyViewText("キーボードの地球儀ボタンを長押しし、azooKeyを選択してください", with: "globe")
                            }
                            TextField("キーボードを開く", text: $text)
                                .textFieldStyle(.roundedBorder)
                                .submitLabel(.continue)
                                .onSubmit {
                                    appStates.requireFirstOpenView = false
                                }
                            if !showDoneMessage {
                                CenterAlignedView {
                                    EnableAzooKeyViewImage(.initSettingGlobeTap)
                                }
                            }
                            EnableAzooKeyViewText("azooKeyをお楽しみください！", with: "star.fill")
                            if !showDoneMessage {
                                CenterAlignedView {
                                    EnableAzooKeyViewButton("始める", systemName: "arrowshape.turn.up.right.fill") {
                                        appStates.requireFirstOpenView = false
                                    }
                                }
                            }
                        }
                        .onAppear {
                            value.scrollTo(0, anchor: .top)
                        }
                        .onTapGesture {
                            UIApplication.shared.closeKeyboard()
                        }
                        .onReceive(NotificationCenter.default.publisher(for: UIApplication.keyboardDidShowNotification)) {_ in
                            // キーボードが開いた時
                            if checkActiveKeyboardIsAzooKey() {
                                showDoneMessage = true
                            }
                        }
                        .onReceive(NotificationCenter.default.publisher(for: UITextInputMode.currentInputModeDidChangeNotification)) {_ in
                            // アクティブなキーボードが変化したとき
                            if checkActiveKeyboardIsAzooKey() {
                                showDoneMessage = true
                            }
                        }
                    }
                }
                .id(0)
            }
        }
        .animation(.interactiveSpring(), value: step)
        .animation(.spring(), value: showDoneMessage)
        .task {
            // 0.2秒に一度チェックを挟んでkeyboardの状態をチェックする
            while !Task.isCancelled && !appStates.isKeyboardActivated {
                if SharedStore.checkKeyboardActivation() {
                    self.step = .setting
                    appStates.isKeyboardActivated = true
                }
                do {
                    try await Task.sleep(nanoseconds: 0_200_000_000)
                } catch {
                    debug(error)
                }
            }
        }
    }

    private func checkActiveKeyboardIsAzooKey() -> Bool {
        // キーボードが開いた時
        // 参考：https://stackoverflow.com/questions/26153336/how-do-i-find-out-the-current-keyboard-used-on-ios8
        let currentKeyboardIdentifier = NSArray(array: UITextInputMode.activeInputModes)
            .filtered(using: NSPredicate(format: "isDisplayed = YES"))
            .first
            .flatMap {($0 as? UITextInputMode)?.value(forKey: "identifier") as? String}
        return currentKeyboardIdentifier?.hasPrefix(SharedStore.bundleName) == true
    }
}
