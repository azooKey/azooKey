import Foundation
import SwiftUI

public struct QwertyVariationsModel {

    public struct VariationElement: Sendable, Equatable {
        var label: KeyLabelType
        var actions: [ActionType]
    }

    let variations: [VariationElement]
    var direction: VariationsViewDirection

    init(_ variations: [VariationElement], direction: VariationsViewDirection = .center) {
        self.variations = variations
        self.direction = direction
    }

    @MainActor func performSelected(selection: Int?, actionManager: some UserActionManager, variableStates: VariableStates) {
        if self.variations.isEmpty {
            return
        }
        guard let selection else {
            return
        }
        actionManager.registerActions(self.variations[selection].actions, variableStates: variableStates)
    }

    func getSelection(dx: CGFloat, tabDesign: TabDependentDesign) -> Int {
        let count = CGFloat(self.variations.count)
        let width = tabDesign.keyViewWidth
        let spacing = tabDesign.horizontalSpacing
        let start: CGFloat
        switch self.direction {
        case .center:
            start = -(width * count + spacing * (count - 1)) / 2
        case .right:
            start = 0
        case .left:
            start = -(width * count + spacing * (count - 1))
        }
        let selection = (dx - start) / width
        return min(max(Int(selection), 0), Int(count) - 1)
    }
}
