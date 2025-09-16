import CustardKit
import Foundation
import KeyboardThemes
import SwiftUI

struct FlickCustomKeyModel<Extension: ApplicationSpecificKeyboardViewExtension>: UnifiedKeyModelProtocol {
    enum ColorRole {
        case normal
        case special
        case selected
        case unimportant
    }

    // 小バブルは基本出さない（必要ならshowsTapBubbleで明示）
    private let labelType: KeyLabelType
    private let centerPress: [ActionType]
    private let centerLongpress: LongpressActionType
    private let flickMap: [FlickDirection: UnifiedVariation]
    private let showsBubbleFlag: Bool
    private let colorRole: ColorRole

    init(labelType: KeyLabelType, pressActions: [ActionType], longPressActions: LongpressActionType, flick: [FlickDirection: UnifiedVariation], showsTapBubble: Bool, colorRole: ColorRole) {
        self.labelType = labelType
        self.centerPress = pressActions
        self.centerLongpress = longPressActions
        self.flickMap = flick
        self.showsBubbleFlag = showsTapBubble
        self.colorRole = colorRole
    }

    func pressActions(variableStates _: VariableStates) -> [ActionType] { centerPress }
    func longPressActions(variableStates _: VariableStates) -> LongpressActionType { centerLongpress }
    func variationSpace(variableStates _: VariableStates) -> UnifiedVariationSpace { .fourWay(flickMap) }
    @MainActor func showsTapBubble(variableStates _: VariableStates) -> Bool { showsBubbleFlag }

    func isFlickAble(to direction: FlickDirection, variableStates _: VariableStates) -> Bool { flickMap.keys.contains(direction) }

    func label<ThemeExtension>(width: CGFloat, theme _: ThemeData<ThemeExtension>, states _: VariableStates, color _: Color?) -> KeyLabel<Extension> where ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable {
        KeyLabel(labelType, width: width)
    }

    @MainActor
    func backgroundStyleWhenUnpressed<ThemeExtension>(states: VariableStates, theme: ThemeData<ThemeExtension>) -> UnifiedKeyBackgroundStyleValue where ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable {
        // If this key's primary action is a tab move, highlight when it targets the current tab
        if let isTabMoveSelected = isMoveTabTargetSelected(states: states), isTabMoveSelected {
            return (theme.pushedKeyFillColor.color, theme.pushedKeyFillColor.blendMode)
        }
        return switch colorRole {
        case .normal: (theme.normalKeyFillColor.color, theme.normalKeyFillColor.blendMode)
        case .special: (theme.specialKeyFillColor.color, theme.specialKeyFillColor.blendMode)
        case .selected: (theme.pushedKeyFillColor.color, theme.pushedKeyFillColor.blendMode)
        case .unimportant: (Color(white: 0, opacity: 0.001), .normal)
        }
    }

    @MainActor
    private func isMoveTabTargetSelected(states: VariableStates) -> Bool? {
        // Check center press actions for a moveTab and compare with current tab
        guard let action = centerPress.first else { return nil }
        switch action {
        case let .moveTab(tabData):
            let target = tabData.tab(config: states.tabManager.config)
            return states.tabManager.isCurrentTab(tab: target)
        default:
            return nil
        }
    }

    func feedback(variableStates: VariableStates) {
        centerPress.first?.feedback(variableStates: variableStates, extension: Extension.self)
    }
}
