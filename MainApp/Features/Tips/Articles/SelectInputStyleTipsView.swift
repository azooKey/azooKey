//
//  SelctInputStyle.swift
//  MainApp
//
//  Created by ensan on 2020/10/03.
//  Copyright © 2020 ensan. All rights reserved.
//

import Foundation
import SwiftUI

struct SelectInputStyleTipsView: View {
    var body: some View {
        TipsContentView("入力方法を選ぶ") {
            TipsContentParagraph {
                Text("日本語と英語それぞれで「ローマ字入力」または「フリック入力」を選ぶことが可能です。")
            }
            LanguageLayoutSettingView(.japaneseKeyboardLayout, language: .japanese).padding(.vertical)
            LanguageLayoutSettingView(.englishKeyboardLayout, language: .english).padding(.vertical)
            TipsContentParagraph {
                Text("macOSなどに搭載されている、入力中の文字列を自動的に変換する「ライブ変換」が利用できます。")
                BoolSettingView(.liveConversion)
            }
            TipsContentParagraph(style: .caption) {
                Text("日本語・英語に対応したカスタムタブを読み込んだ場合、これを選ぶことも可能です")
            }
            TipsContentParagraph(style: .caption) {
                Text("現在は携帯電話式の入力については対応していません。")
            }
        }
    }
}
