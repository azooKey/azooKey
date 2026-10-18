@testable import KeyboardExtensionUtils
import XCTest

final class ExpectedEditTrackerTests: XCTestCase {
    func testConsumeSingleEdit() {
        var tracker = ExpectedEditTracker()
        let before = ObservedTextState(left: "a", center: "", right: "")
        let after = ObservedTextState(left: "ab", center: "", right: "")

        tracker.record(before: before, after: after)

        XCTAssertEqual(tracker.consume(before: before, after: after), .matched(hasMoreEdits: false))
        XCTAssertEqual(tracker.consume(before: before, after: after), .noMatch)
    }

    func testConsumeChainedEditsAsSingleObservation() {
        var tracker = ExpectedEditTracker()
        let initial = ObservedTextState(left: "a", center: "", right: "")
        let intermediate = ObservedTextState(left: "ab", center: "", right: "")
        let final = ObservedTextState(left: "abc", center: "", right: "")

        tracker.record(before: initial, after: intermediate)
        tracker.record(before: intermediate, after: final)

        XCTAssertEqual(tracker.consume(before: initial, after: final), .matched(hasMoreEdits: false))
        XCTAssertEqual(tracker.consume(before: intermediate, after: final), .noMatch)
    }

    func testMismatchDoesNotConsumePendingEdits() {
        var tracker = ExpectedEditTracker()
        let before = ObservedTextState(left: "a", center: "", right: "")
        let expectedAfter = ObservedTextState(left: "ab", center: "", right: "")
        let unexpectedAfter = ObservedTextState(left: "ax", center: "", right: "")

        tracker.record(before: before, after: expectedAfter)

        XCTAssertEqual(tracker.consume(before: before, after: unexpectedAfter), .noMatch)
        XCTAssertEqual(tracker.consume(before: before, after: expectedAfter), .matched(hasMoreEdits: false))
    }

    func testDropsOldestEditsWhenCapacityIsExceeded() {
        var tracker = ExpectedEditTracker(maxStoredEdits: 2)
        let state0 = ObservedTextState(left: "0", center: "", right: "")
        let state1 = ObservedTextState(left: "1", center: "", right: "")
        let state2 = ObservedTextState(left: "2", center: "", right: "")
        let state3 = ObservedTextState(left: "3", center: "", right: "")

        tracker.record(before: state0, after: state1)
        tracker.record(before: state1, after: state2)
        tracker.record(before: state2, after: state3)

        XCTAssertEqual(tracker.consume(before: state0, after: state1), .noMatch)
        XCTAssertEqual(tracker.consume(before: state1, after: state3), .matched(hasMoreEdits: false))
    }

    func testConsumeIncrementalEditsKeepsTransactionOpen() {
        var tracker = ExpectedEditTracker()
        let state0 = ObservedTextState(left: "0", center: "", right: "")
        let state1 = ObservedTextState(left: "01", center: "", right: "")
        let state2 = ObservedTextState(left: "012", center: "", right: "")

        tracker.record(before: state0, after: state1)
        tracker.record(before: state1, after: state2)

        XCTAssertEqual(tracker.consume(before: state0, after: state1), .matched(hasMoreEdits: true))
        XCTAssertEqual(tracker.consume(before: state1, after: state2), .matched(hasMoreEdits: false))
    }

    func testCompletedRoundTripDoesNotMatchExternalMoveToBlankLine() {
        var tracker = ExpectedEditTracker()
        let emoji = ObservedTextState(left: "\n🏊", center: "", right: "")
        let blankLine = ObservedTextState(left: "\n", center: "", right: "")
        let alternative = ObservedTextState(left: "\n泳ぐ人", center: "", right: "")
        let documentStart = ObservedTextState(left: "", center: "", right: "")

        tracker.record(before: emoji, after: blankLine)
        tracker.record(before: blankLine, after: alternative)
        tracker.record(before: alternative, after: blankLine)
        tracker.record(before: blankLine, after: emoji)

        XCTAssertEqual(tracker.consume(before: emoji, after: documentStart), .noMatch)
        XCTAssertEqual(tracker.consume(before: emoji, after: blankLine), .noMatch)
    }

    func testCompletedRoundTripPreservesEarlierPendingChange() {
        var tracker = ExpectedEditTracker()
        let initial = ObservedTextState(left: "before", center: "", right: "")
        let stable = ObservedTextState(left: "🏊", center: "", right: "")
        let temporary = ObservedTextState(left: "", center: "", right: "")

        tracker.record(before: initial, after: stable)
        tracker.record(before: stable, after: temporary)
        tracker.record(before: temporary, after: stable)

        XCTAssertEqual(tracker.consume(before: stable, after: temporary), .noMatch)
        XCTAssertEqual(tracker.consume(before: initial, after: stable), .matched(hasMoreEdits: true))
        XCTAssertEqual(tracker.consume(before: stable, after: stable), .matched(hasMoreEdits: false))
    }

    func testMatchingStateDoesNotCancelDisconnectedChanges() {
        var tracker = ExpectedEditTracker()
        let first = ObservedTextState(left: "a", center: "", right: "")
        let second = ObservedTextState(left: "b", center: "", right: "")
        let unrelated = ObservedTextState(left: "c", center: "", right: "")

        tracker.record(before: first, after: second)
        tracker.record(before: unrelated, after: first)

        XCTAssertEqual(tracker.consume(before: first, after: second), .matched(hasMoreEdits: false))
        XCTAssertEqual(tracker.consume(before: unrelated, after: first), .matched(hasMoreEdits: false))
    }

    func testReturningToConsumedStateIsStillAnExpectedChange() {
        var tracker = ExpectedEditTracker()
        let first = ObservedTextState(left: "🏊", center: "", right: "")
        let second = ObservedTextState(left: "", center: "", right: "")

        tracker.record(before: first, after: second)
        XCTAssertEqual(tracker.consume(before: first, after: second), .matched(hasMoreEdits: false))
        tracker.record(before: second, after: first)
        XCTAssertEqual(tracker.consume(before: second, after: first), .matched(hasMoreEdits: false))
    }

    func testCompletedRoundTripStillConsumesItsUnchangedNotification() {
        var tracker = ExpectedEditTracker()
        let stable = ObservedTextState(left: "🏊", center: "", right: "")
        let temporary = ObservedTextState(left: "", center: "", right: "")

        tracker.record(before: stable, after: temporary)
        tracker.record(before: temporary, after: stable)

        XCTAssertEqual(tracker.consume(before: stable, after: stable), .matched(hasMoreEdits: false))
        XCTAssertEqual(tracker.consume(before: stable, after: stable), .noMatch)
        XCTAssertEqual(tracker.consume(before: stable, after: temporary), .noMatch)
    }

    func testRoundTripAndFollowingEditCanBeConsumedIncrementally() {
        var tracker = ExpectedEditTracker()
        let stable = ObservedTextState(left: "🏊", center: "", right: "")
        let temporary = ObservedTextState(left: "", center: "", right: "")
        let next = ObservedTextState(left: "🏊あ", center: "", right: "")

        tracker.record(before: stable, after: temporary)
        tracker.record(before: temporary, after: stable)
        tracker.record(before: stable, after: next)

        XCTAssertEqual(tracker.consume(before: stable, after: stable), .matched(hasMoreEdits: true))
        XCTAssertEqual(tracker.consume(before: stable, after: next), .matched(hasMoreEdits: false))
    }
}
