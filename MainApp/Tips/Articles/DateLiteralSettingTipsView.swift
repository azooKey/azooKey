import Foundation
import SwiftUI

struct DateLiteralSettingTipsView: View {
    var body: some View {
        TipsContentView("タイムスタンプを設定する") {
            TipsContentParagraph {
                Text("ユーザ辞書の編集画面で「時刻・ランダム変換」を使うと、現在の日時やランダム値を自動生成できます。")
                Text("ここでは「1234/01/23 01:23」という形式のタイムスタンプを作ってみます。")
            }
            TipsContentParagraph {
                Text("手順")
                Text("1. 設定 → ユーザ辞書 → azooKeyユーザ辞書 を開く")
                Text("2. 右上の「追加する」を押す")
                Text("3. 編集画面で「時刻・ランダム変換」をオンにする")
                Text("4. 「時刻」を選び、プリセット（yyyy/MM/dd, HH:mm など）かカスタム書式を入力する")
                Text("単語欄にプレビューが表示され、現在時刻での結果を確認できます。")
            }
            TipsContentParagraph {
                Text("書式の例")
                Text("・yyyy/MM/dd HH:mm → 1234/01/23 01:23")
                Text("・'year='yyyy → year=1234（固定文字は'で囲みます）")
                Text("・EEE a HH:mm → 木 午前 01:23")
            }
            TipsContentParagraph(style: .caption) {
                Text("ヒント: 「M」を1文字にすると先頭ゼロなし（1月→1）になります。「HH」は24時間表記、「ss」は秒、「EEE」は曜日、「a」は午前/午後を表します。")
            }
            TipsContentParagraph {
                Text("ランダム値を使う場合は「ランダム」を選んで、整数/小数/文字列から選び範囲や内容を設定します。")
            }
            NavigationLink("azooKeyユーザ辞書") {
                AzooKeyUserDictionaryView()
            }
        }
    }
}
