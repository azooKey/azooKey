//
//  Focus.swift
//  MainApp
//
//  Created by ensan on 2020/12/12.
//  Copyright © 2020 ensan. All rights reserved.
//

import SwiftUI
private struct FocusViewModifier: ViewModifier {
    init(color: Color, focused: Bool) {
        self.color = color
        self.focused = focused
    }

    private let color: Color
    private let focused: Bool

    func body(content: Content) -> some View {
        let shadowColor = focused ? color : .clear
        let shadowRadius: CGFloat = focused ? 3.0 : .zero
        return content
            .shadow(color: shadowColor, radius: shadowRadius)
    }
}

extension View {
    func focus(_ color: Color = .accentColor, focused: Bool) -> some View {
        self.modifier(FocusViewModifier(color: color, focused: focused))
    }
}
