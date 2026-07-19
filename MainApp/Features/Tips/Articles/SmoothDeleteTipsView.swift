//
//  SmoothDeleteTipsView.swift
//  MainApp
//
//  Created by ensan on 2020/11/03.
//  Copyright © 2020 ensan. All rights reserved.
//

import Foundation
import SwiftUI

struct SmoothDeleteTipsView: View {
    var body: some View {
        TipsContentView("文頭まで削除する") {
            TipsContentParagraph {
                Text("フリックのキーボードでは削除\(systemImage: "delete.left")キーを左にフリックすると、文頭まで削除することができます。")
                TipsImage(.smoothDelete)
            }
            TipsContentParagraph {
                Text("誤って削除してしまった場合は端末を振るか、入力欄を三本指でスワイプすることで取り消し操作を行うことが可能です。")
            }
        }
    }
}
