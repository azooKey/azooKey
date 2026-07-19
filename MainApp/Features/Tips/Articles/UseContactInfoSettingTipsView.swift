//
//  UseContactInfoSettingNews.swift
//  azooKey
//
//  Created by miwa on 2023/11/11.
//  Copyright © 2023 DevEn3. All rights reserved.
//

import SwiftUI
import class KeyboardViews.SemiStaticStates

struct UseContactInfoSettingTipsView: View {
    @EnvironmentObject private var appStates: MainAppStates

    var body: some View {
        TipsContentView("変換に連絡先データを利用") {
            TipsContentParagraph {
                Text("「連絡先」アプリのデータを使って、家族や友人、職場の人の名前を素早く入力することができます。")
            }
            BoolSettingView(.enableContactImport)

            TipsContentParagraph {
                if !SemiStaticStates.shared.hasFullAccess {
                    Text("この機能を利用するには、「フルアクセス」の許可が必要です。詳しくはこちらをお読みください")
                    NavigationLink("フルアクセスが必要な機能を使う") {
                        FullAccessTipsView()
                    }
                }
                Text("この機能を利用するには、連絡先データの利用の許可が必要です。機能を有効化しようとすると、許可を求める画面が表示されるので、「許可」を選んでください")
            }

        }
    }
}
