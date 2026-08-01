import AzooKeyUtils
import XCTest

final class UserDictionaryWordFilterTests: XCTestCase {
    func test_preservesVariationSelector16() {
        let word = "♨️"

        XCTAssertEqual(UserDictionaryWordFilter.filter(word, denylist: []), word)
    }

    func test_appliesDenylistWithoutVariationSelector16() {
        XCTAssertNil(UserDictionaryWordFilter.filter("♨️", denylist: ["♨"]))
    }

    func test_returnsNonDeniedWord() {
        XCTAssertEqual(UserDictionaryWordFilter.filter("温泉", denylist: ["♨"]), "温泉")
    }
}
