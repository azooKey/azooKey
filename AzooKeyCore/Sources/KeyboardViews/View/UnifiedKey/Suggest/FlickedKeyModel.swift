public struct FlickedKeyModel {
    static var empty: Self { FlickedKeyModel(labelType: .text(""), pressActions: []) }
    let labelType: KeyLabelType
    let pressActions: [ActionType]
    let longPressActions: LongpressActionType

    init(labelType: KeyLabelType, pressActions: [ActionType], longPressActions: LongpressActionType = .none) {
        self.labelType = labelType
        self.pressActions = pressActions
        self.longPressActions = longPressActions
    }
}
