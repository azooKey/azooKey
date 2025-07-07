//
//  ResizingRect.swift
//  SwiftUI-Playground
//
//  Created by ensan on 2021/03/11.
//

import Foundation
import SwiftUI

@MainActor
struct ResizingRect<Extension: ApplicationSpecificKeyboardViewExtension>: View {
    typealias Position = (current: CGPoint, initial: CGPoint)
    @State private var top_left_edge: Position
    @State private var bottom_right_edge: Position
    @EnvironmentObject private var variableStates: VariableStates

    private let lineWidth: CGFloat = 6
    private let edgeRatio: CGFloat = 1 / 5
    private let edgeColor: Color = .blue

    @State private var initialPosition: CGPoint

    @Binding private var size: CGSize
    @Binding private var position: CGPoint

    private let initialSize: CGSize
    private let minimumWidth: CGFloat = 120

    init(size: Binding<CGSize>, position: Binding<CGPoint>, initialSize: CGSize) {
        self._size = size
        self._position = position
        self._initialPosition = .init(initialValue: position.wrappedValue)
        let tl = CGPoint(
            x: (2 * position.x.wrappedValue - size.width.wrappedValue + initialSize.width) / 2,
            y: (2 * position.y.wrappedValue - size.height.wrappedValue + initialSize.height) / 2
        )
        self._top_left_edge = .init(initialValue: (tl, tl))
        let br = CGPoint(
            x: (2 * position.x.wrappedValue + size.width.wrappedValue + initialSize.width) / 2,
            y: (2 * position.y.wrappedValue + size.height.wrappedValue + initialSize.height) / 2
        )
        self._bottom_right_edge = .init(initialValue: (br, br))
        self.initialSize = initialSize
    }

    func updateUserDefaults() {
        // UserDefaultsのデータを更新する
        variableStates.keyboardInternalSettingManager.update(\.oneHandedModeSetting) {value in
            value.set(layout: variableStates.keyboardLayout, orientation: variableStates.keyboardOrientation, size: size, position: position)
        }
    }

    // left < right, top < bottomとなるように修正
    func correctOrder() {
        let (left, right) = (self.top_left_edge.current.x, self.bottom_right_edge.current.x)
        (self.top_left_edge.current.x, self.bottom_right_edge.current.x) = (min(left, right), max(left, right))
        let (top, bottom) = (self.top_left_edge.current.y, self.bottom_right_edge.current.y)
        (self.top_left_edge.current.y, self.bottom_right_edge.current.y) = (min(top, bottom), max(top, bottom))
    }

    func setInitial() {
        self.initialPosition = self.position
        self.top_left_edge.initial = self.top_left_edge.current
        self.bottom_right_edge.initial = self.bottom_right_edge.current
    }

    func xGesture(target: KeyPath<Self, Binding<Position>>) -> some Gesture {
        DragGesture(minimumDistance: .zero, coordinateSpace: .global)
            .onChanged {value in
                let dx = value.location.x - value.startLocation.x
                let before = self[keyPath: target].wrappedValue.current.x
                self[keyPath: target].wrappedValue.current.x = self[keyPath: target].wrappedValue.initial.x + dx
                let width = abs(bottom_right_edge.current.x - top_left_edge.current.x)
                let px = (top_left_edge.current.x + bottom_right_edge.current.x - initialSize.width) / 2
                if width < minimumWidth || px < -initialSize.width / 2 || px > initialSize.width / 2 {
                    self[keyPath: target].wrappedValue.current.x = before
                } else {
                    self.size.width = width
                    self.position.x = px
                }
            }
            .onEnded {_ in
                self.correctOrder()
                self.setInitial()
                self.updateUserDefaults()
            }
    }

    func yGesture(target: KeyPath<Self, Binding<Position>>, isTopHandle: Bool) -> some Gesture {
        DragGesture(minimumDistance: .zero, coordinateSpace: .global)
            .onChanged { value in
                let dy = value.location.y - value.startLocation.y
                // ドラッグ前の Y 値を記憶
                let beforeY = self[keyPath: target].wrappedValue.current.y
                // 仮セット
                self[keyPath: target].wrappedValue.current.y = self[keyPath: target].wrappedValue.initial.y + dy

                // エッジ位置と新しい高さを計算
                let topY    = top_left_edge.current.y
                let bottomY = bottom_right_edge.current.y
                let newHeight = abs(bottomY - topY)

                // 縮小禁止（下端ハンドルの場合）
                let isShrinkOnBottom = !isTopHandle && newHeight < size.height
                // 最小・最大を超えたらキャンセル
                let isTooShort = newHeight < Design.keyboardHeight(screenWidth: SemiStaticStates.shared.screenWidth, orientation: variableStates.keyboardOrientation) / 2
                let isTooTall  = newHeight > variableStates.maximumHeight

                if isTooShort || isTooTall || isShrinkOnBottom {
                    // 範囲外なら元に戻す
                    self[keyPath: target].wrappedValue.current.y = beforeY
                } else {
                    // 有効範囲内なら適用
                    self.size.height   = newHeight
                    // centerY 再計算（initialSizeは元の高さ）
                    self.position.y    = (topY + bottomY - initialSize.height) / 2
                }
            }
            .onEnded { _ in
                self.correctOrder()
                self.setInitial()
                self.updateUserDefaults()
            }
    }

    var body: some View {
        ZStack {
            Path {path in
                for i in 0..<4 {
                    let x = size.width / 24 * CGFloat(i)
                    let ratio = (1 - CGFloat(i) / 4) * 0.8
                    path.move(to: CGPoint(x: x, y: size.height / 2 - size.height * edgeRatio * ratio))
                    path.addLine(to: CGPoint(x: x, y: size.height / 2 + size.height * edgeRatio * ratio))
                }
            }
            .stroke(Color.white, lineWidth: 3)
            .gesture(xGesture(target: \.$top_left_edge))
            Path {path in
                for i in 0..<4 {
                    let y = size.height / 24 * CGFloat(i)
                    let ratio = (1 - CGFloat(i) / 4) * 0.8
                    path.move(to: CGPoint(x: size.width / 2 - size.width * edgeRatio * ratio, y: y))
                    path.addLine(to: CGPoint(x: size.width / 2 + size.width * edgeRatio * ratio, y: y))
                }
            }
            .stroke(Color.white, lineWidth: 3)
            .gesture(yGesture(target: \.$top_left_edge, isTopHandle: true))
            Path {path in
                for i in 0..<4 {
                    let x = size.width - size.width / 24 * CGFloat(i)
                    let ratio = (1 - CGFloat(i) / 4) * 0.8
                    path.move(to: CGPoint(x: x, y: size.height / 2 - size.height * edgeRatio * ratio))
                    path.addLine(to: CGPoint(x: x, y: size.height / 2 + size.height * edgeRatio * ratio))
                }
            }
            .stroke(Color.white, lineWidth: 3)
            .gesture(xGesture(target: \.$bottom_right_edge))
            HStack {
                let cur = min(size.width, size.height) * 0.22
                let max = min(initialSize.width, initialSize.height) * 0.22
                let r = min(cur, max)
                Button {
                    KeyboardFeedback<Extension>.reset()
                    variableStates.keyboardInternalSettingManager.update(\.oneHandedModeSetting) {value in
                        value.setUserHasOverwrittenKeyboardHeightSetting(layout: variableStates.keyboardLayout, orientation: variableStates.keyboardOrientation)
                    }
                    withAnimation(.interactiveSpring()) {
                        variableStates.resetOneHandedModeSetting()
                        variableStates.heightScaleFromKeyboardHeightSetting = 1
                    }
                } label: {
                    Circle()
                        .fill(Color.red)
                        .frame(width: r, height: r)
                        .overlay {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundStyle(.white)
                                .font(Font.system(size: r * 0.5))
                        }
                }
                Button {
                    if self.position == .zero && self.size == self.initialSize {
                        variableStates.setResizingMode(.fullwidth)
                    } else {
                        variableStates.setResizingMode(.onehanded)
                    }
                    variableStates.heightScaleFromKeyboardHeightSetting = 1
                    variableStates.keyboardInternalSettingManager.update(\.oneHandedModeSetting) {value in
                        value.setUserHasOverwrittenKeyboardHeightSetting(layout: variableStates.keyboardLayout, orientation: variableStates.keyboardOrientation)
                    }
                } label: {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: r, height: r)
                        .overlay {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.white)
                                .font(Font.system(size: r * 0.5))
                        }
                }
                Button {
                    let screenWidth = UIScreen.main.bounds.width
                    let orientation = variableStates.keyboardOrientation
                    let baseline = Design
                        .keyboardHeight(screenWidth: screenWidth,
                                        orientation: orientation) * 2
                        + Design.keyboardScreenBottomPadding * 2

                    variableStates.maximumHeight = min(
                        variableStates.maximumHeight + 64, baseline
                    )
                } label: {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: r, height: r)
                        .overlay {
                            Image(systemName: "arrow.up.to.line.compact")
                                .foregroundStyle(.white)
                                .font(.system(size: r * 0.5))
                        }
                }
            }
        }
    }
}

@MainActor
struct ResizingBindingFrame<Extension: ApplicationSpecificKeyboardViewExtension>: ViewModifier {
    private let initialSize: CGSize
    @Binding private var position: CGPoint
    @Binding private var size: CGSize
    @EnvironmentObject private var variableStates: VariableStates
    private var hideResetButtonInOneHandedMode: Bool {
        Extension.SettingProvider.hideResetButtonInOneHandedMode
    }
    init(size: Binding<CGSize>, position: Binding<CGPoint>, initialSize: CGSize) {
        self.initialSize = initialSize
        self._size = size
        self._position = position
    }

    private var isAtDefaultWidth: Bool {
        // 浮動小数点数の計算誤差を考慮し、0.1ポイント未満の差は「同じ」と見なします
        self.size.width.isApproximatelyEqual(to: self.initialSize.width, absoluteTolerance: 0.1)
    }

    @ViewBuilder
    private func editButtons(availableWidth: CGFloat, availableHeight: CGFloat) -> some View {
        // --- 1. ボタンサイズの計算 ---
        let spacing: CGFloat = 7.0
        let numberOfButtons: CGFloat = 4.0
        let UIMaxButtonDiameter: CGFloat = 48.0

        // 縦方向と横方向、両方にはみ出さない直径(r)を計算
        let rFromHeight = (availableHeight - spacing * (numberOfButtons - 1)) / numberOfButtons
        let fittableRFromWidth = availableWidth - 8 // 左右の端から少し余白をとる
        let fittableR = max(0, min(rFromHeight, fittableRFromWidth))

        let r = min(fittableR, UIMaxButtonDiameter) * 0.9

        // 計算の結果、ボタンがタップできる十分な大きさを持つ場合のみ表示する
        if r >= 16 {
            // 上下にSpacerを持つコンテナVStackを追加し、垂直中央揃えを強制する
            VStack {
                Spacer()
                // 元々のボタンをまとめたVStack
                VStack(spacing: spacing) {
                    let button1 = Button {
                        variableStates.setResizingMode(.resizing)
                        variableStates.heightScaleFromKeyboardHeightSetting = 1
                    } label: {
                        Circle().fill(Color.blue)
                            .overlay {
                                Image(systemName: "aspectratio").foregroundStyle(.white).font(.system(size: r * 0.5))
                            }
                    }
                    .frame(width: r, height: r)
                    .contentShape(Circle())

                    let button2 = Button {
                        variableStates.setResizingMode(.fullwidth)
                        variableStates.heightScaleFromKeyboardHeightSetting = 1
                    } label: {
                        Circle().fill(Color.blue)
                            .overlay {
                                Image(systemName: "arrow.up.backward.and.arrow.down.forward").foregroundStyle(.white).font(.system(size: r * 0.5))
                            }
                    }
                    .frame(width: r, height: r)
                    .contentShape(Circle())

                    let button3 = Button {
                        KeyboardFeedback<Extension>.reset()
                        withAnimation(.interactiveSpring()) {
                            self.position = .zero
                            self.size = initialSize
                            variableStates.setResizingMode(.fullwidth)
                        }
                        variableStates.heightScaleFromKeyboardHeightSetting = 1
                        variableStates.keyboardInternalSettingManager.update(\.oneHandedModeSetting) {value in
                            value.set(layout: variableStates.keyboardLayout, orientation: variableStates.keyboardOrientation, size: initialSize, position: .zero)
                        }
                    } label: {
                        Circle().fill(Color.red)
                            .overlay {
                                Image(systemName: "arrow.triangle.2.circlepath").foregroundStyle(.white).font(.system(size: r * 0.5))
                            }
                    }
                    .frame(width: r, height: r)
                    .contentShape(Circle())

                    button1
                    button2
                    button3
                }
                Spacer()
            }
        }
    }

    func body(content: Content) -> some View {
        switch variableStates.resizingState {
        case .onehanded:
            // 親Viewに対して、そのサイズを教えてくれるGeometryReaderを重ねる
            content
                .frame(width: size.width, height: size.height)
                .offset(x: position.x, y: 0)
                .overlay {
                    if !hideResetButtonInOneHandedMode && !isAtDefaultWidth {
                        // GeometryReaderが親のサイズ(initialSize)を正確に教えてくれる
                        GeometryReader { geo in
                            // --- 親を基準としたレイアウト計算 ---
                            let leftMargin = position.x + geo.size.width / 2 - size.width / 2
                            let rightMargin = geo.size.width / 2 - position.x - size.width / 2

                            // 左右の広い方のマージンにボタンを配置
                            if leftMargin >= rightMargin {
                                // 左側に配置
                                HStack {
                                    editButtons(availableWidth: leftMargin, availableHeight: geo.size.height)
                                    Spacer()
                                }
                            } else {
                                // 右側に配置
                                HStack {
                                    Spacer()
                                    editButtons(availableWidth: rightMargin, availableHeight: geo.size.height)
                                }
                            }
                        }
                    }
                }

        case .fullwidth:
            content
        case .resizing:
            let maximumHeight = variableStates.maximumHeight
            let height = variableStates.interfaceSize.height
            let offSet = (maximumHeight - height) / 2
            ZStack {
                content
                Rectangle()
                    .fill(Color.black.opacity(0.2))
                    .frame(width: size.width, height: size.height)
            }
            .disabled(true)
            .overlay {
                ResizingRect<Extension>(size: $size, position: $position, initialSize: initialSize)
            }
            .frame(width: size.width, height: size.height)
            .offset(x: position.x, y: offSet)
        }
    }
}

extension View {
    @MainActor func resizingFrame<Extension: ApplicationSpecificKeyboardViewExtension>(size: Binding<CGSize>, position: Binding<CGPoint>, initialSize: CGSize, extension: Extension.Type) -> some View {
        self.modifier(ResizingBindingFrame<Extension>(size: size, position: position, initialSize: initialSize))
    }
}
