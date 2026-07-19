//
//  UpsideSearchView.swift
//  Keyboard
//
//  Created by ensan on 2023/03/17.
//  Copyright © 2023 ensan. All rights reserved.
//

import SwiftUI
import enum KanaKanjiConverterModule.ConverterBehaviorSemantics

@MainActor
struct UpsideSearchView<Extension: ApplicationSpecificKeyboardViewExtension>: View {
    @Environment(\.userActionManager) private var action
    @Environment(Extension.Theme.self) private var theme
    @EnvironmentObject private var variableStates: VariableStates
    @State private var searchQuery = ""
    private let target: [ConverterBehaviorSemantics.ReplacementTarget]
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

    init(target: [ConverterBehaviorSemantics.ReplacementTarget]) {
        self.target = target
    }

    private var searchBarDesign: InKeyboardSearchBar<Extension>.Configuration {
        .init(placeholder: "絵文字を検索", clearButtonMode: .always, theme: theme)
    }

    var body: some View {
        VStack {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 10) {
                    ForEach(variableStates.resultModel.searchResults, id: \.id) {(data: ResultData) in
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
                                    .font(Design.fonts.resultViewFont(theme: theme, userSizePrefrerence: Extension.SettingProvider.resultViewFontSize))
                            }
                            .buttonStyle(EmojiTabResultBarButtonStyle<Extension>(height: buttonHeight))
                        }
                    }
                }
                .padding(.horizontal, 5)
            }
            HStack {
                InKeyboardSearchBar<Extension>(text: $searchQuery, configuration: searchBarDesign, initiallyFocused: true)
                    .frame(height: searchBarHeight)
                    .cornerRadius(10)
                    .padding(.trailing, 5)
                    .onChange(of: searchQuery) { (_, _) in
                        self.action.registerAction(.setSearchQuery(searchQuery, target), variableStates: variableStates)
                    }
                KeyboardBarButton<Extension>(label: .systemImage("face.smiling")) {
                    self.action.setTextDocumentProxy(.preference(.main))
                    self.action.registerActions([.setUpsideComponent(nil), .moveTab(.system(.emoji_tab))], variableStates: variableStates)
                }
                KeyboardBarButton<Extension>(label: .systemImage("arrowtriangle.down.fill")) {
                    self.action.setTextDocumentProxy(.preference(.main))
                    self.action.registerAction(.setUpsideComponent(nil), variableStates: variableStates)
                }
            }
        }
        .onAppear {
            self.action.setTextDocumentProxy(.preference(.ikTextField))
        }
        .onDisappear {
            self.variableStates.resultModel.setSearchResults([])
        }
    }
    private func pressed(candidate: any ResultViewItemData) {
        if case .text(let value) = candidate.label {
            self.action.registerAction(.insertMainDisplay(value), variableStates: variableStates)
        }
    }
}
