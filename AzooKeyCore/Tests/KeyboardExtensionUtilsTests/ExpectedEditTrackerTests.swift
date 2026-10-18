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
}
