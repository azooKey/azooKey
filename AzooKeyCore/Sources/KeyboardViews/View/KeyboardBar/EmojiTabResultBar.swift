//
//  EmojiTabResultBar.swift
//  azooKey
//
//  Created by ensan on 2023/03/15.
//  Copyright © 2023 ensan. All rights reserved.
//

import SwiftUI
import SwiftUIUtils

@MainActor
struct EmojiTabResultBar<Extension: ApplicationSpecificKeyboardViewExtension>: View {
    init() {}
    @Environment(Extension.Theme.self) private var theme
    @Environment(\.userActionManager) private var action
    @EnvironmentObject private var variableStates: VariableStates
    @Namespace private var namespace
    private var buttonHeight: CGFloat {
        Design.keyboardBarHeight(
            interfaceHeight: variableStates.interfaceSize.height,
            context: variableStates.layoutContext
        ) * 0.9
    }
    private var searchBarHeight: CGFloat {
        Design.keyboardBarHeight(
            interfaceHeight: variableStates.interfaceSize.height,
            context: variableStates.layoutContext
        ) * 0.8
    }
    private var searchBarDesign: InKeyboardSearchBar<Extension>.Configuration {
        .init(placeholder: "絵文字を検索", theme: theme)
    }
    @State private var searchQuery = ""
    @State private var showResults = false

    var body: some View {
        HStack {
            TabBarButton<Extension>()
            if !showResults {
                // 見た目だけ表示しておいて、実際はoverlayのボタンになっている
                InKeyboardSearchBar(text: $searchQuery, configuration: searchBarDesign)
                    .overlay {
                        Rectangle()
                            .fill(Color.background.opacity(0.001))
                            .onTapGesture {
                                self.action.registerActions([
                                    .moveTab(.system(.user_japanese)),
                                    .setUpsideComponent(.search([.emoji])),
                                ], variableStates: variableStates)
                            }
                    }
                    .padding(.trailing, 5)
                    .matchedGeometryEffect(id: "SearchBar", in: namespace)
            } else {
                KeyboardBarButton<Extension>(label: .systemImage("magnifyingglass")) {
                    self.action.registerActions([
                        .moveTab(.system(.user_japanese)),
                        .setUpsideComponent(.search([.emoji])),
                    ], variableStates: variableStates)
                }
                .matchedGeometryEffect(id: "SearchBar", in: namespace)
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 10) {
                        ForEach(variableStates.resultModel.results, id: \.id) {(data: ResultData) in
                            switch data.candidate.label {
                            case .text(let value):
                                if data.candidate.inputable {
                                    Button(value) {
                                        KeyboardFeedback<Extension>.click()
                                        self.pressed(candidate: data.candidate)
                                    }
                                    .buttonStyle(EmojiTabResultBarButtonStyle<Extension>(height: buttonHeight))
                                    .contextMenu {
                                        ResultContextMenuView(candidate: data.candidate, displayResetLearningButton: false)
                                    }
                                } else {
                                    Text(value)
                                        .font(Design.fonts.resultViewFont(theme: theme, userSizePrefrerence: Extension.SettingProvider.resultViewFontSize))
                                        .underline(true, color: .accentColor)
                                }
                            case .systemImage(let name, let accessibilityLabel):
                                Button {
                                    KeyboardFeedback<Extension>.click()
                                    self.pressed(candidate: data.candidate)
                                } label: {
                                    Image(systemName: name)
                                        .accessibilityLabel(accessibilityLabel ?? name)
                                }
                                .buttonStyle(EmojiTabResultBarButtonStyle<Extension>(height: buttonHeight))
                            }
                        }
                    }
                    .padding(.horizontal, 5)
                }
            }
        }
        .onChange(of: variableStates.resultModel.results.first?.candidate.textualRepresentation) { (_, newValue) in
            if newValue == nil && showResults {
                withAnimation(.easeIn(duration: 0.2)) {
                    showResults = false
                }
            } else if newValue != nil && !showResults {
                withAnimation(.easeIn(duration: 0.2)) {
                    showResults = true
                }
            }
        }
    }

    private func pressed(candidate: any ResultViewItemData) {
        self.action.notifyComplete(candidate, variableStates: variableStates)
    }
}

struct EmojiTabResultBarButtonStyle<Extension: ApplicationSpecificKeyboardViewExtension>: ButtonStyle {
    private let height: CGFloat
    private let userSizePrefrerence: CGFloat
    @Environment(Extension.Theme.self) private var theme

    @MainActor init(height: CGFloat) {
        self.userSizePrefrerence = Extension.SettingProvider.resultViewFontSize
        self.height = height
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Design.fonts.resultViewFont(theme: theme, userSizePrefrerence: self.userSizePrefrerence, fontSize: height * 0.9))
            .frame(height: height)
            .foregroundStyle(theme.resultTextColor.color) // 文字色は常に不透明度1で描画する
            .background(
                configuration.isPressed ?
                    theme.pushedKeyFillColor.color.opacity(0.5) :
                    theme.resultBackgroundColor.color
            )
            .cornerRadius(5.0)
    }
}
