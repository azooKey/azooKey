import AzooKeyUtils
import Foundation
import struct KanaKanjiConverterModule.TemplateData

enum UserDictionaryMigrationRunner {
    private static let flagKey = "user_dict_migration_v1_done"
    private static let userDictKey = "user_dict"
    private static let backupKey = "user_dict_backup_v1"

    @MainActor static func runIfNeeded() {
        let templates = TemplateData.load()
        let raw = UserDefaults.standard.data(forKey: userDictKey)
        let entries: [UserDictionaryEntryCore]
        if let userDict = UserDictionary.get() {
            entries = userDict.items.map { item in
                .init(
                    ruby: item.ruby,
                    word: item.word,
                    isVerb: item.isVerb,
                    isPersonName: item.isPersonName,
                    isPlaceName: item.isPlaceName,
                    id: item.id,
                    isTemplateMode: item.isTemplateMode,
                    formatLiteral: item.formatLiteral
                )
            }
        } else {
            entries = []
        }

        let result = UserDictionaryMigrationCoordinator.runIfNeeded(userDefaults: .standard, flagKey: flagKey, backupKey: backupKey, currentRawData: raw, currentEntries: entries, templates: templates)
        if result.didMigrate {
            let newItems: [UserDictionaryData] = result.entries.map { e in
                UserDictionaryData(
                    ruby: e.ruby,
                    word: e.word,
                    isVerb: e.isVerb,
                    isPersonName: e.isPersonName,
                    isPlaceName: e.isPlaceName,
                    id: e.id,
                    shared: nil,
                    isTemplateMode: e.isTemplateMode,
                    formatLiteral: e.formatLiteral
                )
            }
            let updated = UserDictionary(items: newItems)
            updated.save()
            AdditionalDictManager().userDictUpdate()
        }
    }

    #if DEBUG
    static func resetFlagForDebug() {
        UserDefaults.standard.set(false, forKey: flagKey)
    }
    #endif
}
