import SwiftUI

struct TermsOfServiceUpdateNews: View {
    @Binding var readTermsOfUseUpdate_2025_05_31: Bool

    var body: some View {
        TipsContentView("利用規約を更新しました") {
            TipsContentParagraph {
                Text("必ずご確認ください。")
            }
            FallbackLink("利用規約", destination: URL(string: "https://azookey.netlify.app/TermsOfService")!)
        }
        .onAppear {
            self.readTermsOfUseUpdate_2025_05_31 = true
        }
    }
}
