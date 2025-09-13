import CustardKit
import Foundation
import SwiftUI
import KeyboardThemes

// Unified press lifecycle to support both Flick and Linear interactions (scaffolding)
private struct PressLifecycle: Sendable {
    enum Mode {
        case none
        case flick
        case linear
    }
    enum State: Equatable, Sendable {
        case idle
        case started(Date)
        case longPressed
        // Flick-specific
        case flickOneSuggested(FlickDirection, Date)
        case longFlicked(FlickDirection)
        // Linear-specific
        case linearVariations(selection: Int?)

        var isActive: Bool {
            switch self {
            case .idle: false
            default: true
            }
        }
    }

    // Double-press tracker used by linear keys
    struct DoublePressTracker: Sendable {
        private var lastDown: Date?
        private var lastUp: Date?
        private(set) var secondPressCompleted: Bool = false
        mutating func update(touchDownDate: Date) {
            if let up = lastUp, touchDownDate.timeIntervalSince(up) < 0.3 {
                /* wait for up */
            }
            lastDown = touchDownDate
        }
        mutating func update(touchUpDate: Date) {
            if let down = lastDown, touchUpDate.timeIntervalSince(down) < 0.3 {
                if let prevUp = lastUp, down.timeIntervalSince(prevUp) < 0.3 {
                    secondPressCompleted = true
                }
            }
            lastUp = touchUpDate
        }
        mutating func reset() {
            lastDown = nil
            lastUp = nil
            secondPressCompleted = false
        }
    }

    var mode: Mode = .none
    var state: State = .idle

    // Common scheduling
    var longPressTask: Task<Void, Never>?
    // Flick scheduling
    var flickAllSuggestTask: Task<Void, Never>?
    var flickSuggestDismissTask: Task<Void, Never>?

    // Pointers
    var flickStartLocation: CGPoint?
    var flickLastUpdate: (direction: FlickDirection, date: Date)?
    var doublePress = DoublePressTracker()

    mutating func reset(cancelTasks: Bool = true, preserveDoublePress: Bool = false) {
        if cancelTasks {
            longPressTask?.cancel()
            longPressTask = nil

            flickAllSuggestTask?.cancel()
            flickAllSuggestTask = nil

            flickSuggestDismissTask?.cancel()
            flickSuggestDismissTask = nil
        }
        state = .idle
        mode = .none
        flickStartLocation = nil
        flickLastUpdate = nil
        if !preserveDoublePress {
            doublePress.reset()
        }
    }
}

@MainActor
public struct UnifiedGenericKeyView<Extension: ApplicationSpecificKeyboardViewExtension>: View {
    // GestureSet expresses which gesture system this key supports,
    // independent of layout naming.
    public enum GestureSet {
        case directionalFlick
        case linearVariation
    }
    private let model: any UnifiedKeyModelProtocol<Extension>
    private let tabDesign: TabDependentDesign
    private let size: CGSize
    @Binding private var isSuggesting: Bool
    // サジェストの種類（View側の表示用）
    @State private var flickSuggestType: FlickSuggestType?
    @State private var qwertySuggestType: QwertySuggestType?

    @EnvironmentObject private var variableStates: VariableStates
    @Environment(Extension.Theme.self) private var theme
    @Environment(\.userActionManager) private var action

    private let gestureSet: GestureSet

    public init(model: any UnifiedKeyModelProtocol<Extension>, tabDesign: TabDependentDesign, size: CGSize, gestureSet: GestureSet, isSuggesting: Binding<Bool>) {
        self.model = model
        self.tabDesign = tabDesign
        self.size = size
        self.gestureSet = gestureSet
        self._isSuggesting = isSuggesting
    }

    // Step 1: introduce unified lifecycle state (not yet wired)
    @State private var lifecycle = PressLifecycle()

    private var longpressDuration: TimeInterval {
        switch self.model.longPressActions(variableStates: variableStates).duration {
        case .light: 0.125
        case .normal: 0.400
        }
    }

    private func longpressDuration(_ action: LongpressActionType) -> TimeInterval {
        switch action.duration {
        case .light: 0.125
        case .normal: 0.400
        }
    }

    private func variation(for direction: FlickDirection) -> UnifiedVariation? {
        if case let .fourWay(map) = model.variationSpace(variableStates: variableStates) {
            return map[direction]
        }
        return nil
    }

    // MARK: FourWay (Flick) gesture
    private var flickGesture: some Gesture {
        DragGesture(minimumDistance: .zero, coordinateSpace: .global)
            .onChanged { value in
                guard gestureSet == .directionalFlick else { return }
                if lifecycle.mode == .none {
                    lifecycle.mode = .flick
                }
                let startLocation = self.lifecycle.flickStartLocation ?? value.startLocation
                let d = startLocation.direction(to: value.location)
                switch lifecycle.state {
                case .idle:
                    // 開始時にタスク/状態を整理
                    self.lifecycle.flickSuggestDismissTask?.cancel()
                    self.lifecycle.flickAllSuggestTask?.cancel()
                    self.flickSuggestType = nil
                    self.isSuggesting = false
                    // Flickでも必要に応じて単押しバブルを表示する
                    if self.model.showsTapBubble(variableStates: variableStates) {
                        self.qwertySuggestType = .normal
                        self.isSuggesting = true
                    } else {
                        self.qwertySuggestType = nil
                    }
                    self.lifecycle.flickLastUpdate = nil
                    self.lifecycle.state = .started(Date())
                    self.lifecycle.flickStartLocation = value.startLocation
                    // フィードバック/長押し予約
                    self.model.feedback(variableStates: variableStates)
                    let longpressActions = self.model.longPressActions(variableStates: variableStates)
                    self.action.reserveLongPressAction(longpressActions, taskStartDuration: self.longpressDuration, variableStates: variableStates)
                    // 全サジェスト（一定時間後、バリエーションがある場合のみ）
                    self.lifecycle.flickAllSuggestTask?.cancel()
                    let task = Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 500_000_000)
                        if !Task.isCancelled,
                           case .started = lifecycle.state,
                           case let .fourWay(map) = self.model.variationSpace(variableStates: variableStates),
                           !map.isEmpty,
                           self.model.longPressActions(variableStates: variableStates).isEmpty {
                        withAnimation(.easeIn(duration: 0.1)) {
                            // Flickサジェスト表示へ移行するため小バブルを閉じる
                            self.qwertySuggestType = nil
                            self.flickSuggestType = .all
                            self.isSuggesting = true
                        }
                    }
                }
                self.lifecycle.flickAllSuggestTask = task
                case let .started(date):
                    if self.model.isFlickAble(to: d, variableStates: variableStates), startLocation.distance(to: value.location) > self.model.flickSensitivity(to: d) {
                        // 一方向サジェスト表示に切り替えるため小バブルを閉じる
                        self.qwertySuggestType = nil
                        self.flickSuggestType = .flick(d)
                        self.isSuggesting = true
                        self.lifecycle.state = .flickOneSuggested(d, Date())
                        self.lifecycle.flickSuggestDismissTask?.cancel()
                        self.action.registerLongPressActionEnd(self.model.longPressActions(variableStates: variableStates))
                        self.lifecycle.flickAllSuggestTask?.cancel()
                        if let v = variation(for: d) {
                            self.action.reserveLongPressAction(v.longPressActions, taskStartDuration: longpressDuration(v.longPressActions), variableStates: variableStates)
                        }
                    }
                    if Date().timeIntervalSince(date) >= self.longpressDuration {
                        self.lifecycle.state = .longPressed
                    }
                case let .flickOneSuggested(prevDirection, _):
                    if self.model.isFlickAble(to: d, variableStates: variableStates) {
                        let distance = startLocation.distance(to: value.location)
                        // Add small hysteresis to avoid boundary jitter
                        let hysteresis: CGFloat = 6
                        if distance <= self.model.flickSensitivity(to: d) + hysteresis {
                            // keep
                        } else {
                            let now = Date()
                            // Throttle direction changes (including A->B, B->A) in a short window
                            let changeThrottle: TimeInterval = 0.06
                            if let last = lifecycle.flickLastUpdate, now.timeIntervalSince(last.date) < changeThrottle, last.direction != d {
                                // skip very rapid alternating updates
                            } else {
                                // Update suggest only if actually changed or not same
                                if case .flick(let current) = self.flickSuggestType, current == d {
                                    // same, skip
                                } else {
                                    // 一方向サジェスト時は小バブルを閉じる
                                    self.qwertySuggestType = nil
                                    self.flickSuggestType = .flick(d)
                                    self.isSuggesting = true
                                }
                                // Reflect latest direction into state and marker
                                if d != prevDirection {
                                    // end previous direction's reserved longpress
                                    if let vPrev = variation(for: prevDirection) {
                                        self.action.registerLongPressActionEnd(vPrev.longPressActions)
                                    }
                                    self.lifecycle.state = .flickOneSuggested(d, Date())
                                    self.lifecycle.state = .flickOneSuggested(d, Date())
                                    // reserve for new direction
                                    if let vNew = variation(for: d) {
                                        self.action.reserveLongPressAction(vNew.longPressActions, taskStartDuration: longpressDuration(vNew.longPressActions), variableStates: variableStates)
                                    }
                                }
                                self.lifecycle.flickLastUpdate = (d, now)
                            }
                        }
                    }
                case let .longFlicked(direction):
                    if d != direction && self.model.isFlickAble(to: d, variableStates: variableStates) {
                        let distance = startLocation.distance(to: value.location)
                        let hysteresis: CGFloat = 6
                        if distance <= self.model.flickSensitivity(to: d) + hysteresis {
                            // ignore micro changes near boundary
                        } else {
                            let now = Date()
                            let changeThrottle: TimeInterval = 0.06
                            if let last = lifecycle.flickLastUpdate, now.timeIntervalSince(last.date) < changeThrottle, last.direction != d {
                                // skip rapid alternation
                            } else {
                                if case .flick(let current) = self.flickSuggestType, current == d {
                                    // same
                                } else {
                                    self.flickSuggestType = .flick(d)
                                }
                                // end previous longpress and start new one
                                if let vPrev = variation(for: direction) {
                                    self.action.registerLongPressActionEnd(vPrev.longPressActions)
                                }
                                self.lifecycle.state = .flickOneSuggested(d, Date())
                                self.lifecycle.state = .flickOneSuggested(d, Date())
                                if let vNew = variation(for: d) {
                                    self.action.reserveLongPressAction(vNew.longPressActions, taskStartDuration: longpressDuration(vNew.longPressActions), variableStates: variableStates)
                                }
                                self.lifecycle.flickLastUpdate = (d, now)
                            }
                        }
                    }
                case .longPressed:
                    // When long-press (all suggestions) is showing, and the finger moves sufficiently
                    // to a flickable direction, transition to one-direction suggest like original FlickKeyView.
                    if self.model.isFlickAble(to: d, variableStates: variableStates),
                       startLocation.distance(to: value.location) > self.model.flickSensitivity(to: d),
                       case let .fourWay(map) = self.model.variationSpace(variableStates: variableStates),
                       !map.isEmpty {
                       if case .flick = self.flickSuggestType {} else {
                            // 一方向サジェストに切り替えるので小バブルを閉じる
                            self.qwertySuggestType = nil
                            self.flickSuggestType = .flick(d)
                            self.isSuggesting = true
                            // Enter one-direction suggested state
                            self.lifecycle.state = .flickOneSuggested(d, Date())
                            self.lifecycle.state = .flickOneSuggested(d, Date())
                            // End long-press reservation now that we moved into a direction
                            self.action.registerLongPressActionEnd(self.model.longPressActions(variableStates: variableStates))
                            self.lifecycle.flickAllSuggestTask?.cancel()
                            if let v = variation(for: d) {
                                self.action.reserveLongPressAction(v.longPressActions, taskStartDuration: longpressDuration(v.longPressActions), variableStates: variableStates)
                            }
                        }
                    }
                case .linearVariations:
                    // Flickハンドラでは特に処理しない
                    break
                }
            }
            .onEnded { _ in
                guard gestureSet == .directionalFlick else { return }
                let dismiss: Task<Void, Never> = Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 70_000_000)
                    self.qwertySuggestType = nil
                    self.flickSuggestType = nil
                    self.isSuggesting = false
                }
                self.lifecycle.flickSuggestDismissTask = dismiss
                if case let .started(date) = lifecycle.state {
                    if Date().timeIntervalSince(date) >= self.longpressDuration {
                        self.lifecycle.state = .longPressed
                    }
                }
                if case let .flickOneSuggested(direction, date) = lifecycle.state {
                    if let v = variation(for: direction), Date().timeIntervalSince(date) >= self.longpressDuration(v.longPressActions) {
                        self.lifecycle.state = .longFlicked(direction)
                    }
                }
                self.action.registerLongPressActionEnd(self.model.longPressActions(variableStates: variableStates))
                self.lifecycle.flickAllSuggestTask?.cancel()
                // End any reserved variation longpress for current direction
                switch lifecycle.state {
                case let .flickOneSuggested(direction, _):
                    if let v = variation(for: direction) { self.action.registerLongPressActionEnd(v.longPressActions) }
                case let .longFlicked(direction):
                    if let v = variation(for: direction) { self.action.registerLongPressActionEnd(v.longPressActions) }
                default:
                    break
                }
                switch lifecycle.state {
                case .idle:
                    break
                case .started:
                    self.action.registerActions(self.model.pressActions(variableStates: variableStates), variableStates: variableStates)
                case let .flickOneSuggested(direction, _):
                    if case let .fourWay(map) = model.variationSpace(variableStates: variableStates), let v = map[direction] {
                        self.action.registerActions(v.pressActions, variableStates: variableStates)
                    }
                case .longPressed:
                    break
                case .longFlicked:
                    if case let .fourWay(map) = model.variationSpace(variableStates: variableStates) {
                        // 長フリックで長押しが設定されていない場合はpressActions
                        // ここでは長押しは予約解除済みなので発火せず、pressのみ
                        // 長押しの有無までは表層から取れないため、pressのみ実施
                        // 既存FlickKeyViewに近い操作感を維持
                        // (詳細制御が必要になればUnifiedVariationにフラグを追加)
                        // fall through to oneDirection behavior when longpress is empty
                        if case let .longFlicked(direction) = lifecycle.state, let v = map[direction], v.longPressActions.isEmpty {
                            self.action.registerActions(v.pressActions, variableStates: variableStates)
                        }
                    }
                case .linearVariations:
                    break
                }
                // keep dismiss task alive; don't cancel it here
                self.lifecycle.reset(cancelTasks: false)
            }
    }

    // MARK: Linear (Qwerty) gesture
    private var qwertyGesture: some Gesture {
        DragGesture(minimumDistance: .zero)
            .onChanged { value in
                // Linear専用ハンドラ
                guard gestureSet == .linearVariation else { return }
                if lifecycle.mode == .none {
                    lifecycle.mode = .linear
                }
                switch self.lifecycle.state {
                case .idle:
                    self.model.feedback(variableStates: variableStates)
                    // 単押しバブル（ジェスチャ非依存）
                    if self.model.showsTapBubble(variableStates: variableStates) {
                        self.qwertySuggestType = .normal
                        self.isSuggesting = true
                    }
                    let now = Date()
                    // lifecycle handles started and double-press tracking
                    self.lifecycle.state = .started(now)
                    self.lifecycle.doublePress.update(touchDownDate: now)
                    self.action.reserveLongPressAction(self.model.longPressActions(variableStates: variableStates), taskStartDuration: longpressDuration, variableStates: variableStates)
                    let task = Task { [longpressDuration] in
                        do {
                            try await Task.sleep(nanoseconds: UInt64(longpressDuration * 1_000_000_000))
                        } catch {
                            return
                        }
                        if !Task.isCancelled && self.lifecycle.state.isActive {
                            if self.model.showsTapBubble(variableStates: variableStates), case let .linear(arr, _) = model.variationSpace(variableStates: variableStates), !arr.isEmpty {
                                self.qwertySuggestType = .variation(selection: nil)
                                self.isSuggesting = true
                                self.lifecycle.state = .linearVariations(selection: nil)
                            } else {
                                self.lifecycle.state = .longPressed
                            }
                        }
                    }
                    self.lifecycle.longPressTask = task
                case .started:
                    break
                case .longPressed:
                    break
                case .linearVariations:
                    let dx = value.location.x - value.startLocation.x
                    let selection: Int = if case let .linear(arr, direction) = model.variationSpace(variableStates: variableStates) {
                        QwertyVariationsModel(arr, direction: direction).getSelection(dx: dx, tabDesign: tabDesign)
                    } else {
                        0
                    }

                    self.qwertySuggestType = .variation(selection: selection)
                    self.isSuggesting = true
                    self.lifecycle.state = .linearVariations(selection: selection)
                case .flickOneSuggested:
                    break
                case .longFlicked:
                    break
                }
            }
            .onEnded { _ in
                // Linear専用ハンドラ
                guard gestureSet == .linearVariation else { return }
                let endDate = Date()
                self.lifecycle.doublePress.update(touchUpDate: endDate)
                self.action.registerLongPressActionEnd(self.model.longPressActions(variableStates: variableStates))
                self.qwertySuggestType = nil
                self.isSuggesting = false
                self.lifecycle.longPressTask?.cancel()
                self.lifecycle.longPressTask = nil
                switch self.lifecycle.state {
                case .idle:
                    break
                case let .started(date):
                    let doublePressActions = self.model.doublePressActions(variableStates: variableStates)
                    if !doublePressActions.isEmpty, lifecycle.doublePress.secondPressCompleted {
                        self.action.registerActions(doublePressActions, variableStates: variableStates)
                        self.lifecycle.doublePress.reset()
                    } else if endDate.timeIntervalSince(date) < longpressDuration {
                        self.action.registerActions(self.model.pressActions(variableStates: variableStates), variableStates: variableStates)
                    }
                case .longPressed:
                    break
                case let .linearVariations(selection):
                    if case let .linear(arr, _) = model.variationSpace(variableStates: variableStates), !arr.isEmpty {
                        let sel = min(max(selection ?? 0, 0), arr.count - 1)
                        self.action.registerActions(arr[sel].actions, variableStates: variableStates)
                    }
                case .flickOneSuggested:
                    break
                case .longFlicked:
                    break
                }
                // ダブルタップ判定のため、直近のUp情報は維持
                self.lifecycle.reset(preserveDoublePress: true)
            }
    }

    // MARK: background/label
    private var keyBackgroundStyle: UnifiedKeyBackgroundStyleValue {
        let isActive: Bool = lifecycle.state.isActive
        return if isActive {
            model.backgroundStyleWhenPressed(theme: theme)
        } else {
            model.backgroundStyleWhenUnpressed(states: variableStates, theme: theme)
        }
    }

    public var body: some View {
        KeyBackground(
            backgroundColor: keyBackgroundStyle.color,
            borderColor: theme.borderColor.color,
            borderWidth: theme.borderWidth,
            size: size,
            shadow: (
                color: theme.keyShadow?.color.color ?? .clear,
                radius: theme.keyShadow?.radius ?? 0.0,
                x: theme.keyShadow?.x ?? 0,
                y: theme.keyShadow?.y ?? 0
            ),
            blendMode: keyBackgroundStyle.blendMode
        )
        .gesture(flickGesture.simultaneously(with: qwertyGesture))
        .overlay { self.model.label(width: size.width, theme: theme, states: variableStates, color: nil) }
        .overlay(alignment: .center) {
            if let flickSuggestType, gestureSet == .directionalFlick {
                UnifiedFlickSuggestView<Extension>(model: model, tabDesign: tabDesign, size: size, suggestType: flickSuggestType)
            }
        }
        .overlay(alignment: .bottom) {
            if let qwertySuggestType {
                let variationsModel: QwertyVariationsModel = if case let .linear(arr, direction) = model.variationSpace(variableStates: variableStates) {
                    QwertyVariationsModel(arr, direction: direction)
                } else {
                    QwertyVariationsModel([])
                }
                let baseLabel = self.model.label(width: size.width, theme: theme, states: variableStates, color: nil)
                UnifiedQwertySuggestView<Extension>(baseLabel: baseLabel, variationsModel: variationsModel, tabDesign: tabDesign, size: size, suggestType: qwertySuggestType)
            }
        }
    }
}
