import Foundation

public struct ObservedTextState: Equatable, Sendable {
    public var left: String
    public var center: String
    public var right: String

    public init(left: String, center: String, right: String) {
        self.left = left
        self.center = center
        self.right = right
    }
}

public struct ExpectedEditTracker: Sendable {
    public enum Consumption: Equatable, Sendable {
        case noMatch
        case matched(hasMoreEdits: Bool)
    }

    private struct ExpectedEdit: Equatable, Sendable {
        var before: ObservedTextState
        var after: ObservedTextState
    }

    private let maxStoredEdits: Int
    private var expectedEdits: [ExpectedEdit] = []

    public init(maxStoredEdits: Int = 32) {
        self.maxStoredEdits = maxStoredEdits
    }

    public mutating func record(before: ObservedTextState?, after: ObservedTextState?) {
        guard let before, let after, before != after else {
            return
        }
        // 削除・再挿入で元の状態へ戻った区間は、途中の空状態が後の外部操作と一致し得る。
        // 途中の履歴を取り除き、表示が変わらない通知だけを一度受け取れるようにする。
        // 連続した未消費の編集だけをたどり、別の編集列や消費済みの通知は対象にしない。
        var currentBefore = before
        var index = self.expectedEdits.endIndex
        while index > self.expectedEdits.startIndex {
            let previous = self.expectedEdits[index - 1]
            guard previous.after == currentBefore else { break }
            index -= 1
            if previous.before == after {
                self.expectedEdits.removeSubrange(index...)
                self.expectedEdits.append(.init(before: after, after: after))
                return
            }
            currentBefore = previous.before
        }
        self.expectedEdits.append(.init(before: before, after: after))
        if self.expectedEdits.count > self.maxStoredEdits {
            self.expectedEdits.removeFirst(self.expectedEdits.count - self.maxStoredEdits)
        }
    }

    public mutating func consume(before: ObservedTextState, after: ObservedTextState) -> Consumption {
        for startIndex in self.expectedEdits.indices where self.expectedEdits[startIndex].before == before {
            var endIndex = startIndex
            var currentAfter = self.expectedEdits[endIndex].after
            if currentAfter == after {
                self.expectedEdits.removeFirst(endIndex + 1)
                return .matched(hasMoreEdits: self.expectedEdits.first?.before == after)
            }

            while endIndex + 1 < self.expectedEdits.endIndex, currentAfter == self.expectedEdits[endIndex + 1].before {
                endIndex += 1
                currentAfter = self.expectedEdits[endIndex].after
                if currentAfter == after {
                    self.expectedEdits.removeFirst(endIndex + 1)
                    return .matched(hasMoreEdits: self.expectedEdits.first?.before == after)
                }
            }
        }
        return .noMatch
    }
}
