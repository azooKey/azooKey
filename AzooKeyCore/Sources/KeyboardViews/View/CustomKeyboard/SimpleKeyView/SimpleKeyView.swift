//
//  SimpleKeyView.swift
//  azooKey
//
//  Created by ensan on 2021/02/19.
//  Copyright © 2021 ensan. All rights reserved.
//

import Foundation
import SwiftUI
import SwiftUIUtils

@MainActor
public struct SimpleKeyView<Extension: ApplicationSpecificKeyboardViewExtension>: View {
    private let model: any SimpleKeyModelProtocol<Extension>
    @EnvironmentObject private var variableStates: VariableStates
    @Environment(Extension.Theme.self) private var theme
    @Environment(\.userActionManager) private var action

    private let keyViewWidth: CGFloat
    private let keyViewHeight: CGFloat

    init(model: any SimpleKeyModelProtocol<Extension>, tabDesign: TabDependentDesign) {
        self.model = model
        self.keyViewWidth = tabDesign.keyViewWidth
        self.keyViewHeight = tabDesign.keyViewHeight
    }

    init(model: any SimpleKeyModelProtocol<Extension>, width: CGFloat, height: CGFloat) {
        self.model = model
        self.keyViewWidth = width
        self.keyViewHeight = height
    }

    @State private var isPressed = false
    @State private var pressStartDate = Date()

    private func label(width: CGFloat) -> some View {
        model.label(width: keyViewWidth, states: variableStates)
    }
    private var longpressDuration: TimeInterval {
        switch self.model.longPressActions(variableStates: variableStates).duration {
        case .light:
            0.125
        case .normal:
            0.400
        }
    }
    private var keyBackground: SimpleKeyBackgroundStyleValue {
        isPressed ? model.backgroundStyleWhenPressed(theme: theme) : model.unpressedKeyColorType.color(states: variableStates, theme: theme)
    }

    public var body: some View {
        label(width: keyViewWidth)
            .background {
                KeyBackground(
                    backgroundColor: keyBackground.color,
                    borderColor: theme.borderColor.color,
                    borderWidth: theme.borderWidth,
                    size: .init(width: keyViewWidth, height: keyViewHeight),
                    shadow: (
                        color: theme.keyShadow?.color.color ?? .clear,
                        radius: theme.keyShadow?.radius ?? 0.0,
                        x: theme.keyShadow?.x ?? 0,
                        y: theme.keyShadow?.y ?? 0
                    ),
                    blendMode: keyBackground.blendMode,
                    appearance: theme.style
                )
            }
            .frame(width: keyViewWidth, height: keyViewHeight)
            .overlay {
                Group {
                    if !(model is SimpleChangeKeyboardKeyModel<Extension> && SemiStaticStates.shared.needsInputModeSwitchKey) {
                        TouchDownAndTouchUpGestureView {
                            isPressed = true
                            pressStartDate = Date()
                            model.feedback(variableStates: variableStates)
                            action.reserveLongPressAction(self.model.longPressActions(variableStates: variableStates), taskStartDuration: self.longpressDuration, variableStates: variableStates)
                        } touchMovedCallBack: { state  in
                            if state.distance > 15 {
                                isPressed = false
                                pressStartDate = Date()
                                action.registerLongPressActionEnd(self.model.longPressActions(variableStates: variableStates))
                            }
                        } touchUpCallBack: {state in
                            isPressed = false
                            action.registerLongPressActionEnd(self.model.longPressActions(variableStates: variableStates))
                            if Date().timeIntervalSince(pressStartDate) < longpressDuration && state.distance < 30 {
                                action.registerActions(self.model.pressActions(variableStates: variableStates), variableStates: variableStates)
                                self.model.additionalOnPress(variableStates: variableStates)
                            }
                        }
                    }
                }
                .onDisappear {
                    action.registerLongPressActionEnd(self.model.longPressActions(variableStates: variableStates))
                }
            }
            .frame(width: keyViewWidth, height: keyViewHeight)
    }
}
