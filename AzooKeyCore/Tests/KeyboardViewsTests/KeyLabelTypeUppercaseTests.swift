import CustardKit
@testable import KeyboardViews
import XCTest

final class KeyLabelTypeUppercaseTests: XCTestCase {
    func test_textUppercasesOnlyWhenSingleInputMatches() {
        XCTAssertEqual(
            KeyLabelType.text("a").uppercasedForEnglishIfInputMatches(pressActions: [.input("a")]),
            .text("A")
        )
        XCTAssertEqual(
            KeyLabelType.text("a").uppercasedForEnglishIfInputMatches(pressActions: [.input("b")]),
            .text("a")
        )
        XCTAssertEqual(
            KeyLabelType.text("a").uppercasedForEnglishIfInputMatches(
                pressActions: [.input("a"), .moveCursor(1)]
            ),
            .text("a")
        )
    }

    func test_mainAndSubUppercasesOnlyMainLabel() {
        XCTAssertEqual(
            KeyLabelType.symbols(["a", "abc"])
                .uppercasedForEnglishIfInputMatches(pressActions: [.input("a")]),
            .symbols(["A", "abc"])
        )
    }

    func test_mainAndDirectionsUppercasesOnlyLabelsMatchingTheirActions() {
        let label = KeyLabelType.mainAndDirections(
            "a",
            CustardKeyDirectionalLabel(left: "b", top: "↑", right: "c", bottom: "D")
        )
        let flickMap: [FlickDirection: UnifiedVariation] = [
            .left: UnifiedVariation(label: .text("b"), pressActions: [.input("b")]),
            .top: UnifiedVariation(label: .text("↑"), pressActions: [.moveCursor(1)]),
            .right: UnifiedVariation(label: .text("x"), pressActions: [.input("x")]),
            .bottom: UnifiedVariation(label: .text("D"), pressActions: [.input("D")]),
        ]

        XCTAssertEqual(
            label.uppercasedForEnglishIfInputMatches(
                pressActions: [.input("a")],
                flickMap: flickMap
            ),
            .mainAndDirections(
                "A",
                CustardKeyDirectionalLabel(left: "B", top: "↑", right: "c", bottom: "D")
            )
        )
    }

    func test_flickVariationLabelUsesItsOwnInputAction() {
        let variation = UnifiedVariation(label: .text("b"), pressActions: [.input("b")])

        XCTAssertEqual(
            variation.uppercasedForEnglishIfInputMatches().label,
            .text("B")
        )
    }
}
