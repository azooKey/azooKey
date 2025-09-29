//
//  CustomKeySettingFlickKeyView.swift
//  MainApp
//
//  Created by ensan on 2021/04/23.
//  Copyright © 2021 ensan. All rights reserved.
//

import Foundation
import KeyboardViews
import SwiftUI

struct CustomKeySettingFlickKeyView<Label: View>: View {
    private let position: FlickKeyPosition
    @Binding private var selectedPosition: FlickKeyPosition
    private let label: () -> Label

    init(_ position: FlickKeyPosition, label: String, selectedPosition: Binding<FlickKeyPosition>) where Label == Text {
        self.position = position
        self.label = { Text(verbatim: label) }
        self._selectedPosition = selectedPosition
    }

    init(_ position: FlickKeyPosition, selectedPosition: Binding<FlickKeyPosition>, @ViewBuilder label: @escaping () -> Label) {
        self.position = position
        self.label = label
        self._selectedPosition = selectedPosition
    }

    private var focused: Bool {
        selectedPosition == position
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .stroke(focused ? .accentColor : .primary)
            .background {
                RoundedRectangle(cornerRadius: 10).fill(Color.background)
            }
            .compositingGroup()
            .focus(.accentColor, focused: focused)
            .overlay {
                label()
            }
            .onTapGesture {
                self.selectedPosition = position
            }
    }
}
