//
//  TipsNewsSection.swift
//  azooKey
//
//  Created by miwa on 2023/11/11.
//  Copyright © 2023 DevEn3. All rights reserved.
//

import SwiftUI

struct TipsNewsSection: View {
    @AppStorage("read_terms_of_use_update_2025_05_31") private var readTermsOfUseUpdate_2025_05_31 = false
    @EnvironmentObject private var appStates: MainAppStates

    @MainActor
    private var needUseFlickCustomSettingNews: Bool {
        appStates.japaneseLayout != .qwerty || appStates.englishLayout != .qwerty
    }

    @MainActor
    private var needFlickDakutenKeyNews: Bool {
        appStates.japaneseLayout != .qwerty
    }

    var body: some View {
        if !readTermsOfUseUpdate_2025_05_31 {
            Section("利用規約の更新") {
                NavigationLink {
                    TermsOfServiceUpdateNews(readTermsOfUseUpdate_2025_05_31: $readTermsOfUseUpdate_2025_05_31)
                } label: {
                    Label(
                        title: {
                            Text("利用規約を更新しました")
                        },
                        icon: {
                            Image(systemName: "bell.badge")
                                .foregroundStyle(.red)
                                .font(.caption)
                        }
                    )
                }
            }
        }
        Section("新機能") {
            IconNavigationLink("「ニューラルかな漢字変換システム Zenzai」を導入しました", systemImage: "z.square.fill", style: AngularGradient(colors: [.red, .blue], center: .center)) {
                ZenzaiIntroductionNews()
            }
            if needFlickDakutenKeyNews {
                IconNavigationLink("日本語フリックのカスタムキーで「濁点化」をサポート", systemImage: "bolt", imageColor: .orange) {
                    FlickDakutenKeyNews()
                }
            }
            if needUseFlickCustomSettingNews {
                IconNavigationLink("フリック式のカスタムタブが簡単に作れるようになりました！", systemImage: "wrench.adjustable", imageColor: .orange) {
                    FlickCustardBaseSelectionNews()
                }
            }
            IconNavigationLink("タブバーにアイコンを使えるようになりました！", systemImage: "heart.rectangle", imageColor: .orange) {
                TabBarSystemIconNews()
            }
        }
    }
}
