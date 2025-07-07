//
//  VariableStates.swift
//  Keyboard
//
//  Created by ensan on 2021/02/06.
//  Copyright © 2021 ensan. All rights reserved.
//

import CustardKit
import Foundation
import SwiftUI
import SwiftUIUtils
import SwiftUtils
import enum KanaKanjiConverterModule.InputStyle
import enum KanaKanjiConverterModule.KeyboardLanguage

/// 実行中変更され、かつViewが変更を検知できるべき値。
public final class VariableStates: ObservableObject {
    @MainActor public init(
        interfaceWidth: CGFloat? = nil,
        orientation: KeyboardOrientation? = nil,
        clipboardHistoryManagerConfig: any ClipboardHistoryManagerConfiguration,
        tabManagerConfig: any TabManagerConfiguration,
        userDefaults: UserDefaults
    ) {
        self.tabManager = TabManager(config: tabManagerConfig)
        self.clipboardHistoryManager = ClipboardHistoryManager(config: clipboardHistoryManagerConfig)
        self.keyboardInternalSettingManager = KeyboardInternalSettingManager(userDefaults: userDefaults)
        if let interfaceWidth {
            self.setInterfaceSize(orientation: orientation ?? .vertical, screenWidth: interfaceWidth)
        } else if let orientation {
            // 小さめの値を適当に入れる
            self.setInterfaceSize(orientation: orientation, screenWidth: 200)
        }
    }

    public struct BoolStates: CustardExpressionEvaluatorContext {
        public func getValue(for key: String) -> ExpressionValue? {
            if let boolValue = self[key] {
                return .bool(boolValue)
            }
            return nil
        }

        var isTextMagnifying = false
        var hasUpsideComponent = false
        public var isCapsLocked = false
        public var isShifted = false

        static let isCapsLockedKey = "isCapsLocked"
        public static let isShiftedKey = "isShifted"
        static let hasUpsideComponentKey = "is_screen_expanded"
        static let hasFullAccessKey = "has_full_access"
        // ビルトインのステートとカスタムのステートの両方を適切に扱いたい
        fileprivate var custardStates: [String: Bool] = [:]

        public func evaluateExpression(_ compiledExpression: CompiledExpression) -> Bool? {
            debug(self.custardStates)
            do {
                let condition = try CustardExpressionEvaluator(context: self).evaluate(compiledExpression: compiledExpression)
                if case let .bool(value) = condition {
                    return value
                }
                return nil
            } catch {
                debug("evaluateExpression", error)
                return nil
            }
        }

        mutating func initializeState(_ key: String, with value: Bool) {
            if !self.custardStates.keys.contains(key) {
                self.custardStates[key] = value
            }
        }

        public subscript(_ key: String) -> Bool? {
            get {
                if key == "isTextMagnifying" {
                    return self.isTextMagnifying
                } else if key == Self.hasFullAccessKey {
                    return SemiStaticStates.shared.hasFullAccess
                } else if key == Self.isCapsLockedKey {
                    return self.isCapsLocked
                } else if key == Self.isShiftedKey {
                    return self.isShifted
                } else if key == Self.hasUpsideComponentKey {
                    return self.hasUpsideComponent
                }
                return custardStates[key]
            }
            set {
                if let newValue {
                    if key == Self.hasFullAccessKey || key == Self.hasUpsideComponentKey {
                        // subscript経由ではRead Onlyにする
                        return
                    } else if key == "isTextMagnifying" {
                        self.isTextMagnifying = newValue
                    } else if key == Self.isShiftedKey {
                        self.isCapsLocked = self.isCapsLocked && !newValue
                        self.isShifted = newValue
                    } else if key == Self.isCapsLockedKey {
                        self.isShifted = self.isShifted && !newValue
                        self.isCapsLocked = newValue
                    } else {
                        custardStates[key] = newValue
                    }
                }
            }
        }
    }
    @MainActor private(set) public var inputStyle: InputStyle = .direct
    @Published private(set) public var tabManager: TabManager
    @Published public var keyboardInternalSettingManager: KeyboardInternalSettingManager
    @Published public var clipboardHistoryManager: ClipboardHistoryManager

    @Published public var keyboardLanguage: KeyboardLanguage = .ja_JP
    @Published private(set) public var keyboardOrientation: KeyboardOrientation = .vertical
    @Published private(set) public var keyboardLayout: KeyboardLayout = .flick

    @MainActor private(set) public var keyboardType: UIKeyboardType = .default

    /// `ResultModel`の変数
    @Published public var resultModel = ResultModel()

    // Bool値の変数はここにまとめる
    @Published public var boolStates = BoolStates()

    // 片手モードの実行時、キーボードの幅はinterfaceSizeによって決定できる。
    @Published public var interfaceSize: CGSize = .zero
    @Published public var interfacePosition: CGPoint = .zero

    /// 外部では利用しないが、`enterKeyState`の更新時に必要になる
    @MainActor private(set) public var returnKeyType: UIReturnKeyType = .default
    @Published private(set) var enterKeyState: EnterKeyState = .return(.default)

    @Published public var barState: BarState = .none

    @Published var magnifyingText = ""

    @Published public var upsideComponent: UpsideComponent?

    /// 片手モード編集状態
    @Published public var resizingState: ResizingState = .fullwidth

    @Published public var maximumHeight: CGFloat = 0

    @Published public var heightScaleFromKeyboardHeightSetting: CGFloat = 1

    /// 周囲のテキストが変化した場合にインクリメントする値。変化の検出に利用する。
    /// - note: この値がどれだけ変化するかは実装によるので、変化量は意味をなさない。
    @Published public var textChangedCount: Int = 0

    public struct UndoAction: Equatable {
        public init(action: ActionType, textChangedCount: Int) {
            self.action = action
            self.textChangedCount = textChangedCount
        }

        var action: ActionType
        var textChangedCount: Int
    }

    @Published public var undoAction: UndoAction?

    struct SurroundingText: Equatable, Hashable, Sendable {
        var leftSideText: String = ""
        var centerText: String = ""
        var rightSideText: String = ""
    }
    @Published private(set) var surroundingText = SurroundingText()

    @Published public var temporalMessage: TemporalMessage?

    public func setSurroundingText(leftSide: String, center: String, rightSide: String) {
        self.surroundingText.leftSideText = leftSide
        self.surroundingText.centerText = center
        self.surroundingText.rightSideText = rightSide
    }

    @MainActor public func setResizingMode(_ state: ResizingState) {
        switch state {
        case .fullwidth:
            interfaceSize = .init(width: SemiStaticStates.shared.screenWidth, height: Design.keyboardHeight(screenWidth: SemiStaticStates.shared.screenWidth, orientation: self.keyboardOrientation) + 2)
            interfacePosition = .zero

        case .onehanded:

            break

        case .resizing:
            // リサイズ開始時は、保存された値から初期状態を読み込むので変更なし
            let item = keyboardInternalSettingManager.oneHandedModeSetting.item(layout: keyboardLayout, orientation: keyboardOrientation)
            interfaceSize = CGSize(width: min(item.size.width, SemiStaticStates.shared.screenWidth), height: item.size.height * heightScaleFromKeyboardHeightSetting)
            interfacePosition = item.position
        }

        // 以下の処理は全ケースで共通
        self.maximumHeight = interfaceSize.height
        self.resizingState = state
        keyboardInternalSettingManager.update(\.oneHandedModeSetting) {value in
            value.update(layout: keyboardLayout, orientation: keyboardOrientation) {value in
                value.isLastOnehandedMode = state != .fullwidth
            }
        }
    }

    @MainActor public func initialize() {
        self.tabManager.initialize(variableStates: self)
    }

    @MainActor public func closeKeyboard() {
        self.tabManager.closeKeyboard()
        self.upsideComponent = nil
        // 変更する
        self.textChangedCount += 1
        // このタイミングでクリップボードを確認する
        self.clipboardHistoryManager.checkUpdate()
        // 保存処理を行う
        self.clipboardHistoryManager.save()
    }

    @MainActor public func setKeyboardType(_ type: UIKeyboardType?) {
        debug("setKeyboardType:", type.debugDescription)
        guard let type else {
            return
        }
        self.keyboardType = type
        switch type {
        case .default, .asciiCapable:
            return
        case .numbersAndPunctuation:
            return
        case .URL:
            self.setTab(.user_dependent(.english), temporary: true)
        case .numberPad:
            self.setTab(.existential(.custard(.numberPad)), temporary: true)
        case .phonePad:
            self.setTab(.existential(.custard(.phonePad)), temporary: true)
        case .namePhonePad:
            return
        case .emailAddress:
            self.setTab(.user_dependent(.english), temporary: true)
        case .decimalPad:
            self.setTab(.existential(.custard(.decimalPad)), temporary: true)
        case .twitter:
            return
        case .webSearch:
            return
        case .asciiCapableNumberPad:
            return
        @unknown default:
            return
        }
    }

    @MainActor public func setEnterKeyState(_ state: RoughEnterKeyState) {
        switch state {
        case .return:
            self.enterKeyState = .return(returnKeyType)
        case .complete:
            self.enterKeyState = .complete
        }
    }

    @MainActor private func setTab(_ tab: KeyboardTab, temporary: Bool = false) {
        if temporary {
            self.tabManager.setTemporalTab(tab, variableStates: self)
        } else {
            self.tabManager.moveTab(to: tab, variableStates: self)
        }
    }

    @MainActor public func setTab(_ tab: TabData, temporary: Bool = false) {
        let tab = tab.tab(config: self.tabManager.config)
        self.setTab(tab, temporary: temporary)
    }

    @MainActor public func setUIReturnKeyType(type: UIReturnKeyType) {
        self.returnKeyType = type
        if case let .return(prev) = self.enterKeyState, prev != type {
            self.setEnterKeyState(.return)
        }
    }

    @MainActor public func updateResizingState() {
        let isLastOnehandedMode = keyboardInternalSettingManager.oneHandedModeSetting.item(layout: keyboardLayout, orientation: keyboardOrientation).isLastOnehandedMode
        if isLastOnehandedMode {
            self.setResizingMode(.onehanded)
        } else {
            self.setResizingMode(.fullwidth)
        }
    }

    @MainActor public func setKeyboardLayout(_ layout: KeyboardLayout) {
        self.keyboardLayout = layout
        self.updateResizingState()
    }

    @MainActor public func setInputStyle(_ style: InputStyle) {
        self.inputStyle = style
    }

    @MainActor public func setInterfaceSize(orientation: KeyboardOrientation, screenWidth: CGFloat) {
        let height = Design.keyboardHeight(screenWidth: screenWidth, orientation: orientation) + Design.keyboardScreenBottomPadding
        if self.keyboardOrientation != orientation {
            self.keyboardOrientation = orientation
            self.updateResizingState()
        }
        let layout = self.keyboardLayout

        // 片手モードの処理
        keyboardInternalSettingManager.update(\.oneHandedModeSetting) {value in
            value.setIfFirst(layout: layout, orientation: orientation, size: .init(width: screenWidth, height: height), position: .zero)
        }
        switch self.resizingState {
        case .fullwidth:
            self.interfaceSize = CGSize(width: screenWidth, height: height * heightScaleFromKeyboardHeightSetting)
        case .onehanded, .resizing:
            let item = keyboardInternalSettingManager.oneHandedModeSetting.item(layout: layout, orientation: orientation)
            // 安全のため、指示されたwidth, heightを超える値を許可しない。
            self.interfaceSize = CGSize(width: min(screenWidth, item.size.width), height: item.size.height * heightScaleFromKeyboardHeightSetting)
            self.interfacePosition = item.position
        }
    }

    @MainActor
    func resetOneHandedModeSetting() {
        // 設定管理オブジェクトを通じて、oneHandedModeSettingを更新する
        keyboardInternalSettingManager.update(\.oneHandedModeSetting) { setting in
            // ステップ1: まず、カスタム設定をまっさらな状態にリセットする
            setting.reset(layout: self.keyboardLayout, orientation: self.keyboardOrientation)

            // ステップ2: 次に、リセットされた項目に「本来のデフォルト値」を再設定する
            let defaultHeight = Design.keyboardHeight(screenWidth: SemiStaticStates.shared.screenWidth, orientation: self.keyboardOrientation) + Design.keyboardScreenBottomPadding
            let defaultSize = CGSize(width: SemiStaticStates.shared.screenWidth, height: defaultHeight)
            setting.setIfFirst(layout: self.keyboardLayout, orientation: self.keyboardOrientation, size: defaultSize, position: .zero, forced: true) // forced: trueで確実に上書きする
        }

        // `updateResizingState()`を呼んで、UIに即時反映させる
        // これにより、リセット後の正しいデフォルトサイズが画面に表示される
        DispatchQueue.main.async {
            self.updateResizingState()
        }
    }

}
