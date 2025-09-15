import AzooKeyUtils
import KanaKanjiConverterModule
import XCTest

final class UserDictionaryMigrationTests: XCTestCase {
    func makeEntry(id: Int, word: String) -> UserDictionaryEntryCore {
        .init(ruby: "てんぷれ", word: word, isVerb: false, isPersonName: false, isPlaceName: false, id: id, isTemplateMode: false, formatLiteral: nil)
    }

    func test_migrate_known_single_placeholder_merges_into_date_format() {
        let date = DateTemplateLiteral(format: "yyyy/MM/dd", type: .western, language: .japanese, delta: "0", deltaUnit: 1)
        let tpl = TemplateData(template: date.export(), name: "Today")
        let entry = makeEntry(id: 1, word: "prefix {{Today}} suffix")
        let (migrated, report) = UserDictionaryMigrator.migrate(entries: [entry], templates: [tpl])
        XCTAssertEqual(report.migratedCount, 1)
        XCTAssertEqual(report.skippedCount, 0)
        XCTAssertTrue(report.unsupportedEntryIDs.isEmpty)
        XCTAssertEqual(migrated.count, 1)
        XCTAssertTrue(migrated[0].isTemplateMode)
        XCTAssertEqual(migrated[0].word, "")
        XCTAssertNotNil(migrated[0].formatLiteral)
        // 逆変換してDateTemplateLiteralを取り出し、formatにprefix/suffixが入っていることを確認
        let td = TemplateData(template: migrated[0].formatLiteral!, name: "")
        guard let migratedDate = td.literal as? DateTemplateLiteral else {
            XCTFail("Expected DateTemplateLiteral"); return
        }
        XCTAssertEqual(migratedDate.format, "prefix yyyy/MM/dd suffix")
    }

    func test_migrate_unknown_single_placeholder_skipped() {
        let entry = makeEntry(id: 2, word: "{{Unknown}}")
        let (migrated, report) = UserDictionaryMigrator.migrate(entries: [entry], templates: [])
        XCTAssertEqual(report.migratedCount, 0)
        XCTAssertEqual(report.skippedCount, 1)
        XCTAssertTrue(report.unsupportedEntryIDs.isEmpty)
        XCTAssertEqual(migrated[0].word, "{{Unknown}}")
        XCTAssertFalse(migrated[0].isTemplateMode)
        XCTAssertNil(migrated[0].formatLiteral)
    }

    func test_migrate_multiple_placeholders_unsupported() {
        let entry = makeEntry(id: 3, word: "{{Date}} {{Time}}")
        let (migrated, report) = UserDictionaryMigrator.migrate(entries: [entry], templates: [])
        XCTAssertEqual(report.migratedCount, 0)
        XCTAssertEqual(report.skippedCount, 0)
        XCTAssertEqual(report.unsupportedEntryIDs, [3])
        XCTAssertTrue(UserDictionaryMigrator.isUnsupportedLegacy(word: migrated[0].word))
    }

    func test_random_with_prefix_suffix_is_unsupported() {
        let tpl = TemplateData(template: RandomTemplateLiteral(value: .int(from: 1, to: 6)).export(), name: "Rand")
        let entry = makeEntry(id: 4, word: "X {{Rand}} Y")
        let (_, report) = UserDictionaryMigrator.migrate(entries: [entry], templates: [tpl])
        XCTAssertEqual(report.migratedCount, 0)
        XCTAssertEqual(report.unsupportedEntryIDs, [4])
    }

    func test_random_without_affixes_migrates() {
        let tpl = TemplateData(template: RandomTemplateLiteral(value: .int(from: 1, to: 6)).export(), name: "Rand")
        let entry = makeEntry(id: 6, word: "{{Rand}}")
        let (migrated, report) = UserDictionaryMigrator.migrate(entries: [entry], templates: [tpl])
        XCTAssertEqual(report.migratedCount, 1)
        XCTAssertTrue(migrated[0].isTemplateMode)
        XCTAssertEqual(migrated[0].word, "")
        XCTAssertEqual(TemplateData(template: migrated[0].formatLiteral!, name: "").literal.export(), tpl.literal.export())
    }

    func test_date_prefix_suffix_are_quoted_in_format() {
        // prefix contains ASCII letters that could be interpreted as pattern letters if not quoted
        let date = DateTemplateLiteral(format: "yyyy", type: .western, language: .japanese, delta: "0", deltaUnit: 1)
        let tpl = TemplateData(template: date.export(), name: "年")
        let entry = makeEntry(id: 5, word: "year={{年}}")
        let (migrated, _) = UserDictionaryMigrator.migrate(entries: [entry], templates: [tpl])
        let td = TemplateData(template: migrated[0].formatLiteral!, name: "")
        guard let migratedDate = td.literal as? DateTemplateLiteral else {
            XCTFail("Expected DateTemplateLiteral"); return
        }
        // prefix should be quoted to avoid being parsed as pattern letters
        XCTAssertEqual(migratedDate.format, "'year='yyyy")
    }
}
