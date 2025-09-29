import CustardKit
import Foundation
import KeyboardThemes
import SwiftUI

// A general unified key model that can expose both flick (four-way) and linear (long-press) variations.
struct UnifiedGeneralKeyModel<Extension: ApplicationSpecificKeyboardViewExtension>: UnifiedKeyModelProtocol {
    enum ColorRole {
        case normal
        case special
        case selected
        case unimportant
    }

    private let labelType: KeyLabelType
    private let centerPress: [ActionType]
    private let centerLongpress: LongpressActionType
    private let flickMap: [FlickDirection: UnifiedVariation]
    private let linearVariations: [QwertyVariationsModel.VariationElement]
    private let linearDirection: VariationsViewDirection
    private let showsBubbleFlag: Bool
    private let colorRole: ColorRole

    init(
        labelType: KeyLabelType,
        pressActions: [ActionType],
        longPressActions: LongpressActionType,
        flick: [FlickDirection: UnifiedVariation],
        linearVariations: [QwertyVariationsModel.VariationElement],
        linearDirection: VariationsViewDirection = .center,
        showsTapBubble: Bool,
        colorRole: ColorRole
    ) {
        self.labelType = labelType
        self.centerPress = pressActions
        self.centerLongpress = longPressActions
        self.flickMap = flick
        self.linearVariations = linearVariations
        self.linearDirection = linearDirection
        self.showsBubbleFlag = showsTapBubble
        self.colorRole = colorRole
    }

    func pressActions(variableStates _: VariableStates) -> [ActionType] {
        centerPress
    }
    func longPressActions(variableStates _: VariableStates) -> LongpressActionType {
        centerLongpress
    }

    func variationSpace(variableStates _: VariableStates) -> UnifiedVariationSpace {
        if !flickMap.isEmpty {
            return .fourWay(flickMap)
        } else if !linearVariations.isEmpty {
            return .linear(linearVariations, direction: linearDirection)
        } else {
            return .none
        }
    }

    @MainActor func showsTapBubble(variableStates _: VariableStates) -> Bool {
        showsBubbleFlag
    }

    func isFlickAble(to direction: FlickDirection, variableStates _: VariableStates) -> Bool {
        flickMap.keys.contains(direction)
    }

    @MainActor func getFlickVariationMap(variableStates _: VariableStates) -> [FlickDirection: UnifiedVariation] {
        flickMap
    }
    @MainActor func getLinearVariations(variableStates _: VariableStates) ->
    (arr: [QwertyVariationsModel.VariationElement], direction: VariationsViewDirection) { (linearVariations, linearDirection)
    }

    func label<ThemeExtension>(width: CGFloat, theme _: ThemeData<ThemeExtension>, states _: VariableStates, color _: Color?) -> KeyLabel<Extension> where ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable {
        KeyLabel(labelType, width: width)
    }

    @MainActor
    func backgroundStyleWhenUnpressed<ThemeExtension>(states _: VariableStates, theme: ThemeData<ThemeExtension>) -> UnifiedKeyBackgroundStyleValue where ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable {
        switch colorRole {
        case .normal: (theme.normalKeyFillColor.color, theme.normalKeyFillColor.blendMode)
        case .special: (theme.specialKeyFillColor.color, theme.specialKeyFillColor.blendMode)
        case .selected: (theme.pushedKeyFillColor.color, theme.pushedKeyFillColor.blendMode)
        case .unimportant: (Color(white: 0, opacity: 0.001), .normal)
        }
    }

    func feedback(variableStates: VariableStates) {
        centerPress.first?.feedback(variableStates: variableStates, extension: Extension.self)
    }
}
