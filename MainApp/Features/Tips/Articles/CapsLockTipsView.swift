//
//  CapslockTips.swift
//  MainApp
//
//  Created by ensan on 2020/12/11.
//  Copyright © 2020 ensan. All rights reserved.
//

import Foundation
import SwiftUI

struct CapsLockTipsView: View {
    var body: some View {
        TipsContentView("大文字に固定する") {
            TipsContentParagraph {
                Text("大文字のみ入力するモード(Caps Lock)を利用できます。")
            }
            TipsContentParagraph {
                Text("フリック入力では「a/A」キーを上にフリックします。")
                Text("ローマ字入力では「Aa」キーを長押しします。")
            }
            TipsContentParagraph {
                Text("どちらの入力方式でも\(systemImage: "capslock.fill")は大文字固定になっていることを意味します。")
                Text("解除するにはもう一度キーを押してください。")
            }
        }
    }
}
