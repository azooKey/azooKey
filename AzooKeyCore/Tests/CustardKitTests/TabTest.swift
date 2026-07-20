import XCTest
@testable import CustardKit

final class TabDataTest: XCTestCase {
    func testSystemTab() {
        XCTAssertEqual(TabData.SystemTab.flick_english.rawValue, "flick_english")
        XCTAssertEqual(TabData.SystemTab.qwerty_japanese.rawValue, "qwerty_japanese")
        XCTAssertEqual(TabData.SystemTab.last_tab.rawValue, "last_tab")
    }

}
