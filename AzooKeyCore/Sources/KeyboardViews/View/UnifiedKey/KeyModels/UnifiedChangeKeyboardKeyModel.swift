import CustardKit
import Foundation
import KeyboardThemes
import SwiftUI

struct UnifiedChangeKeyboardKeyModel<Extension: ApplicationSpecificKeyboardViewExtension>: UnifiedKeyModelProtocol {
    @MainActor private var _enablePasteButton: Bool {
        Extension.SettingProvider.enablePasteButton
    }
    @MainActor private var usePasteButton: Bool {
        !SemiStaticStates.shared.needsInputModeSwitchKey && SemiStaticStates.shared.hasFullAccess && _enablePasteButton
    }
    func pressActions(variableStates: VariableStates) -> [ActionType] {
        switch SemiStaticStates.shared.needsInputModeSwitchKey {
        case true:
            return []
        case false:
            return [.setCursorBar(.toggle)]
        }
    }
    func longPressActions(variableStates _: VariableStates) -> LongpressActionType {
        .none
    }
    func variationSpace(variableStates: VariableStates) -> UnifiedVariationSpace {
        if usePasteButton {
            return .fourWay([.top: UnifiedVariation(label: .image("doc.on.clipboard"), pressActions: [.paste])])
        }
        return .none
    }
    func isFlickAble(to direction: FlickDirection, variableStates _: VariableStates) -> Bool {
        direction == .top && usePasteButton
    }

    func label<ThemeExtension>(width: CGFloat, theme _: ThemeData<ThemeExtension>, states _: VariableStates, color _: Color?) -> KeyLabel<Extension> where ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable {
        switch SemiStaticStates.shared.needsInputModeSwitchKey {
        case true:
            return KeyLabel(.changeKeyboard, width: width)
        case false:
            return KeyLabel(.image("arrowtriangle.left.and.line.vertical.and.arrowtriangle.right"), width: width)
        }
    }
    func backgroundStyleWhenUnpressed<ThemeExtension>(states _: VariableStates, theme: ThemeData<ThemeExtension>) -> UnifiedKeyBackgroundStyleValue where ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable {
        (theme.specialKeyFillColor.color, theme.specialKeyFillColor.blendMode)
    }
    func feedback(variableStates _: VariableStates) {
        KeyboardFeedback<Extension>.tabOrOtherKey()
    }
}
