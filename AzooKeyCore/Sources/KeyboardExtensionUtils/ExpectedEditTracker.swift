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
