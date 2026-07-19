//
//  OneHandedModeTips.swift
//  MainApp
//
//  Created by ensan on 2021/03/13.
//  Copyright © 2021 ensan. All rights reserved.
//

import Foundation
import SwiftUI

struct OneHandedModeTipsView: View {
    var body: some View {
        TipsContentView("片手モードを利用する") {
            TipsContentParagraph {
                Text("azooKeyでは片手モードを利用可能です。")
            }
            TipsContentParagraph {
                Text("まずタブバーを表示します。変換候補欄を長押しするか記号タブキーを長押しすると表示されます。")
                Text("「片手」をタップします。")
                TipsImage(.oneHandedMode1)
            }
            TipsContentParagraph {
                Text("サイズの調整モードがオンになります。左右の白い部分をドラッグし、好みのサイズに調整してください。")
                TipsImage(.oneHandedMode2)
            }
            TipsContentParagraph {
                Text("\(systemImage: "checkmark")をタップすると完了します。")
                Text("\(systemImage: "arrow.triangle.2.circlepath")をタップするとリセットされます。")
                TipsImage(.oneHandedMode3)
            }
            TipsContentParagraph {
                Text("\(systemImage: "checkmark")を押して完了したあとは通常のキーボードと同様に使えます。")
                Text("\(systemImage: "aspectratio")を押すと再度編集できます。")
                Text("\(systemImage: "arrow.up.backward.and.arrow.down.forward")を押すと通常の両手モードに戻ります。")
                TipsImage(.oneHandedMode4)
            }
        }
    }
}
