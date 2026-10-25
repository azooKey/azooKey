//
//  BottomSheetView.swift
//  MainApp
//
//  Created by ensan on 2021/02/22.
//  Copyright © 2021 ensan. All rights reserved.
//

import Foundation
import SwiftUI

/// 参考：https://swiftwithmajid.com/2019/12/11/building-bottom-sheet-in-swiftui/
struct BottomSheetView<Content: View>: View {
    @Binding private var isOpen: Bool

    private let maxHeight: CGFloat
    private let minHeight: CGFloat
    private let headerColor: Color
    private let content: () -> Content

    init(isOpen: Binding<Bool>, maxHeight: CGFloat, minHeight: CGFloat? = nil, headerColor: Color = .systemGray4, @ViewBuilder content: @escaping () -> Content) {
        if let minHeight {
            self.minHeight = minHeight
        } else {
            self.minHeight = maxHeight * 0.2
        }
        self.maxHeight = maxHeight
        self.headerColor = headerColor
        self.content = content
        self._isOpen = isOpen
    }

    private var offset: CGFloat {
        isOpen ? 0 : maxHeight - minHeight
    }

    @MainActor private var indicator: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.secondary)
            .frame(
                width: UIScreen.main.bounds.width * 0.6,
                height: 4
            )
    }
    @GestureState private var translation: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                self.indicator.padding()
                self.content()
            }
            .frame(width: geometry.size.width, height: self.maxHeight, alignment: .top)
            .background(headerColor)
            .cornerRadius(10)
            .frame(height: geometry.size.height, alignment: .bottom)
            .offset(y: max(self.offset + self.translation, 0))
            .animation(.interactiveSpring(), value: isOpen)
            .animation(.interactiveSpring(), value: translation)
            .gesture(
                DragGesture().updating(self.$translation) { value, state, _ in
                    state = value.translation.height
                }.onEnded { value in
                    let snapDistance = self.maxHeight * 0.3
                    guard abs(value.translation.height) > snapDistance else {
                        return
                    }
                    self.isOpen = value.translation.height < 0
                }
            )
        }
    }
}
