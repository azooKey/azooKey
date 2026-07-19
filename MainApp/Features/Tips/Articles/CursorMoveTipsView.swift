//
//  CursorMoveTips.swift
//  MainApp
//
//  Created by ensan on 2020/10/19.
//  Copyright © 2020 ensan. All rights reserved.
//

import Foundation
import SwiftUI

struct CursorMoveTipsView: View {
    var body: some View {
        TipsContentView("カーソルを移動する") {
            TipsContentParagraph {
                Text("「空白」を長押しすると、カーソルバーが現れます。ホームボタンのない端末のフリック入力では左下の\(systemImage: "arrowtriangle.left.and.line.vertical.and.arrowtriangle.right")を押して表示することも可能です。")
                TipsImage(.moveCursor)
            }

            TipsContentParagraph {
                Text("\("黄色枠部分", color: .orange) \(systemImage: "circle.fill")に指を置いて左右になぞることでカーソルが滑らかに移動します。")
                Text("1文字ずつ移動したい場合は\("青枠部分", color: .blue)の\(systemImage: "chevron.left.2")部分または\(systemImage: "chevron.right.2")部分をタップすることでそれぞれの方向に1文字ずつ移動します。")
                Text("カーソルバーを消すには、入力/削除を行うか、再び空白を長押ししてください。")
            }
        }
    }
}
