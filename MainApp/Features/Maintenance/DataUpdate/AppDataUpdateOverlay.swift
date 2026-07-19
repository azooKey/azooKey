import KeyboardViews
import SwiftUI

struct AppDataUpdateOverlay: View {
    @State private var messageManager = MessageManager()

    var body: some View {
        ForEach(messageManager.necessaryMessages, id: \.id) { data in
            if messageManager.requireShow(data.id) {
                switch data.id {
                case .mock, .ver3_0_zenzai_introduction:
                    EmptyView()
                case .ver2_1_emoji_tab:
                    DataUpdateView(id: data.id, manager: $messageManager) {
                        var manager = CustardManager.load()
                        guard var tabBarData = try? manager.tabbar(identifier: 0) else {
                            return
                        }
                        if tabBarData.items.contains(where: { $0.actions.contains(.moveTab(.system(.emoji_tab))) }) {
                            return
                        }
                        tabBarData.items.append(.init(
                            label: .text("絵文字"),
                            pinned: true,
                            actions: [.moveTab(.system(.emoji_tab))]
                        ))
                        tabBarData.lastUpdateDate = .now
                        try? manager.saveTabBarData(tabBarData: tabBarData)
                    }
                case .ver1_9_user_dictionary_update, .iOS17_4_new_emoji, .iOS18_4_new_emoji, .iOS26_4_new_emoji:
                    DataUpdateView(id: data.id, manager: $messageManager) {
                        AdditionalDictManager().userDictUpdate()
                    }
                }
            }
        }
    }
}
