import XCTest
@testable import CustardKit

final class CustardInterfaceLayoutTest: XCTestCase {
    func testDecode() {
        do {
            let target = """
            {
                "type": "grid_fit",
                "row_count": 5,
                "column_count": 4
            }
            """
            XCTAssertEqual(CustardInterfaceLayout.quickDecode(target: target), .gridFit(.init(rowCount: 5, columnCount: 4)))
        }
        do {
            let target = """
            {
                "type": "grid_scroll",
                "direction": "vertical",
                "row_count": 8,
                "column_count": 4.9
            }
            """
            XCTAssertEqual(CustardInterfaceLayout.quickDecode(target: target), .gridScroll(.init(direction: .vertical, rowCount: 8, columnCount: 4.9)))
        }
        do {
            let target = """
            {
                "type": "grid_fit",
                "direction": "vertical",
                "row_count": 4.2,
                "column_count": 3.1
            }
            """
            XCTAssertEqual(CustardInterfaceLayout.quickDecode(target: target), .gridFit(.init(rowCount: 4, columnCount: 3)))
        }
    }

    func testEncode() {
        do {
            let target = CustardInterfaceLayout.gridFit(.init(rowCount: 3, columnCount: 5))
            XCTAssertEqual(target.quickEncodeDecode(), target)
        }
        do {
            let target = CustardInterfaceLayout.gridScroll(.init(direction: .horizontal, rowCount: 3.1, columnCount: 2.9))
            XCTAssertEqual(target.quickEncodeDecode(), target)
        }
        do {
            let target = CustardInterfaceLayout.gridScroll(.init(direction: .vertical, rowCount: 10, columnCount: 1))
            XCTAssertEqual(target.quickEncodeDecode(), target)
        }
    }
}
