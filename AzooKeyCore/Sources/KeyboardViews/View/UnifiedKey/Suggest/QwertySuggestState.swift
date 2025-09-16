struct QwertySuggestState: Equatable, Hashable, Sendable {
    struct Item: Equatable, Hashable, Sendable {
        var position: UnifiedPositionSpecifier
        var type: QwertySuggestType
    }

    /// 位置：サジェストタイプ
    var item: Item?

    /// 一度に一カ所しかサジェストは表示されない
    subscript(position: UnifiedPositionSpecifier) -> QwertySuggestType? {
        get {
            if self.item?.position == position {
                self.item?.type
            } else {
                nil
            }
        }
        set {
            if let newValue {
                self.item = .init(position: position, type: newValue)
            } else if self.item?.position == position {
                self.item = nil
            }
        }
    }
}
