//
//  DraggableView.swift
//  MainApp
//
//  Created by ensan on 2021/04/15.
//  Copyright © 2021 ensan. All rights reserved.
//

import Foundation
import SwiftUI

struct DraggableView<Content: View, Collection: BidirectionalCollection & RandomAccessCollection & RangeReplaceableCollection>: View where Collection.Index == Int {
    private let contentConverter: (Collection.Element, Bool) -> Content
    private var width: CGFloat
    private var height: CGFloat
    private let padding: CGFloat

    @Binding private var items: Collection
    @Binding private var selectedIndex: Int
    @State private var targetIndex: Int = -1
    private let enabled: Bool

    init(items: Binding<Collection>, selection: Binding<Int>, enabled: Bool = true, width: CGFloat, height: CGFloat, padding: CGFloat = 5, @ViewBuilder content: @escaping (Collection.Element, Bool) -> Content) {
        self._items = items
        self._selectedIndex = selection
        self.width = width
        self.height = height
        self.padding = padding
        self.contentConverter = content
        self.enabled = enabled
    }

    private var separator: some View {
        Rectangle()
            .frame(width: 2, height: height * 0.9)
            .foregroundStyle(.accentColor)
    }

    var body: some View {
        VStack {
            HStack(spacing: 0) {
                ForEach(items.indices, id: \.self) {i in
                    if targetIndex == i {
                        separator
                            .focus(.accentColor, focused: true)
                    }
                    DraggableItem(selectedIndex: $selectedIndex, index: i, update: { self.update(index: $0, delta: $1) }, onEnd: onEnd, enabled: enabled) {
                        contentConverter(items[i], selectedIndex == i)
                    }
                    .frame(width: width, height: height)
                    .padding(padding)
                    .zIndex(selectedIndex == i ? 1 : 0)
                }
                if targetIndex == items.endIndex {
                    separator
                        .focus(.accentColor, focused: true)
                }
            }.scaledToFit()
        }
    }

    private func pointedIndex(index: Int, delta: CGFloat) -> Int {
        if delta.isZero {
            return index
        }

        if delta < 0 {
            // 負の場合
            let startIndex = items.startIndex
            var position = CGFloat.zero
            var index = index
            while index >= startIndex {
                position -= (width + padding * 2)
                if position < delta {
                    return index
                }
                index -= 1
            }
            return startIndex
        } else {
            // 正の場合
            let endIndex = items.endIndex
            var position = CGFloat.zero
            var index = index + 1
            while index < endIndex {
                position += (width + padding * 2)
                if delta < position {
                    return index
                }
                index += 1
            }
            return endIndex
        }

    }

    @MainActor
    private func update(index: Int, delta: CGFloat) {
        DispatchQueue.main.async {
            self.targetIndex = self.pointedIndex(index: index, delta: delta)
        }
    }

    private func onEnd() {
        if targetIndex != -1 {
            if selectedIndex > targetIndex {
                let item = items.remove(at: selectedIndex)
                items.insert(item, at: targetIndex)
                self.selectedIndex = targetIndex
            } else if selectedIndex < targetIndex {
                items.insert(items[selectedIndex], at: targetIndex)
                items.remove(at: selectedIndex)
                self.selectedIndex = targetIndex - 1
            }
        }
        self.targetIndex = -1
    }
}

private struct DraggableItem<Content: View>: View {
    private enum DragState {
        case inactive
        case dragging(translation: CGSize)

        var translation: CGSize {
            switch self {
            case .inactive:
                return .zero
            case .dragging(let translation):
                return translation
            }
        }

        var isActive: Bool {
            switch self {
            case .inactive:
                return false
            case .dragging:
                return true
            }
        }

        var isDragging: Bool {
            switch self {
            case .inactive:
                return false
            case .dragging:
                return true
            }
        }
    }

    @GestureState private var dragState = DragState.inactive
    @State private var viewState: CGSize = .zero
    @Binding private var selectedIndex: Int
    private let enabled: Bool
    private let index: Int

    private let onEnd: () -> Void
    private let update: (Int, CGFloat) -> Void

    private let content: () -> Content

    init(selectedIndex: Binding<Int>, index: Int, update: @escaping (Int, CGFloat) -> Void, onEnd: @escaping () -> Void, enabled: Bool, @ViewBuilder content: @escaping () -> Content) {
        self._selectedIndex = selectedIndex
        self.index = index
        self.update = update
        self.onEnd = onEnd
        self.content = content
        self.enabled = enabled
    }

    var body: some View {
        content()
            .offset(
                x: viewState.width + dragState.translation.width,
                y: viewState.height + dragState.translation.height
            )
            .onTapGesture {
                self.selectedIndex = index
            }
            .gesture(
                DragGesture()
                    .updating($dragState) {value, state, _ in
                        if enabled && self.selectedIndex == index {
                            self.update(index, value.translation.width)
                            state = .dragging(translation: value.translation)
                        }
                    }
                    .onEnded {_ in
                        if enabled {
                            self.onEnd()
                        }
                    }
            )
    }
}
