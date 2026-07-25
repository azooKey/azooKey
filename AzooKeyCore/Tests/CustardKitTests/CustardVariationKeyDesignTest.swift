@testable import CustardKit
import XCTest

final class CustardVariationKeyDesignTest: XCTestCase {
    func testDecode() {
        do {
            let target = """
            {"label":{"text": "七月十九日は永遠に"}}
            """
            XCTAssertEqual(CustardVariationKeyDesign.quickDecode(target: target), .init(label: .text("七月十九日は永遠に")))
        }
        do {
            let target = """
            {"label":{"system_image": "piko_taro"}}
            """
            XCTAssertEqual(CustardVariationKeyDesign.quickDecode(target: target), .init(label: .systemImage("piko_taro")))
        }
    }

    func testEncode() {
        do {
            let target = CustardVariationKeyDesign(label: .systemImage("hichhich"))
            XCTAssertEqual(target.quickEncodeDecode(), target)
        }
        do {
            let target = CustardVariationKeyDesign(label: .text("椎乃味醂"))
            XCTAssertEqual(target.quickEncodeDecode(), target)
        }
    }
}
