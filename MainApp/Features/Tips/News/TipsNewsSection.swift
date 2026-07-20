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
    @AppStorage("read_article_iOS17_service_termination") private var readArticle_iOS17_service_termination = false
    @EnvironmentObject private var keyboardConfiguration: KeyboardConfigurationState

    @MainActor
    private var needUseFlickCustomSettingNews: Bool {
        keyboardConfiguration.japaneseLayout != .qwerty || keyboardConfiguration.englishLayout != .qwerty
    }

    @MainActor
    private var needFlickDakutenKeyNews: Bool {
        keyboardConfiguration.japaneseLayout != .qwerty
    }

    private var iOS17TerminationNewsLabel: some View {
        Label(
            title: {
                Text("iOS 17のサポートを終了します")
            },
            icon: {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.red)
                    .font(.caption)
            }
        )
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
        if #unavailable(iOS 18) {
            Section("お知らせ") {
                NavigationLink {
                    IOS17TerminationNews(readThisMessage: $readArticle_iOS17_service_termination)
                } label: {
                    if readArticle_iOS17_service_termination {
                        iOS17TerminationNewsLabel
                            .labelStyle(.titleOnly)
                    } else {
                        iOS17TerminationNewsLabel
                    }
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
