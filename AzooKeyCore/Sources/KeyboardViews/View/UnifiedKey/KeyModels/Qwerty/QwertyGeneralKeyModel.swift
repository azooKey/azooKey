import Foundation
import KeyboardThemes
import SwiftUI

struct QwertyGeneralKeyModel<Extension: ApplicationSpecificKeyboardViewExtension>: UnifiedKeyModelProtocol {
    enum UnpressedRole {
        case normal
        case special
        case selected
        case unimportant
    }

    private let showsBubbleFlag: Bool
    private let labelType: KeyLabelType
    private let press: (VariableStates) -> [ActionType]
    private let longpress: (VariableStates) -> LongpressActionType
    private let variations: [QwertyVariationsModel.VariationElement]
    private let direction: VariationsViewDirection
    private let role: UnpressedRole
    // 文字キー等で英語時シフト・Capsで大文字化するか（カスタムキー等では無効にしたい）
    private let shouldUppercaseForEnglish: Bool

    init(labelType: KeyLabelType,
         pressActions: @escaping (VariableStates) -> [ActionType],
         longPressActions: @escaping (VariableStates) -> LongpressActionType,
         variations: [QwertyVariationsModel.VariationElement],
         direction: VariationsViewDirection,
         showsTapBubble: Bool,
         role: UnpressedRole,
         shouldUppercaseForEnglish: Bool = true
    ) {
        self.labelType = labelType
        self.press = pressActions
        self.longpress = longPressActions
        self.variations = variations
        self.direction = direction
        self.showsBubbleFlag = showsTapBubble
        self.role = role
        self.shouldUppercaseForEnglish = shouldUppercaseForEnglish
    }

    // 静的アクション版（LinearCustomの置き換え用）
    init(labelType: KeyLabelType,
         pressActions: [ActionType],
         longPressActions: LongpressActionType,
         variations: [QwertyVariationsModel.VariationElement],
         direction: VariationsViewDirection = .center,
         showsTapBubble: Bool,
         role: UnpressedRole,
         shouldUppercaseForEnglish: Bool = true
    ) {
        self.init(
            labelType: labelType,
            pressActions: { _ in pressActions },
            longPressActions: { _ in longPressActions },
            variations: variations,
            direction: direction,
            showsTapBubble: showsTapBubble,
            role: role,
            shouldUppercaseForEnglish: shouldUppercaseForEnglish
        )
    }

    func pressActions(variableStates: VariableStates) -> [ActionType] { press(variableStates) }
    func longPressActions(variableStates: VariableStates) -> LongpressActionType { longpress(variableStates) }
    func variationSpace(variableStates _: VariableStates) -> UnifiedVariationSpace { .linear(variations, direction: direction) }
    @MainActor func showsTapBubble(variableStates _: VariableStates) -> Bool { showsBubbleFlag }

    func label<ThemeExtension>(width: CGFloat, theme _: ThemeData<ThemeExtension>, states: VariableStates, color: Color?) -> KeyLabel<Extension> where ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable {
        // Emulate QwertyKeyModel: uppercase for en_US when shifted or caps（必要時のみ）
        if shouldUppercaseForEnglish,
           states.boolStates.isCapsLocked || states.boolStates.isShifted,
           states.keyboardLanguage == .en_US,
           case let .text(text) = labelType {
            return KeyLabel(.text(text.uppercased()), width: width, textColor: color)
        }
        return KeyLabel(labelType, width: width, textColor: color)
    }

    func backgroundStyleWhenUnpressed<ThemeExtension>(states _: VariableStates, theme: ThemeData<ThemeExtension>) -> UnifiedKeyBackgroundStyleValue where ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable {
        switch role {
        case .normal: (theme.normalKeyFillColor.color, theme.normalKeyFillColor.blendMode)
        case .special: (theme.specialKeyFillColor.color, theme.specialKeyFillColor.blendMode)
        case .selected: (theme.pushedKeyFillColor.color, theme.pushedKeyFillColor.blendMode)
        case .unimportant: (Color(white: 0, opacity: 0.001), .normal)
        }
    }

    func feedback(variableStates: VariableStates) {
        press(variableStates).first?.feedback(variableStates: variableStates, extension: Extension.self)
    }
}
