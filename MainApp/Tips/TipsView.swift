//
//  TipsVIew.swift
//  MainApp
//
//  Created by ensan on 2020/10/02.
//  Copyright © 2020 ensan. All rights reserved.
//

import KeyboardViews
import SwiftUI

struct TipsTabView: View {
    @EnvironmentObject private var appStates: MainAppStates
    var body: some View {
        NavigationStack {
            Form {
                Section("キーボードを使えるようにする") {
                    if !appStates.isKeyboardActivated {
                        Text("キーボードを有効化する")
                            .onTapGesture {
                                appStates.requireFirstOpenView = true
                            }
                    }
                    NavigationLink("入力方法を選ぶ", destination: SelctInputStyleTipsView())
                }
                TipsNewsSection()
                Section("便利な使い方") {
                    let imageColor = Color.blue
                    IconNavigationLink("片手モードを使う", systemImage: "aspectratio", imageColor: imageColor) {
                        OneHandedModeTipsView()
                    }
                    IconNavigationLink("カーソルを自由に移動する", systemImage: "arrowtriangle.left.and.line.vertical.and.arrowtriangle.right", imageColor: imageColor) {
                        CursorMoveTipsView()
                    }
                    IconNavigationLink("文頭まで一気に消す", systemImage: "xmark", imageColor: imageColor) {
                        SmoothDeleteTipsView()
                    }
                    IconNavigationLink("漢字を拡大表示する", systemImage: "plus.magnifyingglass", imageColor: imageColor) {
                        KanjiLargeTextTipsView()
                    }
                    IconNavigationLink("大文字に固定する", systemImage: "capslock.fill", imageColor: imageColor) {
                        CapsLockTipsView()
                    }
                    IconNavigationLink("タイムスタンプを使う", systemImage: "clock", imageColor: imageColor) {
                        DateLiteralSettingTipsView()
                    }
                    IconNavigationLink("キーをカスタマイズする", systemImage: "hammer", imageColor: imageColor) {
                        CustomKeyTipsView()
                    }
                    IconNavigationLink("フルアクセスが必要な機能を使う", systemImage: "lock.open", imageColor: imageColor) {
                        FullAccessTipsView()
                    }
                    IconNavigationLink("連絡先情報を変換に使う", systemImage: "person.text.rectangle", imageColor: imageColor) {
                        UseContactInfoSettingTipsView()
                    }
                    if SemiStaticStates.shared.hasFullAccess {
                        IconNavigationLink("「ほかのAppからペースト」について", systemImage: "doc.on.clipboard", imageColor: imageColor) {
                            PasteFromOtherAppsPermissionTipsView()
                        }
                    }
                }

                Section("困ったときは") {
                    NavigationLink("インストール直後、特定のアプリでキーボードが開かない") {
                        KeyboardBehaviorIssueAfterInstallTipsView()
                    }
                    NavigationLink("特定のアプリケーションで入力がおかしくなる") {
                        UseMarkedTextTipsView()
                    }
                    NavigationLink("カスタムアクションがうまく動かない") {
                        CustomActionWorksUnexpectedlyTipsView()
                    }
                    NavigationLink("絵文字や顔文字の変換候補を表示したい") {
                        EmojiKaomojiTipsView()
                    }
                    NavigationLink("バグの報告や機能のリクエストをしたい") {
                        ContactView()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HeaderLogoView()
                        .padding(.vertical, 4)
                }
            }
        }
    }
}
