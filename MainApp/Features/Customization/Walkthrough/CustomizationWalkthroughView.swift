import Foundation
import SwiftUI

private struct Item: Identifiable {
    let id = UUID()
    let image: String
    let headline: LocalizedStringKey
    let body: LocalizedStringKey
}

struct CustomizationWalkthroughView: View {
    @EnvironmentObject private var walkthrough: CustomizationWalkthroughState

    private let items: [Item] = [
        .init(
            image: "rectangle.and.pencil.and.ellipsis",
            headline: "カスタムタブ機能",
            body: "あなたがよく使う仕事の挨拶やゲームの定型文、お気に入りの顔文字など、好きなものを並べたカスタムタブを作ることができます。"
        ),
        .init(
            image: "list.bullet",
            headline: "タブバー",
            body: "作成したカスタムタブに移動するためにタブバーがあります。タブがいくつあっても簡単に移動できます。"
        ),
        .init(
            image: "square.and.arrow.down.on.square",
            headline: "カスタムタブの読み込み",
            body: "カスタムタブはファイルとして共有可能です。パソコンで作ったファイルや他の人の作ったファイルを読み込んで利用できます。"
        ),

    ]

    var body: some View {
        GeometryReader {geometry in
            ScrollView {
                VStack(spacing: 20) {
                    // アイコンの辺の長さ
                    let length = geometry.size.width / 4.8
                    Image(systemName: "gearshape.2.fill")
                        .font(.system(size: length / 2, weight: .bold, design: .default))
                        .background {
                            RoundedRectangle(cornerRadius: length * 0.17)
                                .fill(Color.systemGray5)
                                .frame(width: length, height: length)
                        }
                    Text("azooKeyを拡張する").font(.largeTitle.bold())
                        .padding()
                    let imagesFont: Font = Font.system(size: length / 2.4, weight: .light, design: .default)
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(items) {item in
                            HStack {
                                Image(systemName: item.image)
                                    .font(imagesFont)
                                    .frame(width: geometry.size.width / 7.0, height: geometry.size.width / 7.0)
                                    .foregroundStyle(.blue)
                                VStack(alignment: .leading) {
                                    Text(item.headline)
                                        .font(.subheadline.bold())
                                    Text(item.body)
                                        .foregroundStyle(.gray)
                                        .font(.subheadline)
                                }
                            }
                            .padding(.horizontal, 20)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    Button("始める") {
                        walkthrough.isPresented = false
                    }
                    .buttonStyle(LargeButtonStyle(backgroundColor: .blue))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.top, 30)
                }
                .background(Color.background)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
        }
    }
}
