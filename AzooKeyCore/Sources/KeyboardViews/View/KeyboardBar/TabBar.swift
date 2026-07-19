//
//  TabNavigationView.swift
//  azooKey
//
//  Created by ensan on 2021/02/21.
//  Copyright © 2021 ensan. All rights reserved.
//

import Foundation
import SwiftUI

struct TabBarView<Extension: ApplicationSpecificKeyboardViewExtension>: View {
    private let data: TabBarData
    @Environment(\.userActionManager) private var action
    @EnvironmentObject private var variableStates: VariableStates

    init(data: TabBarData) {
        self.data = data
    }

    private var pinnedItems: [TabBarItem] {
        self.data.items.filter {$0.pinned == true}
    }

    private var nonPinnedItems: [TabBarItem] {
        self.data.items.filter {$0.pinned != true}
    }

    private func itemView(_ item: TabBarItem) -> some View {
        Button {
            self.action.registerActions(item.actions.map {$0.actionType}, variableStates: variableStates)
        } label: {
            switch item.label {
            case let .text(text):
                Text(text)
            case let .image(image):
                Image(systemName: image)
            }
        }
        .buttonStyle(
            ResultButtonStyle<Extension>(
                height: Design.keyboardBarHeight(
                    interfaceHeight: variableStates.interfaceSize.height,
                    context: variableStates.layoutContext
                ) * 0.6
            )
        )
    }

    var body: some View {
        HStack {
            if !self.pinnedItems.isEmpty {
                ForEach(self.pinnedItems.indices, id: \.self) {i in
                    let item = self.pinnedItems[i]
                    self.itemView(item)
                }
                Divider()
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(self.nonPinnedItems.indices, id: \.self) {i in
                        let item = self.nonPinnedItems[i]
                        self.itemView(item)
                    }
                }
            }
        }
        .frame(
            height: Design.keyboardBarHeight(
                interfaceHeight: variableStates.interfaceSize.height,
                context: variableStates.layoutContext
            )
        )
    }
}
