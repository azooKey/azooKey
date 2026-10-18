import XCTest
@testable import KeyboardExtensionUtils

final class TextChangeContextTests: XCTestCase {
    private func state(_ left: String, right: String = "") -> ObservedTextState {
        .init(left: left, center: "", right: right)
    }

    func testRepeatedWillChangePreservesOriginalContext() {
        var context = TextChangeContext()
        context.willChange(before: state("桜"))
        context.willChange(before: state("", right: "桜"))
        XCTAssertEqual(context.before, state("桜"))
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
        context.willChange(before: state("\n🏊"))
        context.willChange(before: state("\n"))
        XCTAssertEqual(context.before, state("\n🏊"))
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
