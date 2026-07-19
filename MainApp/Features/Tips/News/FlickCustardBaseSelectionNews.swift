import SwiftUI

struct FlickCustardBaseSelectionNews: View {
    @EnvironmentObject private var appStates: MainAppStates

    var body: some View {
        TipsContentView("フリック式のカスタムタブを作るのが簡単になりました！") {
            TipsContentParagraph {
                Text("フリック式のカスタムタブを作る際、「ベース」タブを選べるようになりました")
                Text("普段使っている日本語タブもベースにできるので、自由に日本語タブをカスタマイズできます")
            }
            ImageSlideshowView(pictures: [.custard1, .custard2, .custard3])
                .listRowSeparator(.hidden, edges: .bottom)
            Text("好きな文字や文章を並べたオリジナルのタブを作成することができます。")
            NavigationLink("フリック式のカスタムタブを作る") {
                EditingGridFitCustardView(manager: $appStates.custardManager, path: nil)
            }
            .foregroundStyle(.accentColor)
        }
    }
}
