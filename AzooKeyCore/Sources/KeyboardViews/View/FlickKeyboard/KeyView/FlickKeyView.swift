//
//  KeyView.swift
//  azooKey
//
//  Created by ensan on 2020/04/08.
//  Copyright © 2020 ensan. All rights reserved.
//

import CustardKit
import Foundation
import SwiftUI
import SwiftUIUtils

enum KeyPressState {
    case inactive
    case started(Date)
    case oneDirectionSuggested(FlickDirection, Date)
    case longPressed
    case longFlicked(FlickDirection)

    fileprivate func isActive() -> Bool {
        if case .inactive = self {
            return false
        }
        return true
    }
}

@MainActor
public struct FlickKeyView<Extension: ApplicationSpecificKeyboardViewExtension>: View {
    private let model: any FlickKeyModelProtocol<Extension>

    @State private var pressState: KeyPressState = .inactive
    @Binding private var suggestState: FlickSuggestState
    @State private var suggestDismissTask: Task<Void, any Error>?
    // TODO: 消せるはず
    @State private var startLocation: CGPoint?

    @EnvironmentObject private var variableStates: VariableStates

    @Environment(Extension.Theme.self) private var theme
    @Environment(\.userActionManager) private var action
    private let size: CGSize
    private let position: (x: Int, y: Int)

    init(model: any FlickKeyModelProtocol<Extension>, size: CGSize, position: (x: Int, y: Int), suggestState: Binding<FlickSuggestState>) {
        self.model = model
        self.size = size
        self.position = position
        self._suggestState = suggestState
    }

    private var suggestAnimation: Animation {
        Animation.easeIn(duration: 0.1).delay(0.5)
    }

    private func getSuggestState() -> FlickSuggestType? {
        self.suggestState.items[self.position.x, default: [:]][self.position.y]
    }
    private func setSuggestState(_ state: FlickSuggestType?) {
        self.suggestState.items[self.position.x, default: [:]][self.position.y] = state
    }

    private func flickKeys() -> [FlickDirection: FlickedKeyModel] {
        self.model.flickKeys(variableStates: variableStates)
    }

    private func label(width: CGFloat) -> KeyLabel<Extension> {
        self.model.label(width: width, theme: theme, states: variableStates)
    }

    /// 長押しとみなすまでの時間
    private var longpressDuration: TimeInterval {
        0.4
    }

    private var gesture: some Gesture {
        DragGesture(minimumDistance: .zero, coordinateSpace: .global)
            .onChanged {(value: DragGesture.Value) in
                let startLocation = self.startLocation ?? value.startLocation
                let d = startLocation.direction(to: value.location)
                switch pressState {
                // 押していない状態の場合
                case .inactive:
                    // 押し始めの時間を記録する。
                    pressState = .started(Date())
                    self.startLocation = value.startLocation
                    self.model.feedback(variableStates: variableStates)
                    withAnimation(suggestAnimation) {
                        // サジェストが必要な設定なら
                        if self.model.needSuggestView && self.model.longPressActions(variableStates: variableStates) == .none {
                            // 全てのサジェストを表示する
                            self.setSuggestState(.all)
                        }
                        // 長押しの予約をする。
                        self.action.reserveLongPressAction(self.model.longPressActions(variableStates: variableStates), taskStartDuration: self.longpressDuration, variableStates: variableStates)
                    }
                // 押し始めた後の変化である場合。
                case let .started(date):
                    // 押したところから25px以上離れてて、サジェストが必要な設定だったら
                    if self.model.isFlickAble(to: d, variableStates: variableStates) && startLocation.distance(to: value.location) > self.model.flickSensitivity(to: d) {
                        // サジェストの状態を一度非表示にする。
                        self.setSuggestState(nil)
                        // 一つの方向でサジェストされた状態を登録する。
                        pressState = .oneDirectionSuggested(d, Date())
                        // もしサジェストを非表示にするタスクが走っていたら、キャンセルする
                        self.suggestDismissTask?.cancel()
                        // 長押しされなかったと判断して終了する。
                        self.action.registerLongPressActionEnd(self.model.longPressActions(variableStates: variableStates))
                        // 長フリックを予約する
                        self.longFlickReserve(d)
                    }
                    // startedのまま長押し判定時間が経過した場合
                    if Date().timeIntervalSince(date) >= self.longpressDuration {
                        // 長押し状態に設定する。
                        pressState = .longPressed
                    }
                // 一方向にサジェストが表示(予定)されている状態だったら
                case let .oneDirectionSuggested(direction, startTime):
                    // 同じ方向で長押し判定時間以上フリックされていたら長フリックと判定する。
                    if Date().timeIntervalSince(startTime) >= self.longpressDuration {
                        // 長いフリックを登録する。
                        pressState = .longFlicked(direction)
                        return
                    }
                    // もし距離が閾値以上離れていて
                    if startLocation.distance(to: value.location) > self.model.flickSensitivity(to: direction) {
                        // 状態がflickでなかったら
                        if case .flick = self.getSuggestState() {} else {
                            self.setSuggestState(.flick(d))
                        }
                        // 指す方向が変わっていた場合
                        if  d != direction && self.model.isFlickAble(to: d, variableStates: variableStates) {
                            // 長フリックの予約は停止する。
                            self.longFlickEnd(direction)
                            // 新しい方向の長フリックを予約する。
                            self.longFlickReserve(d)
                            // 新しい方向へのサジェストを登録する。
                            self.setSuggestState(.flick(d))
                            // 方向を変更する。
                            pressState = .oneDirectionSuggested(d, Date())
                        }
                    }
                case .longPressed:
                    // もし距離が25px以上離れていて、サジェストが必要な設定だったら
                    if self.model.isFlickAble(to: d, variableStates: variableStates) && startLocation.distance(to: value.location) > self.model.flickSensitivity(to: d) && self.model.needSuggestView {
                        // 状態がflickでなかったら
                        if case .flick = self.getSuggestState() {} else {
                            self.setSuggestState(.flick(d))
                            // 一つの方向でサジェストされた状態を登録する。
                            pressState = .oneDirectionSuggested(d, Date())
                            // 長押しは終わりと判断して終了する。
                            self.action.registerLongPressActionEnd(self.model.longPressActions(variableStates: variableStates))
                            // 長フリックを予約する
                            self.longFlickReserve(d)
                        }
                    }
                case let .longFlicked(direction):
                    // 指す方向が変わっていた場合
                    if  d != direction && self.model.isFlickAble(to: d, variableStates: variableStates) {
                        // 実行中の長フリックを停止する。
                        self.longFlickEnd(direction)
                        // 新しい方向の長フリックを予約する。
                        self.longFlickReserve(d)
                        // 新しい方向へのサジェストを登録する。
                        self.setSuggestState(.flick(d))
                        // 方向を変更する。
                        pressState = .oneDirectionSuggested(d, Date())
                    }
                }
            }
            // タップの終了時
            .onEnded {_ in
                // サジェストを解除する
                // 少しdelayを入れることで表示がはっきりして、「フリックした感」が強まる
                self.suggestDismissTask = Task {
                    // 0.1秒だともたつき感、0.05秒だと短すぎ、という感じ
                    try await Task.sleep(nanoseconds: 0_070_000_000)
                    try Task.checkCancellation()
                    self.setSuggestState(nil)
                }
                // 押しはじめて、そのあと動きがなかった場合ここに来る。
                if case let .started(date) = pressState {
                    // 長押し判定時間以上経っていたら
                    if Date().timeIntervalSince(date) >= self.longpressDuration {
                        // 長押しと判定しておく。
                        pressState = .longPressed
                    }
                }

                // 一方向をサジェストして
                if case let .oneDirectionSuggested(direction, date) = pressState {
                    // 長押し判定時間以上経っていたら
                    if Date().timeIntervalSince(date) >= self.longpressDuration {
                        // 長フリックと判定しておく
                        pressState = .longFlicked(direction)
                    }
                }
                // 有無を言わさず終わらせる
                self.action.registerLongPressActionEnd(self.model.longPressActions(variableStates: variableStates))
                self.flickKeys().forEach {_, flickKey in
                    self.action.registerLongPressActionEnd(flickKey.longPressActions)
                }
                // 状態に基づいて、必要な変更を加える
                switch pressState {
                case .inactive:
                    break
                case .started:
                    self.action.registerActions(self.model.pressActions(variableStates: variableStates), variableStates: variableStates)
                case let .oneDirectionSuggested(direction, _):
                    if let flickKey = self.flickKeys()[direction] {
                        self.action.registerActions(flickKey.pressActions, variableStates: variableStates)
                    }
                case .longPressed:
                    break
                case let .longFlicked(direction):
                    if let flickKey = self.flickKeys()[direction], flickKey.longPressActions == .none {
                        self.action.registerActions(flickKey.pressActions, variableStates: variableStates)
                    }
                }
                pressState = .inactive
            }
    }

    private var keyBackgroundStyle: FlickKeyBackgroundStyleValue {
        if pressState.isActive() {
            return model.backgroundStyleWhenPressed(theme: theme)
        } else {
            return model.backgroundStyleWhenUnpressed(states: variableStates, theme: theme)
        }
    }

    private var keyBorderColor: Color {
        theme.borderColor.color
    }

    private var keyShadow: ShadowStyle {
        .drop(
            color: theme.keyShadow?.color.color ?? .clear,
            radius: theme.keyShadow?.radius ?? 0.0,
            x: theme.keyShadow?.x ?? 0,
            y: theme.keyShadow?.y ?? 0
        )
    }

    public var body: some View {
        let keySize = (width: size.width, height: size.height)
        RoundedRectangle(cornerRadius: 6)
            .strokeAndFill(
                fillContent: keyBackgroundStyle.color.shadow(keyShadow).blendMode(keyBackgroundStyle.blendMode),
                strokeContent: keyBorderColor,
                lineWidth: theme.borderWidth
            )
            .frame(width: keySize.width, height: keySize.height)
            .gesture(gesture)
            .overlay {
                self.label(width: keySize.width)
            }
    }

    func longFlickReserve(_ direction: FlickDirection) {
        if let flickKey = self.flickKeys()[direction] {
            self.action.reserveLongPressAction(flickKey.longPressActions, taskStartDuration: self.longpressDuration, variableStates: variableStates)
        }
    }

    func longFlickEnd(_ direction: FlickDirection) {
        if let flickKey = self.flickKeys()[direction] {
            self.action.registerLongPressActionEnd(flickKey.longPressActions)
        }
    }
}
