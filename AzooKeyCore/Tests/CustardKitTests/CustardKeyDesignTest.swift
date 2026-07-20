import XCTest
@testable import CustardKit

final class CustardKeyDesignTest: XCTestCase {
    func testDecode() {
        do {
            let target = """
            {"label":{"text": "虚無"},"color": "special"}
            """
            XCTAssertEqual(CustardKeyDesign.quickDecode(target: target), .init(label: .text("虚無"), color: .special))
        }
        do {
            let target = """
            {"label":{"text": "義務"},"color": "unimportant"}
            """
            XCTAssertEqual(CustardKeyDesign.quickDecode(target: target), .init(label: .text("義務"), color: .unimportant))
        }
        do {
            let target = """
            {"label":{"system_image": "kyomukyomupurin"},"color": "selected"}
            """
            XCTAssertEqual(CustardKeyDesign.quickDecode(target: target), .init(label: .systemImage("kyomukyomupurin"), color: .selected))
        }
    }

    func testEncode() {
        do {
            let target = CustardKeyDesign.init(label: .systemImage("uchuhi"), color: .normal)
            XCTAssertEqual(target.quickEncodeDecode(), target)
        }
        do {
            let target = CustardKeyDesign.init(label: .text("緑和"), color: .special)
            XCTAssertEqual(target.quickEncodeDecode(), target)
        }
    }
}
