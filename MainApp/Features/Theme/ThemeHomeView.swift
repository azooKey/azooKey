//
//  ThemeTab.swift
//  MainApp
//
//  Created by ensan on 2021/02/04.
//  Copyright © 2021 ensan. All rights reserved.
//

import AzooKeyUtils
import KeyboardViews
import SwiftUI
import SwiftUIUtils
import SwiftUtils

private struct ThemeRowLayout: Layout {
    var spacing: CGFloat = 0

    private func itemWidths(totalWidth: CGFloat, count: Int) -> [CGFloat] {
        guard count > 0 else {
            return []
        }
        let contentWidth = max(0, totalWidth - spacing * CGFloat(count - 1))
        if count == 2 {
            return [contentWidth * 2 / 3, contentWidth / 3]
        }
        return Array(
            repeating: contentWidth / CGFloat(count),
            count: count
        )
    }

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        guard !subviews.isEmpty else {
            return .zero
        }
        let totalSpacing = spacing * CGFloat(subviews.count - 1)
        let idealWidths = subviews.map {
            $0.sizeThatFits(.unspecified).width
        }
        let fallbackContentWidth: CGFloat
        if idealWidths.count == 2 {
            fallbackContentWidth = max(
                idealWidths[0] * 3 / 2,
                idealWidths[1] * 3
            )
        } else {
            fallbackContentWidth = idealWidths.reduce(0, +)
        }
        let width = proposal.width ?? fallbackContentWidth + totalSpacing
        let widths = itemWidths(
            totalWidth: width,
            count: subviews.count
        )
        let height = zip(subviews, widths).map { subview, width in
            subview.sizeThatFits(
                ProposedViewSize(width: width, height: proposal.height)
            ).height
        }.max() ?? 0
        return CGSize(width: width, height: height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        guard !subviews.isEmpty else {
            return
        }
        let widths = itemWidths(
            totalWidth: bounds.width,
            count: subviews.count
        )
        var x = bounds.minX
        for (index, subview) in subviews.enumerated() {
            let itemWidth = widths[index]
            let itemProposal = ProposedViewSize(
                width: itemWidth,
                height: bounds.height
            )
            let itemHeight = subview.sizeThatFits(itemProposal).height
            subview.place(
                at: CGPoint(
                    x: x,
                    y: bounds.midY
                ),
                anchor: .leading,
                proposal: ProposedViewSize(
                    width: itemWidth,
                    height: itemHeight
                )
            )
            x += itemWidth + spacing
        }
    }
}

private struct AdaptiveThemeActionLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 6) {
                configuration.icon
                configuration.title
            }
            .fixedSize(horizontal: true, vertical: false)
            configuration.icon
        }
    }
}

@MainActor
struct ThemeHomeView: View {
    enum Path: Hashable {
        case edit(index: Int?)
    }

    @Namespace private var namespace
    @EnvironmentObject private var keyboardConfiguration: KeyboardConfigurationState
    @State private var manager = ThemeIndexManager.load()

    @State private var editViewIndex: Int?
    @State private var path: [Path] = []

    private func theme(at index: Int) -> AzooKeyTheme? {
        do {
            return try manager.theme(at: index)
        } catch {
            debug(error)
            return nil
        }
    }

    @MainActor
    private func circle(width: CGFloat, systemName: String, color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(width: width, height: width)
            .overlay {
                Image(systemName: systemName)
                    .font(Font.system(size: width / 2).weight(.bold))
                    .foregroundStyle(.white)
            }
    }

    private var tab: KeyboardTab.ExistentialTab {
        switch keyboardConfiguration.japaneseLayout {
        case .flick:
            return .flick_hira
        case .qwerty:
            return .qwerty_hira
        case let .custard(identifier):
            return .custard((try? CustardManager.load().custard(identifier: identifier)) ?? .errorMessage)
        }
    }

    @MainActor @ViewBuilder
    private var listSection: some View {
        let tab = tab
        ForEach(manager.indices.reversed(), id: \.self) { index in
            if let theme = theme(at: index) {
                ThemeRowLayout(spacing: 8) {
                    ZStack {
                        KeyboardPreview(
                            theme: theme,
                            sizing: .fitToExtension,
                            defaultTab: tab
                        )
                            .disabled(true)
                            .overlay {
                                if manager.selectedIndex == index || manager.selectedIndexInDarkMode == index {
                                    Color.black.opacity(0.3)
                                }
                            }
                            .background {
                                Rectangle()
                                    .foregroundStyle(.systemGray4)
                            }
                            .onTapGesture {
                                if manager.selectedIndex != index && manager.selectedIndexInDarkMode != index {
                                    self.manager.select(at: index)
                                }
                            }
                            .overlay(alignment: .bottom) {
                                if let title = manager.themeTitle(at: index) {
                                    Label(title, systemImage: "photo")
                                        .labelStyle(LiquidLabelStyle())
                                        .labelStyle(.titleOnly)
                                }
                            }
                        if manager.selectedIndex == manager.selectedIndexInDarkMode,
                           manager.selectedIndex == index {
                            circle(width: 80, systemName: "checkmark", color: .blue)
                                .matchedGeometryEffect(id: "selected_theme_checkmark", in: namespace)
                        } else if manager.selectedIndex == index {
                            circle(width: 80, systemName: "sun.max.fill", color: .blue)
                                .matchedGeometryEffect(id: "selected_theme_light", in: namespace)
                        } else if manager.selectedIndexInDarkMode == index {
                            circle(width: 80, systemName: "moon.fill", color: .blue)
                                .matchedGeometryEffect(id: "selected_theme_dark", in: namespace)
                        }
                    }
                    VStack {
                        if manager.selectedIndex == manager.selectedIndexInDarkMode {
                            if manager.selectedIndex != index {
                                Button("選択", systemImage: "checkmark") {
                                    manager.select(at: index)
                                }
                            }
                        } else {
                            if manager.selectedIndex != index {
                                Button("ライトモード", systemImage: "sun.max.fill") {
                                    manager.selectForLightMode(at: index)
                                }
                            }
                            if manager.selectedIndexInDarkMode != index {
                                Button("ダークモード", systemImage: "moon.fill") {
                                    manager.selectForDarkMode(at: index)
                                }
                            }
                        }
                        if index > 0 {
                            Button("編集", systemImage: "slider.horizontal.3") {
                                self.editViewIndex = index
                                self.path.append(.edit(index: index))
                            }
                        }
                    }
                    .labelStyle(AdaptiveThemeActionLabelStyle())
                    .buttonStyle(LargeButtonStyle(backgroundColor: .systemGray5))
                }
                .contextMenu {
                    if self.manager.selectedIndex == self.manager.selectedIndexInDarkMode {
                        Button("ライトモードで使用", systemImage: "sun.max.fill") {
                            manager.selectForLightMode(at: index)
                        }
                        Button("ダークモードで使用", systemImage: "moon.fill") {
                            manager.selectForDarkMode(at: index)
                        }
                    }
                    Button("編集する", systemImage: "slider.horizontal.3") {
                        self.editViewIndex = index
                        self.path.append(.edit(index: index))
                    }
                    .disabled(index <= 0)
                    Button("削除する", systemImage: "trash", role: .destructive) {
                        manager.remove(index: index)
                    }
                    .disabled(index <= 0)
                }
            }
        }
        .animation(.easeIn(duration: 0.15), value: manager.selectedIndex)
        .animation(.easeIn(duration: 0.15), value: manager.selectedIndexInDarkMode)
    }

    var body: some View {
        NavigationStack(path: $path) {
            Form {
                Section(header: Text("作る")) {
                    Button("着せ替えを作成") {
                        editViewIndex = nil
                        path.append(.edit(index: nil))
                    }
                    .foregroundStyle(.primary)
                }
                Section(header: Text("選ぶ")) {
                    listSection
                }
            }
            .navigationBarTitle(Text("着せ替え"), displayMode: .large)
            .navigationDestination(for: Path.self) { destination in
                switch destination {
                case let .edit(index: index):
                    ThemeEditView(index: index, manager: $manager)
                }
            }
        }
    }
}
