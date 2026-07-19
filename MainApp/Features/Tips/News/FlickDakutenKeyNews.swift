import SwiftUI

struct FlickDakutenKeyNews: View {
    var body: some View {
        TipsContentView("日本語フリックのカスタムキーで「濁点化」をサポート") {
            TipsContentParagraph {
                Text("「小ﾞﾟ」キーのカスタマイズでAndroid風の「濁点化」ができるようになりました")
                Text("「カスタムキー」機能の一部として利用できます。")
            }
            CustomKeysSettingView()
        }
    }
}
