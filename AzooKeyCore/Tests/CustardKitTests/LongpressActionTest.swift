import XCTest
@testable import CustardKit

final class CodableLongpressActionTest: XCTestCase {
    func testDecodeLongpressAction() {
        let target = """
            {
                "start": [{
                    "type": "input",
                    "text": "ブルーホール"
                }],
                "repeat": [{
                    "type": "input",
                    "text": "青"
                }]
            }
            """
        let decoded = CodableLongpressActionData.quickDecode(target: target)
        // `duration: .normal`は省略可能
        XCTAssertEqual(decoded, .init(duration: .normal, start: [.input("ブルーホール")], repeat: [.input("青")]))
    }

    func testDecodeLongpressActionWithDurationSpec() {
        let target = """
            {
                "duration": "light",
                "start": [{
                    "type": "input",
                    "text": "藍色空間"
                }],
                "repeat": [{
                    "type": "input",
                    "text": "自然選択"
                }]
            }
            """
        let decoded = CodableLongpressActionData.quickDecode(target: target)
        // `duration: .normal`は省略可能
        XCTAssertEqual(decoded, .init(duration: .light, start: [.input("藍色空間")], repeat: [.input("自然選択")]))
    }

    func testEncodeLongpressAction() {
        let target = CodableLongpressActionData.init(start: [.complete, .dismissKeyboard, .moveCursor(-1)], repeat: [.moveCursor(-1)])
        XCTAssertEqual(target.quickEncodeDecode(), target)
    }

    func testStaticValue() {
        let target = CodableLongpressActionData.none
        XCTAssertEqual(target, CodableLongpressActionData.init(start: [], repeat: []))
    }

}
