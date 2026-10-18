import Foundation

/// ホストの変更通知を比較するための、変更前のコンテキスト。
public struct TextChangeContext: Sendable {
    public private(set) var before: ObservedTextState?
    private var isContinuingExpectedEdits = false

    public init() {}

    /// 同じ変更について複数回通知される場合は、最初の状態を保持する。
    /// 内部編集の続きに備えた状態は、新たな変更前通知があれば置き換える。
    public mutating func willChange(before: ObservedTextState) {
        guard self.before == nil || self.isContinuingExpectedEdits else {
            return
        }
        self.before = before
        self.isContinuingExpectedEdits = false
    }

    /// 変更前通知を伴わない、内部編集の後続通知にも対応する。
    public mutating func didConsumeExpectedEdit(after: ObservedTextState, hasMoreEdits: Bool) {
        self.before = hasMoreEdits ? after : nil
        self.isContinuingExpectedEdits = hasMoreEdits
    }

    public mutating func reset() {
        self.before = nil
        self.isContinuingExpectedEdits = false
    }
}
