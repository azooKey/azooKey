//
//  ReflectStyleCursorBar.swift
//
//
//  Created by miwa on 2023/09/30.
//

import Foundation
import SwiftUI
import SwiftUIUtils
import SwiftUtils

private struct CursorBarState: Equatable, Hashable, Sendable {
    private(set) var displayLeftIndex = 0
    private(set) var displayRightIndex = 0
    fileprivate var line: [String] = []

    private var itemCount: Int = 0
    mutating func updateItemCount(viewWidth: CGFloat, itemWidth: CGFloat) {
        self.itemCount = (Int(viewWidth / itemWidth) >> 1) << 1
    }

    fileprivate var centerIndex: Int {
        displayLeftIndex + itemCount / 2
    }

    mutating func updateLine(leftText: String, rightText: String) {
        debug("CursorBarState.updateLine", leftText, rightText, itemCount, line)
        var left = leftText.map {String($0)}
        if let index = left.firstIndex(of: "\n"), index != left.endIndex - 1 {
            left.removeFirst(index + 1)
        }
        self.line = left + rightText.map {String($0)} + ["⏎"]
        self.displayLeftIndex = left.count - itemCount / 2
        self.displayRightIndex = self.displayLeftIndex + itemCount
    }

    fileprivate func getItem(at index: Int) -> String {
        if index < 0 || line.count <= index {
            return ""
        }
        return line[index]
    }

    @MainActor mutating fileprivate func move(_ count: Int, actionManager: some UserActionManager, variableStates: VariableStates) {
        if centerIndex + count < -1 || line.count < centerIndex + count {
            debug("CursorBarState.move rejected", centerIndex, count, line)
            return
        }
        displayLeftIndex += count
        displayRightIndex += count
        actionManager.registerAction(.moveCursor(count), variableStates: variableStates)
    }

    @MainActor mutating fileprivate func tap(at index: Int, actionManager: some UserActionManager, variableStates: VariableStates) {
        let diff: Int
        if index < 0 {
            diff = -1
        } else if line.count <= index {
            diff = 1
        } else {
            diff = index - centerIndex
        }
        move(diff, actionManager: actionManager, variableStates: variableStates)
    }

    mutating func clear() {
        self.displayLeftIndex = 0
        self.displayRightIndex = 0
        self.line = []
    }
}

struct ReflectStyleCursorBar<Extension: ApplicationSpecificKeyboardViewExtension>: View {
    init() {}

    @EnvironmentObject private var variableStates: VariableStates
    @Environment(Extension.Theme.self) private var theme
    @Environment(\.userActionManager) private var action

    private enum SwipeGestureState {
        case inactive
        case tap(l1: CGPoint, l2: CGPoint, l3: CGPoint)
        case moving(l1: CGPoint, l2: CGPoint, l3: CGPoint, count: Double)
    }
    @State private var swipeGestureState: SwipeGestureState = .inactive
    @State private var cursorBarState = CursorBarState()
    @State private var longPressTask: Task<(), any Error>?

    @MainActor
    private var fontSize: CGFloat {
        Design.fonts.resultViewFontSize(userPrefrerence: Extension.SettingProvider.resultViewFontSize)
    }

    @MainActor
    fileprivate var itemWidth: CGFloat {
        fontSize * 1.3
    }

    @MainActor
    fileprivate var viewWidth: CGFloat {
        variableStates.interfaceSize.width * 0.85
    }

    @MainActor
    var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged {value in
                switch swipeGestureState {
                case .inactive:
                    swipeGestureState = .tap(l1: value.location, l2: value.location, l3: value.location)
                case let .tap(l1, l2, _):
                    let d = value.startLocation.distance(to: value.location)
                    if d > 20 {
                        swipeGestureState = .moving(l1: value.location, l2: l1, l3: l2, count: 0)
                    } else {
                        swipeGestureState = .tap(l1: value.location, l2: l1, l3: l2)
                    }
                case let .moving(l1, l2, l3, count):
                    var direction = 0
                    var count = count
                    // directionを多数決で決定する
                    if value.location.x - l1.x > 0 {
                        direction -= 1
                    } else {
                        direction += 1
                    }
                    if l1.x - l2.x > 0 {
                        direction -= 1
                    } else {
                        direction += 1
                    }
                    if l2.x - l3.x > 0 {
                        direction -= 1
                    } else {
                        direction += 1
                    }
                    // countの更新
                    if direction > 0 && value.location.x < l3.x {
                        count += (Double(direction) / 3) * (l3.x - value.location.x) / 3
                    } else if direction < 0 && value.location.x > l3.x {
                        count -= (Double(direction) / 3) * (l3.x - value.location.x) / 3
                    }
                    withAnimation(.linear(duration: 0.05)) {
                        if count >= 15 {
                            cursorBarState.move(1, actionManager: self.action, variableStates: variableStates)
                            count -= 15
                        }
                        if count <= -15 {
                            cursorBarState.move(-1, actionManager: self.action, variableStates: variableStates)
                            count += 15
                        }
                        swipeGestureState = .moving(l1: value.location, l2: l1, l3: l2, count: count)
                    }
                }
            }
            .onEnded {value in
                switch swipeGestureState {
                case .inactive:
                    break
                case .tap:
                    // offsetを計算する
                    // タップした位置を理解する
                    // 左端がx=0の座標系で考える。
                    let center_x = variableStates.interfacePosition.x + variableStates.containerWidth / 2
                    let x = value.startLocation.x
                    // あpい|う え
                    // pの位置をタップした場合、このdiffは-1*itemWidthに近い値になる
                    let diff_from_center = x - center_x
                    let offset_double = diff_from_center / itemWidth
                    // center indexからのoffsetになる
                    let offset = Int(offset_double.rounded(.toNearestOrAwayFromZero))
                    let index = cursorBarState.centerIndex + offset
                    withAnimation(.easeOut(duration: 0.1)) {
                        cursorBarState.tap(at: index, actionManager: self.action, variableStates: variableStates)
                    }
                case .moving:
                    // 位置を揃える
                    break
                }
                swipeGestureState = .inactive
            }
    }

    private var centerColor: Color {
        theme.pushedKeyFillColor.color
    }

    private var edgeColor: Color {
        theme.backgroundColor.color
    }

    private var symbolsFontWeight: Font.Weight {
        theme.textFont.weight
    }

    private var symbolsColor: Color {
        theme.resultTextColor.color
    }

    @MainActor
    private var background: some View {
        RadialGradient(gradient: Gradient(colors: [centerColor, edgeColor]), center: .center, startRadius: 1, endRadius: viewWidth / 2)
            .cornerRadius(20)
            .gesture(swipeGesture)
    }

    private func symbolFont(size: CGFloat) -> Font {
        .system(size: size, weight: symbolsFontWeight, design: .default)
    }

    @MainActor
    private var textView: some View {
        HStack(spacing: .zero) {
            // 多めに描画しておく
            ForEach(cursorBarState.displayLeftIndex - 4 ..< cursorBarState.displayRightIndex + 4, id: \.self) { i in
                let item = cursorBarState.getItem(at: i)
                let hash = {
                    var hasher = Hasher()
                    hasher.combine(i)
                    hasher.combine(item)
                    return hasher.finalize()
                }()
                Text(verbatim: item)
                    .font(.system(size: fontSize).bold())
                    .frame(width: itemWidth)
                    .id(hash)
            }
        }
        .allowsHitTesting(false)
        .foregroundStyle(theme.resultTextColor.color.opacity(0.4))
        .frame(width: viewWidth)
        .clipped()
    }

    @MainActor
    private var foregroundButtons: some View {
        ZStack(alignment: .center) {
            textView
            HStack(spacing: .zero) {
                Image(systemName: "chevron.left.2")
                    .font(symbolFont(size: 18))
                    .foregroundStyle(symbolsColor)
                    .padding()
                    .overlay {
                        TouchDownAndTouchUpGestureView {
                            self.startLongPress(offset: -1)
                        } touchMovedCallBack: { state in
                            if state.distance > 20 { // 20以上動いたらダメ
                                self.longPressTask?.cancel()
                                debug("touch failed")
                            }
                        } touchUpCallBack: { gestureState in
                            //                            self.action.registerLongPressActionEnd(.init(start: [], repeat: [.moveCursor(-1)]))
                            self.longPressTask?.cancel()
                            if gestureState.time < 0.4 {
                                withAnimation(.linear(duration: 0.15)) {
                                    cursorBarState.move(-1, actionManager: self.action, variableStates: variableStates)
                                }
                                KeyboardFeedback<Extension>.tabOrOtherKey()
                            }
                        }
                    }
                Spacer()
                Text(verbatim: "│")
                    .font(.system(size: fontSize + 4))
                    .foregroundStyle(symbolsColor)
                    .allowsHitTesting(false)
                Spacer()
                Image(systemName: "chevron.right.2")
                    .font(symbolFont(size: 18))
                    .foregroundStyle(symbolsColor)
                    .padding()
                    .overlay {
                        TouchDownAndTouchUpGestureView {
                            self.startLongPress(offset: 1)
                        } touchMovedCallBack: { state in
                            if state.distance > 20 { // 20以上動いたらダメ
                                self.longPressTask?.cancel()
                                debug("touch failed")
                            }
                        } touchUpCallBack: { gestureState in
                            self.longPressTask?.cancel()
                            if gestureState.time < 0.4 {
                                withAnimation(.linear(duration: 0.15)) {
                                    cursorBarState.move(1, actionManager: self.action, variableStates: variableStates)
                                }
                                KeyboardFeedback<Extension>.tabOrOtherKey()
                            }
                        }
                    }
            }
        }
    }

    var body: some View {
        background
            .overlay {
                foregroundButtons
            }
            .onAppear {
                cursorBarState.updateItemCount(viewWidth: viewWidth, itemWidth: itemWidth)
                let surroundingText = variableStates.surroundingText
                cursorBarState.updateLine(leftText: surroundingText.leftSideText + surroundingText.centerText, rightText: surroundingText.rightSideText)
            }
            .onChange(of: variableStates.surroundingText) { (_, newValue) in
                withAnimation(.easeOut(duration: 0.1)) {
                    cursorBarState.updateLine(leftText: newValue.leftSideText + newValue.centerText, rightText: newValue.rightSideText)
                }
            }
    }

    @MainActor
    private func startLongPress(offset: Int) {
        self.longPressTask = Task {
            // 0.4秒待つ
            try await Task.sleep(nanoseconds: 0_400_000_000)
            while !Task.isCancelled {
                withAnimation(.linear(duration: 0.05)) {
                    cursorBarState.move(offset, actionManager: self.action, variableStates: variableStates)
                }
                KeyboardFeedback<Extension>.tabOrOtherKey()
                try await Task.sleep(nanoseconds: 0_100_000_000)
            }
        }
    }
}
