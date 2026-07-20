import XCTest
@testable import CustardKit

final class CustardKeyLabelStyleTest: XCTestCase {
    func testDecode() {
        do {
            let target = """
            {"text": "HaTa"}
            """
            XCTAssertEqual(CustardKeyLabelStyle.quickDecode(target: target), .text("HaTa"))
        }
        do {
            let target = """
            {"system_image": "aris_to_teles"}
            """
            XCTAssertEqual(CustardKeyLabelStyle.quickDecode(target: target), .systemImage("aris_to_teles"))
        }
        do {
            let target = """
            {"systemimage": "aris_to_teles"}
            """
            XCTAssertEqual(CustardKeyLabelStyle.quickDecode(target: target), nil)
        }
        do {
            let target = """
            {"main_and_sub": "1"}
            """
            XCTAssertEqual(CustardKeyLabelStyle.quickDecode(target: target), nil)
        }
        do {
            let target = """
            {"type": "text", "text": "turing"}
            """
            XCTAssertEqual(CustardKeyLabelStyle.quickDecode(target: target), .text("turing"))
        }
        do {
            let target = """
            {"type": "system_image", "system_image": "que"}
            """
            XCTAssertEqual(CustardKeyLabelStyle.quickDecode(target: target), .systemImage("que"))
        }
        do {
            let target = """
            {"type": "main_and_sub", "main": "1", "sub": "☆♡◇"}
            """
            XCTAssertEqual(CustardKeyLabelStyle.quickDecode(target: target), .mainAndSub("1", "☆♡◇"))
        }
        do {
            let target = """
            {"type": "main_and_directions", "main": "1", "directions": {"left": "2", "top": "3"}}
            """
            XCTAssertEqual(CustardKeyLabelStyle.quickDecode(target: target), .mainAndDirections("1", .init(left: "2", top: "3")))
        }
    }

    func testEncode() {
        do {
            let target = CustardKeyLabelStyle.text("omiya")
            XCTAssertEqual(target.quickEncodeDecode(), target)
        }
        do {
            let target = CustardKeyLabelStyle.systemImage("kitanitatuya")
            XCTAssertEqual(target.quickEncodeDecode(), target)
        }
        do {
            let target = CustardKeyLabelStyle.mainAndSub("金", "money")
            XCTAssertEqual(target.quickEncodeDecode(), target)
        }
    }
}
