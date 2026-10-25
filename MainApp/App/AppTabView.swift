import SwiftUI

struct AppTabView: View {
    @EnvironmentObject private var router: AppRouter

    var body: some View {
        TabView(selection: $router.selectedTab) {
            TipsHomeView()
                .tabItem {
                    AppTabItem(title: "使い方", systemImage: "lightbulb.fill")
                }
                .tag(AppRouter.Tab.tips)
            ThemeHomeView()
                .tabItem {
                    AppTabItem(title: "着せ替え", systemImage: "photo")
                }
                .tag(AppRouter.Tab.theme)
            CustomizationHomeView()
                .tabItem {
                    AppTabItem(title: "拡張", systemImage: "gearshape.2.fill")
                }
                .tag(AppRouter.Tab.customization)
            SettingsHomeView()
                .tabItem {
                    AppTabItem(title: "設定", systemImage: "wrench.fill")
                }
                .tag(AppRouter.Tab.settings)
        }
    }
}

private struct AppTabItem: View {
    let title: LocalizedStringKey
    let systemImage: String

    var body: some View {
        VStack {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .light))
                .foregroundStyle(.systemGray2)
            Text(title)
        }
    }
}
