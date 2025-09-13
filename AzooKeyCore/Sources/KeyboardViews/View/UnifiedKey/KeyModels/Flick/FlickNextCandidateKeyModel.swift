import CustardKit
import Foundation
import KeyboardThemes
import SwiftUI

struct FlickNextCandidateKeyModel<Extension: ApplicationSpecificKeyboardViewExtension>: UnifiedKeyModelProtocol {
    @MainActor func showsTapBubble(variableStates _: VariableStates) -> Bool { false }
    func pressActions(variableStates: VariableStates) -> [ActionType] {
        variableStates.resultModel.results.isEmpty ? [.input(" ")] : [.selectCandidate(.offset(1))]
    }
    func longPressActions(variableStates: VariableStates) -> LongpressActionType {
        if variableStates.resultModel.results.isEmpty {
            .init(start: [.setCursorBar(.toggle)])
        } else {
            .init(repeat: [.selectCandidate(.offset(1))])
        }
    }
    func doublePressActions(variableStates _: VariableStates) -> [ActionType] { [] }
    func variationSpace(variableStates: VariableStates) -> UnifiedVariationSpace {
        let left: UnifiedVariation = if variableStates.resultModel.selection != nil {
            UnifiedVariation(label: .text("前候補"), pressActions: [.selectCandidate(.offset(-1))], longPressActions: .init(repeat: [.selectCandidate(.offset(-1))]))
        } else {
            UnifiedVariation(label: .text("←"), pressActions: [.moveCursor(-1)], longPressActions: .init(repeat: [.moveCursor(-1)]))
        }
        return .fourWay([
            .left: left,
            .top: UnifiedVariation(label: .text("全角"), pressActions: [.input("　")]),
            .bottom: UnifiedVariation(label: .text("Tab"), pressActions: [.input("\u{0009}")])
        ])
    }
    func isFlickAble(to direction: FlickDirection, variableStates _: VariableStates) -> Bool {
        switch direction {
        case .left, .top, .bottom: true
        case .right: false
        }
    }
    func flickSensitivity(to _: FlickDirection) -> CGFloat { 25 / Extension.SettingProvider.flickSensitivity }
    func label<ThemeExtension>(width: CGFloat, theme _: ThemeData<ThemeExtension>, states: VariableStates, color _: Color?) -> KeyLabel<Extension> where ThemeExtension : ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable {
        states.resultModel.results.isEmpty ? KeyLabel(.text("空白"), width: width) : KeyLabel(.text("次候補"), width: width)
    }
    func backgroundStyleWhenPressed<ThemeExtension>(theme: ThemeData<ThemeExtension>) -> UnifiedKeyBackgroundStyleValue where ThemeExtension : ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable { (theme.pushedKeyFillColor.color, theme.pushedKeyFillColor.blendMode) }
    func backgroundStyleWhenUnpressed<ThemeExtension>(states _: VariableStates, theme: ThemeData<ThemeExtension>) -> UnifiedKeyBackgroundStyleValue where ThemeExtension : ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable { (theme.specialKeyFillColor.color, theme.specialKeyFillColor.blendMode) }
    func feedback(variableStates: VariableStates) { variableStates.resultModel.results.isEmpty ? KeyboardFeedback<Extension>.click() : KeyboardFeedback<Extension>.tabOrOtherKey() }
}
