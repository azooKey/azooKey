//
//  SystemIconPicker.swift
//  azooKey
//
//  Created by miwa on 2024/10/07.
//  Copyright © 2024 DevEn3. All rights reserved.
//

import SwiftUI

struct SystemIconCompactPicker: View {
    init(
        icon: Binding<String>,
        recommendation: [String] = [
            "doc.on.doc",
            "doc.on.doc.fill",
            "doc.on.clipboard",
            "doc.on.clipboard.fill",
            "scissors",
            "delete.left",
            "delete.left.fill",
            "delete.right",
            "delete.right.fill",
            "heart",
            "clear",
            "clear.fill",
            "arrowtriangle.left.and.line.vertical.and.arrowtriangle.right",
            "arrowtriangle.left.and.line.vertical.and.arrowtriangle.right.fill",
            "xmark",
            "shift",
            "shift.fill",
            "capslock",
            "capslock.fill",
            "globe",
            "keyboard.chevron.compact.down",
            "keyboard.chevron.compact.down.fill",
            "space",
            "return",
            "command",
        ]
    ) {
        self._icon = icon
        self.recommendation = recommendation
    }

    private var recommendation: [String]

    @State private var showPopover: Bool = false
    @Binding private var icon: String

    @ViewBuilder private var popoverCore: some View {
        LargeIconListView(icon: $icon, recommendation: self.recommendation)
        IconSelectField(icon: $icon)
    }

    var body: some View {
        SelectedIconView(icon: $icon)
            .onTapGesture {
                self.showPopover = true
            }
            .popover(isPresented: $showPopover) {
                popoverCore
                    .presentationCompactAdaptation(.none)
                    .ignoresSafeArea(.keyboard)
            }
    }
}

struct SystemIconPicker: View {
    init(
        icon: Binding<String>,
        recommendation: [String] = [
            "doc.on.doc",
            "doc.on.doc.fill",
            "doc.on.clipboard",
            "doc.on.clipboard.fill",
            "scissors",
            "delete.left",
            "delete.left.fill",
            "delete.right",
            "delete.right.fill",
            "heart",
            "clear",
            "clear.fill",
            "arrowtriangle.left.and.line.vertical.and.arrowtriangle.right",
            "arrowtriangle.left.and.line.vertical.and.arrowtriangle.right.fill",
            "xmark",
            "shift",
            "shift.fill",
            "capslock",
            "capslock.fill",
            "globe",
            "keyboard.chevron.compact.down",
            "keyboard.chevron.compact.down.fill",
            "space",
            "return",
            "command",
        ]
    ) {
        self._icon = icon
        self.recommendation = recommendation
    }

    private var recommendation: [String]

    @Binding private var icon: String

    var body: some View {
        LargeIconListView(icon: $icon, recommendation: recommendation)
        HStack {
            IconSelectField(icon: $icon)
            Image(systemName: self.icon)
                .frame(width: 45, height: 45)
                .foregroundStyle(.white)
                .background(.tint)
                .cornerRadius(10)
        }
        .padding(.horizontal)
    }
}

private struct SelectedIconView: View {
    @Binding var icon: String

    var body: some View {
        Image(systemName: self.icon)
            .frame(width: 45, height: 45)
            .foregroundStyle(.white)
            .background(.tint)
            .cornerRadius(10)
    }
}

private struct IconSelectField: View {
    @Binding var icon: String

    var body: some View {
        TextField("ID", text: $icon, prompt: Text("SF SymbolsのIDを指定"))
            .textFieldStyle(.roundedBorder)
            .monospaced()
            .keyboardType(.asciiCapable)
            .submitLabel(.done)
    }
}

private struct LargeIconListView: View {
    @Binding var icon: String
    var recommendation: [String]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(), count: 5)) { // カラム数の指定
            ForEach(recommendation.indices, id: \.self) { index in
                Button {
                    self.icon = self.recommendation[index]
                } label: {
                    if self.icon == self.recommendation[index] {
                        Image(systemName: self.recommendation[index])
                            .frame(width: 45, height: 45)
                            .foregroundStyle(.white)
                            .background(.tint)
                            .cornerRadius(10)
                    } else {
                        Image(systemName: self.recommendation[index])
                            .frame(width: 45, height: 45)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

@available(iOS 17, *)
#Preview {
    @Previewable @State var icon = "star"
    return SystemIconPicker(icon: $icon)
}

@available(iOS 17, *)
#Preview {
    @Previewable @State var icon = "star"
    return SystemIconCompactPicker(icon: $icon)
}
