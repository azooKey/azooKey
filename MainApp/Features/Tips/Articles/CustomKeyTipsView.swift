//
//  CustomKeyTipsView.swift
//  MainApp
//
//  Created by ensan on 2020/11/21.
//  Copyright © 2020 ensan. All rights reserved.
//

import SwiftUI

struct CustomKeyTipsView: View {
    var body: some View {
        TipsContentView("キーをカスタマイズする") {
            TipsContentParagraph {
                Text("azooKeyでは一部キーのカスタマイズが可能です。「設定」タブから変更できます。")
            }
            TipsContentParagraph {
                Text("フリック入力では、ひらがなタブの「小ﾞﾟ」キーと「､｡?!」キーのフリックに最大3方向まで好きな文字を登録することができます。")
                ImageSlideshowView(pictures: [.flickCustomKeySetting0, .flickCustomKeySetting1, .flickCustomKeySetting2])
            }
            TipsContentParagraph {
                Text("ローマ字入力では、数字タブの一部キーに好きな文字と長押ししたときの候補を登録することができます。")
                ImageSlideshowView(pictures: [.qwertyCustomKeySetting0, .qwertyCustomKeySetting1, .qwertyCustomKeySetting2])
            }
        }
    }
}
