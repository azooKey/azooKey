import SwiftUI

struct IOS17TerminationNews: View {
    @Binding var readThisMessage: Bool

    var body: some View {
        TipsContentView("iOS 17のサポートを終了します") {
            TipsContentParagraph {
                Text("バージョン3.2以降のazooKeyではiOS 17のサポートを終了する予定です。")
            }
            TipsContentParagraph {
                Text("iOS 18を最新の状態にアップデートすることで、引き続き最新バージョンのazooKeyをご利用いただけます。")
            }
            TipsContentParagraph {
                Text("ぜひiOSをアップデートしてazooKeyをご利用ください。")
            }
        }
        .onAppear {
            readThisMessage = true
        }
    }
}
