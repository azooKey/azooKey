import XCTest
@testable import CustardKit

final class CustardInterfaceSystemKeyTest: XCTestCase {
    func testDecode() {
        XCTAssertEqual(CustardInterfaceSystemKey.quickDecode(target: #"{"type": "change_keyboard"}"#), .changeKeyboard)
        XCTAssertEqual(CustardInterfaceSystemKey.quickDecode(target: #"{"type": "flick_kogaki"}"#), .flickKogaki)
        XCTAssertEqual(CustardInterfaceSystemKey.quickDecode(target: #"{"type": "flick_kutoten"}"#), .flickKutoten)
        XCTAssertEqual(CustardInterfaceSystemKey.quickDecode(target: #"{"type": "flick_hira_tab"}"#), .flickHiraTab)
        XCTAssertEqual(CustardInterfaceSystemKey.quickDecode(target: #"{"type": "flick_abc_tab"}"# ), .flickAbcTab)
        XCTAssertEqual(CustardInterfaceSystemKey.quickDecode(target: #"{"type": "flick_star123_tab"}"#), .flickStar123Tab)
        XCTAssertEqual(CustardInterfaceSystemKey.quickDecode(target: #"{"type": "enter"}"#), .enter)
    }

    func testEncode() {
        XCTAssertEqual(CustardInterfaceSystemKey.changeKeyboard.quickEncodeDecode(), .changeKeyboard)
        XCTAssertEqual(CustardInterfaceSystemKey.flickKogaki.quickEncodeDecode(), .flickKogaki)
        XCTAssertEqual(CustardInterfaceSystemKey.flickKutoten.quickEncodeDecode(), .flickKutoten)
        XCTAssertEqual(CustardInterfaceSystemKey.flickHiraTab.quickEncodeDecode(), .flickHiraTab)
        XCTAssertEqual(CustardInterfaceSystemKey.flickAbcTab.quickEncodeDecode(), .flickAbcTab)
        XCTAssertEqual(CustardInterfaceSystemKey.flickStar123Tab.quickEncodeDecode(), .flickStar123Tab)
        XCTAssertEqual(CustardInterfaceSystemKey.enter.quickEncodeDecode(), .enter)
    }

}
