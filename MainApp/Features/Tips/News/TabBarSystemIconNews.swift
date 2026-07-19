import SwiftUI
import SwiftUIUtils

struct TabBarSystemIconNews: View {
    @EnvironmentObject private var appStates: MainAppStates

    var body: some View {
        TipsContentView("タブバーでアイコンを使う") {
            TipsContentParagraph {
                Text("タブバーでアイコンを使えるようになりました")
            }
            TipsContentParagraph {
                Text("また、よく使うアイテムは「ピン留め」できるようになりました")
            }
            CenterAlignedView {
                Image(.tabBar1)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: MainAppDesign.imageMaximumWidth)
            }
            .listRowSeparator(.hidden, edges: .bottom)
            NavigationLink("タブバーを編集") {
                EditingTabBarView(manager: $appStates.custardManager)
            }
            .foregroundStyle(.accentColor)
        }
    }
}
