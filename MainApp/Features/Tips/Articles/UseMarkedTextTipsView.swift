//
//  UseMarkedTextTipsView.swift
//  MainApp
//
//  Created by ensan on 2023/02/09.
//  Copyright © 2023 ensan. All rights reserved.
//

import SwiftUI

struct UseMarkedTextTipsView: View {
    var body: some View {
        TipsContentView("特定のアプリケーションで入力がおかしくなる") {
            TipsContentParagraph {
                Text("azooKeyとアプリの相性の問題で、入力がうまくいかないケースがあります。")
                Text("「入力中のテキストを保護」の設定をオンにすることで解決する場合があります。")
            }
            MarkedTextSettingView(.markedTextSetting)
        }
    }
}
