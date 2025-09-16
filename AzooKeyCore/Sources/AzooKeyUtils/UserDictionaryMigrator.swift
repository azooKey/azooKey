import Foundation
import KanaKanjiConverterModule

public struct UserDictionaryEntryCore: Equatable {
    public var ruby: String
    public var word: String
    public var isVerb: Bool
    public var isPersonName: Bool
    public var isPlaceName: Bool
    public var id: Int
    public var isTemplateMode: Bool
    public var formatLiteral: String?

    public init(ruby: String, word: String, isVerb: Bool, isPersonName: Bool, isPlaceName: Bool, id: Int, isTemplateMode: Bool, formatLiteral: String?) {
        self.ruby = ruby
        self.word = word
        self.isVerb = isVerb
        self.isPersonName = isPersonName
        self.isPlaceName = isPlaceName
        self.id = id
        self.isTemplateMode = isTemplateMode
        self.formatLiteral = formatLiteral
    }
}

public struct MigrationReport: Equatable {
    public var migratedCount: Int
    public var skippedCount: Int
    public var unsupportedEntryIDs: [Int]

    public init(migratedCount: Int = 0, skippedCount: Int = 0, unsupportedEntryIDs: [Int] = []) {
        self.migratedCount = migratedCount
        self.skippedCount = skippedCount
        self.unsupportedEntryIDs = unsupportedEntryIDs
    }
}

public enum UserDictionaryMigrator {
    /// date format内にリテラル文字列を安全に埋め込むためのクォート処理
    /// - ICU/DateFormatterの仕様では、A-Za-z はパターン文字として解釈され得るため、
    ///   任意の文字列は基本的にシングルクォートで囲み、内部の'は''へエスケープする。
    private static func quoteForDateFormat(_ literal: String) -> String {
        guard !literal.isEmpty else {
            return ""
        }
        // ' → '' にエスケープし、全体を'...'で囲む
        let escaped = literal.replacingOccurrences(of: "'", with: "''")
        return "'" + escaped + "'"
    }
    /// 旧来の `{{name}}` プレースホルダを走査
    private static func scanPlaceholders(_ word: String) -> [(range: Range<String.Index>, name: String)] {
        var results: [(Range<String.Index>, String)] = []
        var searchStart = word.startIndex
        while searchStart < word.endIndex {
            guard let open = word[searchStart...].firstIndex(of: "{") else { break }
            let nextIndex = word.index(after: open)
            guard nextIndex < word.endIndex, word[nextIndex] == "{" else {
                searchStart = word.index(after: open)
                continue
            }
            // find closing "}}"
            var closeSearchStart = word.index(after: nextIndex)
            var foundClose: String.Index?
            while closeSearchStart < word.endIndex {
                guard let close = word[closeSearchStart...].firstIndex(of: "}") else { break }
                let afterClose = word.index(after: close)
                if afterClose < word.endIndex, word[afterClose] == "}" {
                    foundClose = close
                    break
                }
                closeSearchStart = word.index(after: close)
            }
            guard let close = foundClose else { break }
            let nameStart = word.index(after: nextIndex)
            let nameEndExclusive = close
            let name = String(word[nameStart..<nameEndExclusive])
            let afterSecondBrace = word.index(after: word.index(after: close))
            let fullRange: Range<String.Index> = open..<afterSecondBrace
            results.append((fullRange, name))
            searchStart = afterSecondBrace
        }
        return results
    }

    /// 単一テンプレートのみ移行。複数は非対応として扱う。
    public static func migrate(entries: [UserDictionaryEntryCore], templates: [TemplateData]) -> (migrated: [UserDictionaryEntryCore], report: MigrationReport) {
        var report = MigrationReport()
        var migratedEntries: [UserDictionaryEntryCore] = []

        for var entry in entries {
            // すでに新形式ならスキップ
            if entry.isTemplateMode, entry.formatLiteral != nil {
                migratedEntries.append(entry)
                continue
            }
            let placeholders = scanPlaceholders(entry.word)
            if placeholders.isEmpty {
                report.skippedCount += 1
                migratedEntries.append(entry)
                continue
            }
            // 複数テンプレは非対応
            if placeholders.count >= 2 {
                report.unsupportedEntryIDs.append(entry.id)
                migratedEntries.append(entry)
                continue
            }
            // 単一テンプレ
            let (range, name) = placeholders[0]
            // 名前解決
            if let t = templates.first(where: { $0.name == name }) {
                let prefix = String(entry.word[..<range.lowerBound])
                let suffix = String(entry.word[range.upperBound...])
                // 日付テンプレはフォーマットへ prefix/suffix を取り込む
                if let date = t.literal as? DateTemplateLiteral {
                    var newDate = date
                    // prefix/suffix はリテラルとして扱うため、date format へクォートして埋め込む
                    let quotedPrefix = quoteForDateFormat(prefix)
                    let quotedSuffix = quoteForDateFormat(suffix)
                    newDate.format = quotedPrefix + date.format + quotedSuffix
                    entry.isTemplateMode = true
                    entry.formatLiteral = newDate.export()
                    entry.word = ""
                } else if t.literal is RandomTemplateLiteral {
                    // ランダム + prefix/suffix は廃止: 未移行（unsupported）として扱う
                    if !prefix.isEmpty || !suffix.isEmpty {
                        report.unsupportedEntryIDs.append(entry.id)
                        migratedEntries.append(entry)
                        continue
                    }
                    // 純粋なランダム（前後なし）は移行
                    let resolved = t.literal.export()
                    entry.isTemplateMode = true
                    entry.formatLiteral = resolved
                    entry.word = ""
                } else {
                    // それ以外（例: ランダム）は外側に連結
                    let resolved = t.literal.export()
                    entry.isTemplateMode = true
                    entry.formatLiteral = prefix + resolved + suffix
                    entry.word = ""
                }
                report.migratedCount += 1
                migratedEntries.append(entry)
            } else {
                // 未知テンプレ名はテンプレ扱いせず、そのまま残す
                report.skippedCount += 1
                migratedEntries.append(entry)
            }
        }
        return (migratedEntries, report)
    }

    /// 旧来の `{{...}}` が2つ以上含まれるか
    public static func isUnsupportedLegacy(word: String) -> Bool {
        scanPlaceholders(word).count >= 2
    }

    /// ランダムテンプレートに前後文字が付随する場合は未対応（廃止）
    public static func isUnsupportedRandomWithAffixes(word: String, templates: [TemplateData]) -> Bool {
        let placeholders = scanPlaceholders(word)
        guard placeholders.count == 1 else { return false }
        let (range, name) = placeholders[0]
        guard let t = templates.first(where: { $0.name == name }) else { return false }
        guard t.literal is RandomTemplateLiteral else { return false }
        let prefix = String(word[..<range.lowerBound])
        let suffix = String(word[range.upperBound...])
        return !prefix.isEmpty || !suffix.isEmpty
    }
}

protocol KeyValueBoolDataStore {
    func data(forKey key: String) -> Data?
    func set(_ data: Data, forKey key: String)
    func bool(forKey key: String) -> Bool
    func set(_ value: Bool, forKey key: String)
}

public struct UserDictionaryMigrationCoordinator {
    @MainActor static func runIfNeeded(store: any KeyValueBoolDataStore, flagKey: String = "user_dict_migration_v1_done", backupKey: String = "user_dict_backup_v1", currentRawData: Data?, currentEntries: [UserDictionaryEntryCore], templates: [TemplateData]) -> (entries: [UserDictionaryEntryCore], didMigrate: Bool) {
        if store.bool(forKey: flagKey) {
            return (currentEntries, false)
        }
        // Skip for fresh installs on or after nextVersion
        if let initial = SharedStore.initialAppVersion, initial >= .nextVersion {
            store.set(true, forKey: flagKey)
            return (currentEntries, false)
        }
        // backup once
        if store.data(forKey: backupKey) == nil, let raw = currentRawData {
            store.set(raw, forKey: backupKey)
        }
        let (migrated, report) = UserDictionaryMigrator.migrate(entries: currentEntries, templates: templates)
        store.set(true, forKey: flagKey)
        return (migrated, report.migratedCount > 0)
    }
}

// Adapters
struct KeyValueBoolDataStoreWrapper: KeyValueBoolDataStore {
    private let defaults: UserDefaults
    public init(defaults: UserDefaults) { self.defaults = defaults }
    public func data(forKey key: String) -> Data? { defaults.data(forKey: key) }
    public func set(_ data: Data, forKey key: String) { defaults.set(data, forKey: key) }
    public func bool(forKey key: String) -> Bool { defaults.bool(forKey: key) }
    public func set(_ value: Bool, forKey key: String) { defaults.set(value, forKey: key) }
}

public extension UserDictionaryMigrationCoordinator {
    @MainActor static func runIfNeeded(userDefaults: UserDefaults, flagKey: String = "user_dict_migration_v1_done", backupKey: String = "user_dict_backup_v1", currentRawData: Data?, currentEntries: [UserDictionaryEntryCore], templates: [TemplateData]) -> (entries: [UserDictionaryEntryCore], didMigrate: Bool) {
        let wrapper = KeyValueBoolDataStoreWrapper(defaults: userDefaults)
        return runIfNeeded(store: wrapper, flagKey: flagKey, backupKey: backupKey, currentRawData: currentRawData, currentEntries: currentEntries, templates: templates)
    }
}
