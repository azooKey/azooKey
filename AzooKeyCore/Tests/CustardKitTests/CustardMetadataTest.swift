import XCTest
@testable import CustardKit

final class CustardMetadataTest: XCTestCase {
    func testDecode() {
        do {
            let target = """
            {
                "custard_version": "1.0",
                "display_name": "٩(๑`^´๑)۶",
            }
            """
            XCTAssertEqual(CustardMetadata.quickDecode(target: target), .init(custard_version: .v1_0, display_name: "٩(๑`^´๑)۶"))
        }
    }

    func testEncode() {
        do {
            let target = CustardMetadata.init(custard_version: .v1_0, display_name: "unknown")
            XCTAssertEqual(target.quickEncodeDecode(), target)
        }
        do {
            let target = CustardMetadata.init(custard_version: .v1_0, display_name: "unhappy")
            XCTAssertEqual(target.quickEncodeDecode(), target)
        }
    }

}
