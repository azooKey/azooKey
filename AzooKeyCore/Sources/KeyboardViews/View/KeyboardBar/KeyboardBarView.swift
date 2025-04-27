//
//  KeyboardBarView.swift
//  azooKey
//
//  Created by ensan on 2020/04/10.
//  Copyright © 2020 ensan. All rights reserved.
//

import Foundation
import SwiftUI
import SwiftUIUtils

@MainActor
struct KeyboardBarView<Extension: ApplicationSpecificKeyboardViewExtension>: View {
    @EnvironmentObject private var variableStates: VariableStates
    @Binding private var isResultViewExpanded: Bool
    @Environment(Extension.Theme.self) private var theme
    // CursorBarは操作がない場合に非表示にする。これをハンドルするためのタスク
    @State private var dismissTask: Task<(), any Error>?

    private var useReflectStyleCursorBar: Bool {
        Extension.SettingProvider.useReflectStyleCursorBar
    }

    private var displayCursorBarAutomatically: Bool {
        Extension.SettingProvider.displayCursorBarAutomatically
    }

    init(isResultViewExpanded: Binding<Bool>) {
        self._isResultViewExpanded = isResultViewExpanded
    }

    var body: some View {
        switch variableStates.barState {
        case .cursor:
            Group {
                if useReflectStyleCursorBar {
                    ReflectStyleCursorBar<Extension>()
                } else {
                    SliderStyleCursorBar<Extension>()
                }
            }
            .onAppear {
                // 表示したタイミングでdismissTaskを開始
                self.restartCursorBarDismissTask()
            }
            .onChange(of: variableStates.textChangedCount) { _ in
                // カーソルが動くたびにrestart
                self.restartCursorBarDismissTask()
            }
        case .tab:
            let tabBarData = (try? variableStates.tabManager.config.custardManager.tabbar(identifier: 0)) ?? .default
            TabBarView<Extension>(data: tabBarData)
        case .none:
            switch variableStates.tabManager.tab {
            case let .existential(.special(tab)) where tab == .emoji:
                EmojiTabResultBar<Extension>()
            default:
                ResultBar<Extension>(isResultViewExpanded: $isResultViewExpanded)
            }
        }
    }

    private func restartCursorBarDismissTask() {
        // 自動非表示はdisplayCursorBarAutomaticallyが有効の場合のみにする。
        guard self.displayCursorBarAutomatically else {
            return
        }
        self.dismissTask?.cancel()
        self.dismissTask = Task {
            // 10秒待つ
            try await Task.sleep(nanoseconds: 10_000_000_000)
            try Task.checkCancellation()
            withAnimation {
                variableStates.barState = .none
            }
        }
    }
}

@MainActor
struct KeyboardBarButton<Extension: ApplicationSpecificKeyboardViewExtension>: View {
    enum LabelType {
        case azooKeyIcon(AzooKeyIcon.Looks = .normal)
        case systemImage(String)
    }
    @Environment(Extension.Theme.self) private var theme
    @EnvironmentObject private var variableStates: VariableStates
    private var action: () -> Void
    private let label: LabelType

    init(label: LabelType, action: @escaping () -> Void) {
        self.label = label
        self.action = action
    }

    private var buttonBackgroundColor: Color {
        theme.tabBarButtonBackgroundColor
    }

    private var buttonLabelColor: Color {
        theme.tabBarButtonForegroundColor
    }

    private var circleSize: CGFloat {
        Design.keyboardBarHeight(interfaceHeight: variableStates.interfaceSize.height, orientation: variableStates.keyboardOrientation) * 0.8
    }

    private var iconSize: CGFloat {
        Design.keyboardBarHeight(interfaceHeight: variableStates.interfaceSize.height, orientation: variableStates.keyboardOrientation) * 0.6
    }

    var body: some View {
        Button(action: self.action) {
            ZStack {
                Circle()
                    .strokeAndFill(fillContent: buttonBackgroundColor, strokeContent: theme.borderColor.color, lineWidth: theme.borderWidth)
                    .frame(width: circleSize, height: circleSize)
                switch label {
                case let .azooKeyIcon(looks):
                    AzooKeyIcon(fixedSize: iconSize, color: .color(buttonLabelColor), looks: looks)
                case let .systemImage(name):
                    Image(systemName: name)
                        .frame(width: iconSize, height: iconSize)
                        .foregroundStyle(buttonLabelColor)
                }
            }
        }
        .padding(.all, 5)
    }
}
