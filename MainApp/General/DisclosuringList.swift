//
//  DisclosuringList.swift
//  DisclosuringList
//
//  Created by ensan on 2021/07/23.
//  Copyright © 2021 ensan. All rights reserved.
//

import SwiftUI
import SwiftUIUtils

struct DisclosuringList<Item: Sendable & Identifiable, Label: View, Content: View>: View {
    @Environment(\.editMode) var editMode
    @Binding private var items: [Item]
    private let label: (Binding<Item>) -> Label
    private let content: (Binding<Item>) -> Content
    private var delete: ((IndexSet) -> Void)?
    private var move: ((IndexSet, Int) -> Void)?
    private var disclosingCondition: (Item) -> Bool = { _ in true }

    init(_ items: Binding<[Item]>, @ViewBuilder content: @escaping (Binding<Item>) -> Content, @ViewBuilder label: @escaping (Binding<Item>) -> Label) {
        self._items = items
        self.label = label
        self.content = content
    }

    @ViewBuilder
    private func editableView(_ value: Binding<[Item]>.IdentifiableItem) -> some View {
        switch disclosingCondition(value.item) {
        case true:
            MiniDisclosureGroup {
                content(value.$item)
                    .listRowSeparator(.hidden, edges: .top)
            } label: {
                label(value.$item)
                    .listRowSeparator(.hidden, edges: .bottom)
            }
        case false:
            label(value.$item)
        }
    }

    var body: some View {
        if editMode?.wrappedValue == .inactive {
            ForEach($items.identifiableItems, content: editableView)
        } else {
            List {
                ForEach($items.identifiableItems) {value in
                    label(value.$item)
                }
                .onDelete(perform: delete)
                .onMove(perform: move)
            }
        }
    }

    func onDelete(perform action: ((IndexSet) -> Void)?) -> Self {
        var result = self
        result.delete = action
        return result
    }

    func onMove(perform action: ((IndexSet, Int) -> Void)?) -> Self {
        var result = self
        result.move = action
        return result
    }

    func disclosed(when condition: @escaping (Item) -> Bool) -> Self {
        var result = self
        result.disclosingCondition = condition
        return result
    }
}

private struct MiniDisclosureGroup<Label: View, Content: View>: View {
    private let label: () -> Label
    private let content: () -> Content
    @State private var hidden = true
    init(@ViewBuilder content: @escaping () -> Content, @ViewBuilder label: @escaping () -> Label) {
        self.label = label
        self.content = content
    }

    var body: some View {
        HStack {
            self.label()
            Spacer()
            Button {
                hidden.toggle()
            } label: {
                Image(systemName: hidden ? "chevron.right" : "chevron.down")
                    .font(.system(.caption).bold())
                    .foregroundStyle(.accentColor)
            }
        }
        if !hidden {
            self.content()
        }
    }

}
