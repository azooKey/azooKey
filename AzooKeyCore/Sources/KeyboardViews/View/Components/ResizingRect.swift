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
    private let minimumHeight: CGFloat = 120

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

    func gesture(x: KeyPath<Self, Binding<Position>>, y: KeyPath<Self, Binding<Position>>, top: Bool = true, left: Bool = true) -> some Gesture {
        DragGesture(minimumDistance: .zero, coordinateSpace: .global)
            .onChanged {value in
                let dx = value.location.x - value.startLocation.x
                let dy = value.location.y - value.startLocation.y
                self[keyPath: x].wrappedValue.current.x = self[keyPath: x].wrappedValue.initial.x + dx
                self[keyPath: y].wrappedValue.current.y = self[keyPath: y].wrappedValue.initial.y + dy
                size.width = abs(bottom_right_edge.current.x - top_left_edge.current.x)
                size.height = abs(bottom_right_edge.current.y - top_left_edge.current.y)
                position.x = (top_left_edge.current.x + bottom_right_edge.current.x - initialSize.width) / 2
                position.y = (top_left_edge.current.y + bottom_right_edge.current.y - initialSize.height) / 2
            }
            .onEnded {_ in
                self.correctOrder()
                self.setInitial()
                self.updateUserDefaults()
            }
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
            .onChanged {value in
                let dy = value.location.y - value.startLocation.y
                // 変更前のY座標を保持
                let before_y = self[keyPath: target].wrappedValue.current.y
                // 新しいY座標を一旦計算
                self[keyPath: target].wrappedValue.current.y = self[keyPath: target].wrappedValue.initial.y + dy

                // 新しい高さと中心位置を計算
                let newHeight = abs(bottom_right_edge.current.y - top_left_edge.current.y)
                let new_py = (top_left_edge.current.y + bottom_right_edge.current.y - initialSize.height) / 2

                // 以下のいずれかの条件に合致する場合、変更を無効にする
                // [修正点 1/2]新しい高さが、定義した最小値を下回った場合
                let isTooShort = newHeight < self.minimumHeight
                // 2. 操作対象が上ハンドルで、かつ新しい高さがデフォルトの高さを超えた場合
                let isTooTall = isTopHandle && newHeight > self.initialSize.height
                // 3. キーボード全体が描画領域外に出てしまう場合
                let isOutOfBounds = new_py < -initialSize.height / 2 || new_py > initialSize.height / 2

                // isTooShort をチェック条件に追加
                if isTooShort || isTooTall || isOutOfBounds {
                    // 条件に合致した場合、Y座標をドラッグ前の値に戻す
                    self[keyPath: target].wrappedValue.current.y = before_y
                } else {
                    // 条件に合わなければ、計算結果を適用する
                    self.size.height = newHeight
                    self.position.y = new_py
                }
            }
            .onEnded {_ in
                self.correctOrder()
                self.setInitial()
                self.updateUserDefaults()
            }
    }

    var moveGesture: some Gesture {
        DragGesture(minimumDistance: .zero, coordinateSpace: .global)
            .onChanged {value in
                let dx = value.location.x - value.startLocation.x
                let dy = value.location.y - value.startLocation.y
                let px = self.initialPosition.x + dx
                let py = self.initialPosition.y + dy
                if  -initialSize.width / 2 < px && px < initialSize.width / 2 &&
                        -initialSize.height / 2 < py && py < initialSize.height / 2 {
                    withAnimation(.interactiveSpring()) {
                        self.position.x = px
                        self.position.y = py
                        self.top_left_edge.current.x = self.top_left_edge.initial.x + dx
                        self.top_left_edge.current.y = self.top_left_edge.initial.y + dy
                        self.bottom_right_edge.current.x = self.bottom_right_edge.initial.x + dx
                        self.bottom_right_edge.current.y = self.bottom_right_edge.initial.y + dy
                    }
                }
            }
            .onEnded {_ in
                self.setInitial()
                self.updateUserDefaults()
            }
    }

    var body: some View {
        ZStack {
            /*
             Path{path in
             path.move(to: CGPoint(x: 0, y: height * edgeRatio))
             path.addLine(to: CGPoint(x: 0, y: 0))
             path.addLine(to: CGPoint(x: width * edgeRatio, y: 0))
             }.stroke(edgeColor, lineWidth: lineWidth)
             .gesture(gesture(x: \.$top_left_edge.x, y: \.$top_left_edge.y))
             Path{path in
             path.move(to: CGPoint(x: width, y: height * edgeRatio))
             path.addLine(to: CGPoint(x: width, y: 0))
             path.addLine(to: CGPoint(x: width * (1-edgeRatio), y: 0))
             }.stroke(edgeColor, lineWidth: lineWidth)
             .gesture(gesture(x: \.$bottom_right_edge.x, y: \.$top_left_edge.y, left: false))
             Path{path in
             path.move(to: CGPoint(x: 0, y: height * (1-edgeRatio)))
             path.addLine(to: CGPoint(x: 0, y: height))
             path.addLine(to: CGPoint(x: width * edgeRatio, y: height))
             }.stroke(edgeColor, lineWidth: lineWidth)
             .gesture(gesture(x: \.$top_left_edge.x, y: \.$bottom_right_edge.y, top: false))
             Path{path in
             path.move(to: CGPoint(x: width, y: height * (1-edgeRatio)))
             path.addLine(to: CGPoint(x: width, y: height))
             path.addLine(to: CGPoint(x: width * (1-edgeRatio), y: height))
             }.stroke(edgeColor, lineWidth: lineWidth)
             .gesture(gesture(x: \.$bottom_right_edge.x, y: \.$bottom_right_edge.y, top: false, left: false))
             */
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
            .gesture(yGesture(target: \.$top_left_edge,isTopHandle: true))
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
            /*
             Path{path in
             for i in 0..<4{
             let y = height - height / 24 * CGFloat(i)
             let ratio = (1 - CGFloat(i) / 4) * 0.8
             path.move(to: CGPoint(x: width / 2 - width * edgeRatio * ratio, y: y))
             path.addLine(to: CGPoint(x: width / 2 + width * edgeRatio * ratio, y: y))
             }
             }.stroke(Color.white, lineWidth: 3)
             .gesture(yGesture(y: \.$bottom_right_edge.y, top: false))
             */
            HStack {
                let cur = min(size.width, size.height) * 0.22
                let max = min(initialSize.width, initialSize.height) * 0.22
                let r = min(cur, max)
                Circle()
                    .fill(Color.blue)
                    .frame(width: r, height: r)
                    .overlay {
                        Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                            .foregroundStyle(.white)
                            .font(Font.system(size: r * 0.5))
                    }
                    .gesture(moveGesture)
                Button {
                    KeyboardFeedback<Extension>.reset()
                    withAnimation(.interactiveSpring()) {
                        variableStates.resetOneHandedModeSetting()
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
        return abs(self.size.width - self.initialSize.width) < 0.1
    }

    private enum HV {
        case H, V
    }
    private var editButtonData: (max: CGFloat, position: CGPoint, stack: HV) {
        let leftMargin = position.x + initialSize.width / 2 - size.width / 2
        let rightMargin = initialSize.width / 2 - position.x - size.width / 2
        let topMargin = position.y + initialSize.height / 2 - size.height / 2
        let bottomMargin = initialSize.height / 2 - position.y - size.height / 2
        let maxMargin = max(leftMargin, rightMargin, topMargin, bottomMargin)
        let position: CGPoint
        let stack: HV
        if leftMargin == maxMargin {
            position = .init(x: maxMargin / 2, y: initialSize.height / 2)
            stack = .V
        } else if rightMargin == maxMargin {
            position = .init(x: initialSize.width - maxMargin / 2, y: initialSize.height / 2)
            stack = .V
        } else if topMargin == maxMargin {
            position = .init(x: initialSize.width / 2, y: maxMargin / 2)
            stack = .H
        } else {
            position = .init(x: initialSize.width / 2, y: initialSize.height - maxMargin / 2)
            stack = .H
        }
        return (maxMargin, position, stack)
    }

    @ViewBuilder func editButton() -> some View {
        let data = self.editButtonData
        if data.max >= 30 {
            let max = min(initialSize.width, initialSize.height) * 0.15
            let r = min(data.max * 0.7, max)
            let button1 = Button {
                variableStates.setResizingMode(.resizing)
            } label: {
                Circle()
                    .fill(Color.blue)
                    .frame(width: r, height: r)
                    .overlay {
                        Image(systemName: "aspectratio")
                            .foregroundStyle(.white)
                            .font(Font.system(size: r * 0.5))
                    }
            }
            .frame(width: r, height: r)

            let button2 = Button {
                variableStates.setResizingMode(.fullwidth)
            } label: {
                Circle()
                    .fill(Color.blue)
                    .frame(width: r, height: r)
                    .overlay {
                        Image(systemName: "arrow.up.backward.and.arrow.down.forward")
                            .foregroundStyle(.white)
                            .font(Font.system(size: r * 0.5))
                    }
            }
            .frame(width: r, height: r)

            let button3 = Button {
                KeyboardFeedback<Extension>.reset()
                withAnimation(.interactiveSpring()) {
                    self.position = .zero
                    self.size.width = initialSize.width
                    self.size.height = initialSize.height
                    variableStates.setResizingMode(.fullwidth)
                }
                variableStates.keyboardInternalSettingManager.update(\.oneHandedModeSetting) {value in
                    value.set(layout: variableStates.keyboardLayout, orientation: variableStates.keyboardOrientation, size: initialSize, position: .zero)
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

            switch data.stack {
            case .H:
                HStack {
                    button1
                    button2
                    button3
                }
                .position(x: data.position.x, y: data.position.y)
            case .V:
                VStack {
                    button1
                    button2
                    button3
                }
                .position(x: data.position.x, y: data.position.y)
            }

        }
    }

    @ViewBuilder func body(content: Content) -> some View {
        switch variableStates.resizingState {
        case .onehanded:
            if !hideResetButtonInOneHandedMode && !isAtDefaultWidth {
                editButton()
            }
            let userScreenHeight = Design.keyboardHeight(
                screenWidth: SemiStaticStates.shared.screenWidth,
                orientation: variableStates.keyboardOrientation
            )
            content
                .frame(width: size.width, height: userScreenHeight)
                .offset(x: position.x, y: position.y)
        case .fullwidth:
            content
        case .resizing:
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
            .offset(x: position.x, y: position.y)
        }
    }
}

extension View {
    @MainActor func resizingFrame<Extension: ApplicationSpecificKeyboardViewExtension>(size: Binding<CGSize>, position: Binding<CGPoint>, initialSize: CGSize, extension: Extension.Type) -> some View {
        self.modifier(ResizingBindingFrame<Extension>(size: size, position: position, initialSize: initialSize))
    }
}
