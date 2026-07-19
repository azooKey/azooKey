//
//  EmojiKaomojiTipsView.swift
//  MainApp
//
//  Created by ensan on 2020/11/17.
//  Copyright © 2020 ensan. All rights reserved.
//

import SwiftUI
struct EmojiKaomojiTipsView: View {
    var body: some View {
        TipsContentView("絵文字や顔文字の変換候補を表示したい") {
            TipsContentParagraph {
                Text("絵文字と顔文字は別々にオン・オフを選択可能です。")
                Text("絵文字の一覧を表示したい場合、標準の絵文字キーボードをご利用ください。")
            }
            AdditionalDictManageViewMain()
        }
    }
}
