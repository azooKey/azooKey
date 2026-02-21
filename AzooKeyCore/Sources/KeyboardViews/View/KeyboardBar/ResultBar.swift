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
    private enum TabBarButtonPlacement {
        case center
        case leading
    }

    @Environment(Extension.Theme.self) private var theme
    @Environment(\.userActionManager) private var action
    @EnvironmentObject private var variableStates: VariableStates
    @Binding private var isResultViewExpanded: Bool
    @State private var undoButtonAction: VariableStates.UndoAction?
    @State private var tabBarButtonPlacement: TabBarButtonPlacement = .center
    @State private var isTabBarButtonVisible = false
    @State private var tabBarButtonAnimationTask: Task<(), Never>?
    private var displayTabBarButton: Bool {
        Extension.SettingProvider.displayTabBarButton
    }

    private var buttonWidth: CGFloat {
        Design.keyboardBarHeight(interfaceHeight: variableStates.interfaceSize.height, orientation: variableStates.keyboardOrientation) * 0.5
    }
    private var buttonHeight: CGFloat {
        Design.keyboardBarHeight(interfaceHeight: variableStates.interfaceSize.height, orientation: variableStates.keyboardOrientation) * 0.6
    }
    private var tabBarButtonReservedWidth: CGFloat {
        // KeyboardBarButton has circle size (0.8 * bar height) plus horizontal padding (5pt each side).
        Design.keyboardBarHeight(interfaceHeight: variableStates.interfaceSize.height, orientation: variableStates.keyboardOrientation) * 0.8 + 10
    }

    init(isResultViewExpanded: Binding<Bool>) {
        self._isResultViewExpanded = isResultViewExpanded
    }

    private var tabBarButton: some View {
        TabBarButton<Extension>()
            .zIndex(10)
    }

    private var tabBarButtonHiddenScale: CGFloat { 0.55 }

    private var tabBarButtonAlignment: Alignment {
        switch tabBarButtonPlacement {
        case .center:
            .center
        case .leading:
            .leading
        }
    }

    private func setTabBarButtonState(for displayState: ResultModel.DisplayState) {
        switch displayState {
        case .nothing:
            self.tabBarButtonPlacement = .center
            self.isTabBarButtonVisible = true
        case .predictions:
            self.tabBarButtonPlacement = .leading
            self.isTabBarButtonVisible = true
        case .results:
            self.tabBarButtonPlacement = .center
            self.isTabBarButtonVisible = false
        }
    }

    private func updateTabBarButtonLayout(from oldState: ResultModel.DisplayState, to newState: ResultModel.DisplayState) {
        let stagedHideDuration = 0.10
        let stagedShowDuration = 0.22

        tabBarButtonAnimationTask?.cancel()
        tabBarButtonAnimationTask = nil

        if oldState == .predictions && newState == .nothing {
            withAnimation(.easeIn(duration: stagedHideDuration)) {
                self.isTabBarButtonVisible = false
            }

            tabBarButtonAnimationTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(stagedHideDuration * 1_000_000_000))
                guard !Task.isCancelled else { return }
                self.tabBarButtonPlacement = .center
                withAnimation(.easeOut(duration: stagedShowDuration)) {
                    self.isTabBarButtonVisible = true
                }
            }
            return
        }

        self.setTabBarButtonState(for: newState)
    }

    var body: some View {
        Group {
            if variableStates.resultModel.displayState == .nothing {
                HStack {}
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: .trailing) {
                    if let undoButtonAction {
                        Button("取り消す", systemImage: "arrow.uturn.backward") {
                            KeyboardFeedback<Extension>.click()
                            self.action.registerAction(undoButtonAction.action, variableStates: variableStates)
                        }
                        .buttonStyle(ResultButtonStyle<Extension>(height: buttonHeight))
                        .padding(.trailing, 10)
                    }
                }
                .onAppear {
                    if variableStates.undoAction?.textChangedCount == variableStates.textChangedCount {
                        self.undoButtonAction = variableStates.undoAction
                    } else {
                        self.undoButtonAction = nil
                    }
                }
                .onChange(of: variableStates.undoAction.and(variableStates.textChangedCount)) { (_, newValue) in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if newValue.first?.textChangedCount == newValue.second {
                            self.undoButtonAction = newValue.first
                        } else {
                            self.undoButtonAction = nil
                        }
                    }
                }
                .background(Color(.sRGB, white: 1, opacity: 0.001))
                .onLongPressGesture {
                    self.action.registerAction(.setTabBar(.toggle), variableStates: variableStates)
                }
            } else {
                HStack {
                    if variableStates.resultModel.displayState == .predictions && displayTabBarButton {
                        Color.clear
                            .frame(width: tabBarButtonReservedWidth)
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        ScrollViewReader {scrollViewProxy in
                            LazyHStack(spacing: 10) {
                                ForEach(variableStates.resultModel.resultData, id: \.id) {(data: ResultData) in
                                    switch data.candidate.label {
                                    case .text(let value):
                                        if data.candidate.inputable {
                                            Button(action: {
                                                KeyboardFeedback<Extension>.click()
                                                self.pressed(data)
                                            }, label: {
                                                Text(
                                                    Design.fonts.forceJapaneseFont(
                                                        text: value,
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
                                            Text(Design.fonts.forceJapaneseFont(text: value, theme: theme, userSizePrefrerence: Extension.SettingProvider.resultViewFontSize))
                                                .underline(true, color: .accentColor)
                                        }
                                    case .systemImage(let name, let accessibilityLabel):
                                        Button {
                                            KeyboardFeedback<Extension>.click()
                                            self.pressed(data)
                                        } label: {
                                            Image(systemName: name)
                                                .accessibilityLabel(accessibilityLabel ?? name)
                                                .font(Design.fonts.resultViewFont(theme: theme, userSizePrefrerence: Extension.SettingProvider.resultViewFontSize))
                                        }
                                        .buttonStyle(ResultButtonStyle<Extension>(height: buttonHeight, selected: .init(selection: variableStates.resultModel.selection, index: data.id)))
                                        .id(data.id)
                                    }
                                }
                            }
                            .onChange(of: variableStates.resultModel.updateResult) { (_, _) in
                                scrollViewProxy.scrollTo(0, anchor: .trailing)
                            }
                            .onChange(of: variableStates.resultModel.selection) { (_, newValue) in
                                if let newValue {
                                    withAnimation(.easeIn(duration: 0.05)) {
                                        scrollViewProxy.scrollTo(newValue, anchor: .center)
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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .overlay(alignment: tabBarButtonAlignment) {
            if displayTabBarButton {
                tabBarButton
                    .scaleEffect(isTabBarButtonVisible ? 1 : tabBarButtonHiddenScale, anchor: .center)
                    .opacity(isTabBarButtonVisible ? 1 : 0)
                    .allowsHitTesting(isTabBarButtonVisible)
            }
        }
        .onAppear {
            self.setTabBarButtonState(for: variableStates.resultModel.displayState)
        }
        .onChange(of: variableStates.resultModel.displayState) { oldValue, newValue in
            self.updateTabBarButtonLayout(from: oldValue, to: newValue)
        }
        .onDisappear {
            tabBarButtonAnimationTask?.cancel()
            tabBarButtonAnimationTask = nil
        }
    }

    private func pressed(_ data: ResultData) {
        self.action.prepareReportSuggestion(candidate: data.candidate, index: data.id, variableStates: variableStates)
        self.action.notifyComplete(data.candidate, variableStates: variableStates)
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
            if let labelText = candidate.textualRepresentation {
                variableStates.magnifyingText = labelText
                variableStates.boolStates.isTextMagnifying = true
            }
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
