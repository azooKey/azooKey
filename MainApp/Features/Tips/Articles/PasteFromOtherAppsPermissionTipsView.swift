//
//  PasteFromOtherAppsPermissionTipsView.swift
//  azooKey
//
//  Created by ensan on 2023/04/01.
//  Copyright © 2023 ensan. All rights reserved.
//

import SwiftUI

struct PasteFromOtherAppsPermissionTipsView: View {
    var body: some View {
        TipsContentView("「ほかのAppからペースト」について") {
            TipsContentParagraph {
                Text("「クリップボードの履歴」や「ペーストボタン」の機能を利用している際、頻繁に「ペーストの許可」を求めるダイアログが出ることがあります。")
                TipsImage(.pasteRequestDialogue)
                Text("azooKeyはクリップボードの履歴を保存するため、定期的にクリップボードをチェックします。また、ペーストする際にもクリップボードの情報を利用します。")
            }
            TipsContentParagraph {
                Text("設定アプリで「ほかのAppからペースト」を「許可」にすることで、ダイアログが出なくなります。")
            }
            TipsContentParagraph {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    Button("設定アプリを開く") {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                }
            }
            TipsContentParagraph {
                TipsImage(.pasteFromOtherAppsSetting)
            }
            TipsContentParagraph {
                Text("なお、「クリップボードの履歴」を有効にしていない場合、クリップボードの中身を定期的に取得することはありません。また、取得したクリップボードのテキストはアプリ内でのみ利用されます。")
            }
        }
    }
}
