import XCTest
@testable import CustardKit

final class ConstantsTest: XCTestCase {
    func testCustardVersion() {
        XCTAssertEqual(CustardVersion.v1_0.rawValue, "1.0")
    }

    func testFlickDirection() {
        XCTAssertEqual(FlickDirection.left.rawValue, "left")
        XCTAssertEqual(FlickDirection.top.rawValue, "top")
        XCTAssertEqual(FlickDirection.right.rawValue, "right")
        XCTAssertEqual(FlickDirection.bottom.rawValue, "bottom")
    }

    func testCustardLanguage() {
        XCTAssertEqual(CustardLanguage.el_GR.rawValue, "el_GR")
        XCTAssertEqual(CustardLanguage.ja_JP.rawValue, "ja_JP")
        XCTAssertEqual(CustardLanguage.en_US.rawValue, "en_US")
        XCTAssertEqual(CustardLanguage.none.rawValue, "none")
        XCTAssertEqual(CustardLanguage.undefined.rawValue, "undefined")
    }

    func testCustardInputStyle() {
        XCTAssertEqual(CustardInputStyle.direct.rawValue, "direct")
        XCTAssertEqual(CustardInputStyle.roman2kana.rawValue, "roman2kana")
    }

    func testCustardInterfaceStyle() {
        XCTAssertEqual(CustardInterfaceStyle.pcStyle.rawValue, "pc_style")
        XCTAssertEqual(CustardInterfaceStyle.tenkeyStyle.rawValue, "tenkey_style")
    }

}
