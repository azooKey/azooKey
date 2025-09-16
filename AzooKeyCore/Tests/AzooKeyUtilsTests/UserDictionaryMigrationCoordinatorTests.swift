@testable import AzooKeyUtils
import KanaKanjiConverterModule
import XCTest

private final class FakeStore: KeyValueBoolDataStore {
    var dataStore: [String: Data] = [:]
    var boolStore: [String: Bool] = [:]
    func data(forKey key: String) -> Data? {
        dataStore[key]
    }
    func set(_ data: Data, forKey key: String) {
        dataStore[key] = data
    }
    func bool(forKey key: String) -> Bool {
        boolStore[key] ?? false
    }
    func set(_ value: Bool, forKey key: String) {
        boolStore[key] = value
    }
}

final class UserDictionaryMigrationCoordinatorTests: XCTestCase {
    func makeEntry(id: Int, word: String) -> UserDictionaryEntryCore {
        .init(ruby: "てんぷれ", word: word, isVerb: false, isPersonName: false, isPlaceName: false, id: id, isTemplateMode: false, formatLiteral: nil)
    }

    func test_backup_created_once_and_not_overwritten() {
        let store = FakeStore()
        let flagKey = "flag"
        let backupKey = "backup"
        let rawV1 = "v1".data(using: .utf8)
        let templates: [TemplateData] = []
        let entries: [UserDictionaryEntryCore] = []

        // First run: creates backup and sets flag
        let r1 = UserDictionaryMigrationCoordinator.runIfNeeded(store: store, flagKey: flagKey, backupKey: backupKey, currentRawData: rawV1, currentEntries: entries, templates: templates)
        XCTAssertFalse(r1.didMigrate)
        XCTAssertEqual(store.data(forKey: backupKey), rawV1)
        XCTAssertTrue(store.bool(forKey: flagKey))

        // Reset only flag, change raw to v2
        store.set(false, forKey: flagKey)
        let rawV2 = "v2".data(using: .utf8)
        let r2 = UserDictionaryMigrationCoordinator.runIfNeeded(store: store, flagKey: flagKey, backupKey: backupKey, currentRawData: rawV2, currentEntries: entries, templates: templates)
        XCTAssertFalse(r2.didMigrate)
        // backup must remain v1
        XCTAssertEqual(store.data(forKey: backupKey), rawV1)
        XCTAssertTrue(store.bool(forKey: flagKey))
    }
}
