import AzooKeyUtils
import SwiftUI

struct ZenzaiSettingView: View {
    @State private var effort = SettingUpdater<ZenzaiEffortSettingKey>()
    @State private var zenzaiEnabled = SettingUpdater<EnableZenzai>()

    var body: some View {
        Form {
            BoolSettingView(.zenzaiEnable)
            Picker("エフォート", selection: $effort.value) {
                Text("低").tag(ZenzaiEffortSettingKey.Value.low)
                Text("中").tag(ZenzaiEffortSettingKey.Value.medium)
                Text("高").tag(ZenzaiEffortSettingKey.Value.high)
            }
            .disabled(!zenzaiEnabled.value)
            Section(header: Text("Zenzaiについて")) {
                Text("「Zenzai」はazooKeyの新しいかな漢字変換システムです。")
                Text("ニューラル言語モデルを用いることで、高精度な変換と文脈の理解を実現しました。")
            }

            Section(header: Text("Zenzaiの安全性について")) {
                Text("Zenzaiはインターネット接続を一切要さず、デバイスの中だけで使用できます。")
                Text("このため、フルアクセスは不要で、プライバシーは完全に守られます。")
            }

            Section(header: Text("「エフォート」について")) {
                Text("一部の端末では動作が重い場合があります。")
                Text("iPhone 15 Proより上位の端末では「中」「高」程度のエフォートでも快適に利用できます。")
                Text("それ以前の端末では、「低」などの設定を推奨します。")
            }

            Section(header: Text("Zenzaiの機能的制約について")) {
                Text("ユーザ辞書や学習については十分に動作しない場合があります。")
                Text("入力誤り訂正についても現在サポートしていません。")
            }
        }
        .onAppear {
            effort.reload()
            zenzaiEnabled.reload()
        }
    }
}
