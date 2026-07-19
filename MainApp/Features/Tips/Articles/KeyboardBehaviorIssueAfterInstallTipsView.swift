//
//  KeyboardBehaviorIssueAfterInstallTipsView.swift
//  MainApp
//
//  Created by ensan on 2023/02/09.
//  Copyright © 2023 DevEn3. All rights reserved.
//

import SwiftUI

struct KeyboardBehaviorIssueAfterInstallTipsView: View {
    var body: some View {
        TipsContentView("インストール直後、特定のアプリでキーボードが開かない") {
            TipsContentParagraph {
                Text("azooKeyをインストールした直後、特定のアプリでキーボードが開かないことがあります。")
                Text("これはazooKeyの問題ではなく、OS側のデータの更新が遅れている可能性があります。")
                Text("一度端末を再起動していただくとデータが更新され、キーボードが使えるようになることがあります。")
            }

            TipsContentParagraph {
                Text("なお、アプリケーション側でカスタムキーボードの利用を禁止する設定がなされている場合もあります。再起動で治らない場合はそちらもご確認ください。")
            }

        }
    }
}
