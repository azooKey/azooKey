import SwiftUI

struct AppTabView: View {
    @EnvironmentObject private var router: AppRouter

    var body: some View {
        TabView(selection: $router.selectedTab) {
            TipsHomeView()
                .tabItem {
                    Label("使い方", systemImage: "lightbulb.fill")
                }
                .tag(AppRouter.Tab.tips)
            ThemeHomeView()
                .tabItem {
                    Label("着せ替え", systemImage: "photo")
                }
                .tag(AppRouter.Tab.theme)
            CustomizationHomeView()
                .tabItem {
                    Label("拡張", systemImage: "gearshape.2.fill")
                }
                .tag(AppRouter.Tab.customization)
            SettingsHomeView()
                .tabItem {
                    Label("設定", systemImage: "wrench.fill")
                }
                .tag(AppRouter.Tab.settings)
        }
    }
}
