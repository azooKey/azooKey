//
//  KanjiLargeText.swift
//  MainApp
//
//  Created by ensan on 2020/10/19.
//  Copyright © 2020 ensan. All rights reserved.
//

import Foundation
import SwiftUI

struct KanjiLargeTextTipsView: View {
    var body: some View {
        TipsContentView("文字を拡大表示する") {
            TipsContentParagraph {
                Text("azooKeyではキーボード上で文字を拡大して表示することができます。")
            }

            TipsContentParagraph {
                Text("文字を拡大するには、まず拡大したい文字を入力した上で変換候補を長押しします。")
                TipsImage(.largeTextTips1)
            }

            TipsContentParagraph {
                Text("長押し後表示される画面で「大きな文字で表示する」をタップします。")
                TipsImage(.largeTextTips2)
            }

            TipsContentParagraph {
                Text("最大限大きなサイズで文字が表示されます。右にスクロールすると途切れている文字を確認することができます。")
                TipsImage(.largeTextTips3)
            }

            TipsContentParagraph(style: .caption) {
                Text("フォントはiOSで標準的に利用される「ヒラギノ明朝」を用いています。明朝体の字形は手書きする際の規範的な字形と必ずしも一致しません。ご了承ください。")
            }
        }
    }
}
