import XCTest
@testable import KeyboardExtensionUtils

final class TextChangeContextTests: XCTestCase {
    private func state(_ left: String, right: String = "") -> ObservedTextState {
        .init(left: left, center: "", right: right)
    }

    func testRepeatedWillChangePreservesOriginalContext() {
        var context = TextChangeContext()
        XCTAssertTrue(context.willChange(before: state("桜")))
        XCTAssertFalse(context.willChange(before: state("", right: "桜")))
        XCTAssertEqual(context.before, state("桜"))
    }

    func testLegacyWillChangePreservesExpectedEditContext() {
        var context = TextChangeContext()
        context.willChange(before: state("\nさく"), replacingExpectedEditContext: false)
        context.didConsumeExpectedEdit(after: state("\n"), hasMoreEdits: true)

        XCTAssertFalse(context.willChange(before: state("\n🏊"), replacingExpectedEditContext: false))
        XCTAssertEqual(context.before, state("\n"))
    }

    func testLegacyWillChangeAcceptsNextChangeAfterCompletionOrReset() {
        var context = TextChangeContext()
        context.willChange(before: state("さく"), replacingExpectedEditContext: false)
        context.didConsumeExpectedEdit(after: state("桜"), hasMoreEdits: false)
        XCTAssertTrue(context.willChange(before: state("次の入力"), replacingExpectedEditContext: false))
        XCTAssertEqual(context.before, state("次の入力"))

        context.reset()
        XCTAssertTrue(context.willChange(before: state("別の入力"), replacingExpectedEditContext: false))
        XCTAssertEqual(context.before, state("別の入力"))
    }

    func testExpectedEditRetainsContextForDidChangeWithoutWillChange() {
        var context = TextChangeContext()
        context.willChange(before: state("さく"))
        context.didConsumeExpectedEdit(after: state("さ"), hasMoreEdits: true)
        XCTAssertEqual(context.before, state("さ"))
        context.didConsumeExpectedEdit(after: state(""), hasMoreEdits: true)
        XCTAssertEqual(context.before, state(""))
        context.didConsumeExpectedEdit(after: state("桜"), hasMoreEdits: false)
        XCTAssertNil(context.before)
    }

    func testNewWillChangeAfterExpectedEditUsesCurrentComposition() {
        for lineBreakCount in [1, 2, 5] {
            let prefix = String(repeating: "\n", count: lineBreakCount)
            var context = TextChangeContext()
            context.willChange(before: state(prefix + "さく"))
            // The host has notified only an intermediate internal deletion.
            context.didConsumeExpectedEdit(after: state(prefix), hasMoreEdits: true)

            // A new host change starts after further keyboard input.
            context.willChange(before: state(prefix + "🏊"))
            let afterMovingToBlankLine = state("\n")
            XCTAssertEqual(context.before, state(prefix + "🏊"))
            XCTAssertNotEqual(context.before, afterMovingToBlankLine)
        }
    }

    func testRepeatedWillChangeAfterContinuationKeepsFirstFreshContext() {
        var context = TextChangeContext()
        context.didConsumeExpectedEdit(after: state("\n"), hasMoreEdits: true)
        XCTAssertTrue(context.willChange(before: state("\n🏊")))
        XCTAssertFalse(context.willChange(before: state("\n")))
        XCTAssertEqual(context.before, state("\n🏊"))
    }

    func testDuplicateWillChangeDoesNotDiscardEditsForOriginalNotification() {
        var context = TextChangeContext()
        var tracker = ExpectedEditTracker()
        let initial = state("さく")
        let final = state("桜")
        XCTAssertTrue(context.willChange(before: initial))
        tracker.record(before: initial, after: final)

        if context.willChange(before: final) {
            tracker.discardEditsReflected(in: final)
        }

        XCTAssertEqual(context.before, initial)
        XCTAssertEqual(tracker.consume(before: initial, after: final), .matched(hasMoreEdits: false))
    }

    func testPendingRoundTripKeepsIntermediateCallbacksForOriginalNotification() {
        var context = TextChangeContext()
        var tracker = ExpectedEditTracker()
        let composition = state("\n🏊")
        let intermediate = state("\n")
        context.willChange(before: composition)
        tracker.record(before: composition, after: intermediate)
        tracker.record(before: intermediate, after: composition)

        if context.willChange(before: composition) {
            tracker.discardEditsReflected(in: composition)
        }

        XCTAssertEqual(tracker.consume(before: composition, after: intermediate), .matched(hasMoreEdits: true))
        context.didConsumeExpectedEdit(after: intermediate, hasMoreEdits: true)
        XCTAssertEqual(context.before, intermediate)
        XCTAssertEqual(tracker.consume(before: intermediate, after: composition), .matched(hasMoreEdits: false))
    }

    func testSamePositionTapStillHasEqualBeforeAndAfterContext() {
        var context = TextChangeContext()
        context.didConsumeExpectedEdit(after: state("\n"), hasMoreEdits: true)
        context.willChange(before: state("\n桜"))
        XCTAssertEqual(context.before, state("\n桜"))
    }

    func testResetDiscardsUnfinishedChange() {
        var context = TextChangeContext()
        context.willChange(before: state("桜"))
        context.reset()
        XCTAssertNil(context.before)
        context.willChange(before: state("次の入力"))
        XCTAssertEqual(context.before, state("次の入力"))
    }
}
