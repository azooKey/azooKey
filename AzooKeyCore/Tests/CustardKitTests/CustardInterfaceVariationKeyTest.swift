import XCTest
@testable import CustardKit

final class CustardInterfaceVariationKeyTest: XCTestCase {
    func testDecode() {
        do {
            let target = """
            {
                "design": {"label":{"text": "笹川真生"}},
                "press_actions": [{
                    "type": "input",
                    "text": "ねぇママ",
                }],
                "longpress_actions": {
                    "start": [{
                        "type": "input",
                        "text": "官能と飽食",
                    }],
                    "repeat": [{
                        "type": "input",
                        "text": "滞る夜",
                    }]
                }
            }
            """
            XCTAssertEqual(CustardInterfaceVariationKey.quickDecode(target: target), .init(design: .init(label: .text("笹川真生")), press_actions: [.input("ねぇママ")], longpress_actions: .init(start: [.input("官能と飽食")], repeat: [.input("滞る夜")])))
        }
    }

    func testEncode() {
        do {
            let target = CustardInterfaceVariationKey.init(design: .init(label: .systemImage("que")), press_actions: [.dismissKeyboard, .complete, .replaceDefault(.default)], longpress_actions: .none)
            XCTAssertEqual(target.quickEncodeDecode(), target)
        }
        do {
            let target = CustardInterfaceVariationKey.init(design: .init(label: .text("∫")), press_actions: [.input("√")], longpress_actions: .init(start: [.input("≈")]))
            XCTAssertEqual(target.quickEncodeDecode(), target)
        }
    }

}
