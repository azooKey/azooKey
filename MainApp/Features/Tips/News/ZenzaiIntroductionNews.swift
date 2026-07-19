import SwiftUI

struct ZenzaiIntroductionNews: View {
    var body: some View {
        TipsContentView("Zenzaiについて") {
            TipsContentParagraph {
                Text("「ニューラルかな漢字変換システム Zenzai」がiOSでも使えるようになりました。")
                Text("macOS版azooKeyで好評な高精度な変換システム「Zenzai」がついにiOS版でも利用できます")
                Text("「Zenzaiを有効化」をONにしてお試しください")
            }
            NavigationLink("Zenzaiを設定") {
                ZenzaiSettingView()
            }
            .foregroundStyle(.accentColor)
            TipsContentParagraph {
                Text("Zenzaiはインターネット接続を一切要さず、デバイスの中だけで使用できます。")
                Text("このため、フルアクセスは不要で、プライバシーは完全に守られます。")
            }
            TipsContentParagraph {
                Text("一部の端末では動作が重い場合があります。「エフォート」を「低」にすると改善する場合があります。")
                Text("ユーザ辞書や学習については十分に動作しない場合があります。")
                Text("入力誤り訂正についても現在サポートしていません。")
            }
        }
    }
}
