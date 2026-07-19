import XCTest
@testable import CustardKit

final class CustardInterfaceVariationTest: XCTestCase {
    func testDecode() {
        do {
            let target = """
            {
                "type": "flick_variation",
                "direction": "left",
                "key": {
                    "design": {"label":{"system_image": "instagram"}},
                    "press_actions": [],
                    "longpress_actions": {
                        "start": [],
                        "repeat": []
                    }
                }
            }
            """
            XCTAssertEqual(CustardInterfaceVariation.quickDecode(target: target), .init(type: .flickVariation(.left), key: .init(design: .init(label: .systemImage("instagram")), press_actions: [], longpress_actions: .none)))
        }
        do {
            let target = """
            {
                "type": "longpress_variation",
                "key": {
                    "design": {"label":{"system_image": "qiita"}},
                    "press_actions": [],
                    "longpress_actions": {
                        "start": [],
                        "repeat": []
                    }
                }
            }
            """
            XCTAssertEqual(CustardInterfaceVariation.quickDecode(target: target), .init(type: .longpressVariation, key: .init(design: .init(label: .systemImage("qiita")), press_actions: [], longpress_actions: .none)))
        }
    }

    func testEncode() {
        do {
            let target = CustardInterfaceVariation.init(type: .flickVariation(.bottom), key: .init(design: .init(label: .text("facebook")), press_actions: [], longpress_actions: .none))
            XCTAssertEqual(target.quickEncodeDecode(), target)
        }
        do {
            let target = CustardInterfaceVariation.init(type: .longpressVariation, key: .init(design: .init(label: .systemImage("twitter")), press_actions: [], longpress_actions: .none))
            XCTAssertEqual(target.quickEncodeDecode(), target)
        }
    }

}
