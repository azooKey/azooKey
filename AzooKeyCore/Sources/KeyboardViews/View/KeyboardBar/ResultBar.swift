//
//  ResultBar.swift
//  azooKey
//
//  Created by ensan on 2023/03/19.
//  Copyright © 2023 ensan. All rights reserved.
//

import SwiftUI
import SwiftUIUtils
import SwiftUtils

private struct EquatablePair<First: Equatable, Second: Equatable>: Equatable {
    var first: First
    var second: Second
}

private extension Equatable {
    func and<T: Equatable>(_ value: T) -> EquatablePair<Self, T> {
        .init(first: self, second: value)
    }
}

@MainActor
struct ResultBar<Extension: ApplicationSpecificKeyboardViewExtension>: View {
    @Environment(Extension.Theme.self) private var theme
    @Environment(\.userActionManager) private var action
    @EnvironmentObject private var variableStates: VariableStates
    @Binding private var isResultViewExpanded: Bool
    @State private var undoButtonAction: VariableStates.UndoAction?
    private var displayTabBarButton: Bool {
        Extension.SettingProvider.displayTabBarButton
    }

    private var buttonWidth: CGFloat {
        Design.keyboardBarHeight(interfaceHeight: variableStates.interfaceSize.height, orientation: variableStates.keyboardOrientation) * 0.5
    }
    private var buttonHeight: CGFloat {
        Design.keyboardBarHeight(interfaceHeight: variableStates.interfaceSize.height, orientation: variableStates.keyboardOrientation) * 0.6
    }

    init(isResultViewExpanded: Binding<Bool>) {
        self._isResultViewExpanded = isResultViewExpanded
    }

    private var tabBarButton: some View {
        TabBarButton<Extension>()
            .zIndex(10)
    }

    var body: some View {
        Group {
            if variableStates.resultModel.displayState == .nothing {
                HStack {
                    if displayTabBarButton {
                        tabBarButton
                        if undoButtonAction != nil {
                            Spacer()
                        }
                    }
                }
                .overlay {
                    if let undoButtonAction {
                        Button("取り消す", systemImage: "arrow.uturn.backward") {
                            KeyboardFeedback<Extension>.click()
                            self.action.registerAction(undoButtonAction.action, variableStates: variableStates)
                        }
                        .buttonStyle(ResultButtonStyle<Extension>(height: buttonHeight))
                    }
                }
                .onAppear {
                    if variableStates.undoAction?.textChangedCount == variableStates.textChangedCount {
                        self.undoButtonAction = variableStates.undoAction
                    } else {
                        self.undoButtonAction = nil
                    }
                }
                .onChange(of: variableStates.undoAction.and(variableStates.textChangedCount)) {newValue in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if newValue.first?.textChangedCount == newValue.second {
                            self.undoButtonAction = newValue.first
                        } else {
                            self.undoButtonAction = nil
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.sRGB, white: 1, opacity: 0.001))
                .onLongPressGesture {
                    self.action.registerAction(.setTabBar(.toggle), variableStates: variableStates)
                }
            } else {
                HStack {
                    if variableStates.resultModel.displayState == .predictions && displayTabBarButton {
                        tabBarButton
                        Spacer()
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        ScrollViewReader {scrollViewProxy in
                            LazyHStack(spacing: 10) {
                                ForEach(variableStates.resultModel.resultData, id: \.id) {(data: ResultData) in
                                    if data.candidate.inputable {
                                        Button(action: {
                                            KeyboardFeedback<Extension>.click()
                                            self.pressed(candidate: data.candidate)
                                        }, label: {
                                            Text(
                                                Design.fonts.forceJapaneseFont(
                                                    text: data.candidate.text,
                                                    theme: theme,
                                                    userSizePrefrerence: Extension.SettingProvider.resultViewFontSize
                                                )
                                            )
                                        })
                                        .buttonStyle(ResultButtonStyle<Extension>(height: buttonHeight, selected: .init(selection: variableStates.resultModel.selection, index: data.id)))
                                        .contextMenu {
                                            ResultContextMenuView(candidate: data.candidate, displayResetLearningButton: Extension.SettingProvider.canResetLearningForCandidate, index: data.id)
                                        }
                                        .id(data.id)
                                    } else {
                                        Text(Design.fonts.forceJapaneseFont(text: data.candidate.text, theme: theme, userSizePrefrerence: Extension.SettingProvider.resultViewFontSize))
                                            .underline(true, color: .accentColor)
                                    }
                                }
                            }
                            .onChange(of: variableStates.resultModel.updateResult) { _ in
                                scrollViewProxy.scrollTo(0, anchor: .trailing)
                            }
                            .onChange(of: variableStates.resultModel.selection) { value in
                                if let value {
                                    withAnimation(.easeIn(duration: 0.05)) {
                                        scrollViewProxy.scrollTo(value, anchor: .center)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 5)
                    }
                    .zIndex(0)
                    if variableStates.resultModel.displayState == .results {
                        // 候補を展開するボタン
                        Button {
                            self.expand()
                        } label: {
                            ZStack {
                                Color(white: 1, opacity: 0.001)
                                    .frame(width: buttonWidth)
                                Image(systemName: "chevron.down")
                                    .font(Design.fonts.iconImageFont(keyViewFontSizePreference: Extension.SettingProvider.keyViewFontSize, theme: theme))
                                    .frame(height: 18)
                            }
                        }
                        .buttonStyle(ResultButtonStyle<Extension>(height: buttonHeight))
                        .padding(.trailing, 10)
                    }
                }
            }
        }
        .animation(.easeIn(duration: 0.2), value: variableStates.resultModel.displayState == .nothing)
    }

    private func pressed(candidate: any ResultViewItemData) {
        self.action.notifyComplete(candidate, variableStates: variableStates)
    }

    private func expand() {
        self.isResultViewExpanded = true
    }
}

struct ResultContextMenuView: View {
    @EnvironmentObject private var variableStates: VariableStates
    @Environment(\.userActionManager) private var action
    private let candidate: any ResultViewItemData
    private let index: Int?
    private let displayResetLearningButton: Bool

    init(candidate: any ResultViewItemData, displayResetLearningButton: Bool, index: Int? = nil) {
        self.candidate = candidate
        self.index = index
        self.displayResetLearningButton = displayResetLearningButton
    }

    var body: some View {
        Button("大きな文字で表示", systemImage: "plus.magnifyingglass") {
            variableStates.magnifyingText = candidate.text
            variableStates.boolStates.isTextMagnifying = true
        }
        if displayResetLearningButton {
            Button("この候補の学習をリセットする", systemImage: "clear") {
                action.notifyForgetCandidate(candidate, variableStates: variableStates)
            }
        }
        Section(SemiStaticStates.shared.hasFullAccess ? "フィードバックを送信" : "フルアクセスが必要です") {
            Button("意図した変換ではない", systemImage: "exclamationmark.bubble") {
                Task { @MainActor in
                    await action.notifyReportWrongConversion(candidate, index: index, variableStates: variableStates)
                }
            }
            .disabled(!SemiStaticStates.shared.hasFullAccess)
            Button("欲しい変換がない", systemImage: "questionmark.bubble") {
                Task { @MainActor in
                    await action.notifyReportWrongConversion(candidate, index: index, variableStates: variableStates)
                }
            }
            .disabled(!SemiStaticStates.shared.hasFullAccess)
        }
        #if DEBUG
        Button("デバッグ情報を表示する", systemImage: "ladybug.fill") {
            debug(self.candidate.getDebugInformation())
        }
        #endif
    }
}

struct ResultButtonStyle<Extension: ApplicationSpecificKeyboardViewExtension>: ButtonStyle {
    enum SelectionState: Sendable {
        case nothing
        case this
        case other
        init(selection: Int?, index: Int) {
            if let selection {
                if selection == index {
                    self = .this
                } else {
                    self = .other
                }
            } else {
                self = .nothing
            }
        }
    }
    private let height: CGFloat
    private let userSizePreference: Double
    private let selected: SelectionState

    @Environment(Extension.Theme.self) private var theme

    @MainActor init(height: CGFloat, selected: SelectionState = .nothing) {
        self.userSizePreference = Extension.SettingProvider.resultViewFontSize
        self.height = height
        self.selected = selected
    }

    private func background(configuration: Configuration) -> any ShapeStyle {
        if configuration.isPressed {
            theme.pushedKeyFillColor.color.opacity(0.5)
        } else {
            switch self.selected {
            case .nothing: theme.resultBackgroundColor.color
            case .this: Material.thin
            case .other: theme.resultBackgroundColor.color.opacity(0.5)
            }
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Design.fonts.resultViewFont(theme: theme, userSizePrefrerence: self.userSizePreference))
            .frame(height: height)
            .padding(.all, 5)
            .foregroundStyle(theme.resultTextColor.color) // 文字色は常に不透明度1で描画する
            .background(AnyShapeStyle(background(configuration: configuration)))
            .cornerRadius(5.0)
            .compositingGroup()
            .contentShape(Rectangle())
            .animation(nil, value: configuration.isPressed)
    }
}
