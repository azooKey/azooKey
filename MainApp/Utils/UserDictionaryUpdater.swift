import AzooKeyUtils
import Foundation
import KanaKanjiConverterModule
import KeyboardViews
import SwiftUtils

extension UserDictionaryUpdater {
    static func loadCharID() -> [Character: UInt8] {
        do {
            let chidURL = Bundle.main.bundleURL.appendingPathComponent("charID.chid", isDirectory: false)
            let string = try String(contentsOf: chidURL, encoding: .utf8)
            return [Character: UInt8].init(uniqueKeysWithValues: string.enumerated().map {($0.element, UInt8($0.offset))})
        } catch {
            debug("ファイルが存在しません: \(error)")
            return [:]
        }
    }
}

struct UserDictionaryUpdater {
    let templateData: [TemplateData]
    let char2UInt8: [Character: UInt8]
    let additionalSystemDictionaries: [AdditionalSystemDictionarySetting.SystemDictionaryType]
    let denylist: Set<String>

    /// `LOUDSBuilder.init`
    /// - Parameters:
    ///   - additionalSystemDictionaries: "emoji" and "kaomoji" can be in this
    ///   - blockTarget: Target items to remove from additional dictionary
    init(additionalSystemDictionaries: [AdditionalSystemDictionarySetting.SystemDictionaryType], denylist: Set<String>) {
        self.char2UInt8 = Self.loadCharID()
        self.templateData = TemplateData.load()
        self.additionalSystemDictionaries = additionalSystemDictionaries
        self.denylist = denylist
    }

    func loadUserDictInfo() -> (paths: [String], useradds: [UserDictionaryData], hotfixDictionary: [HotfixDictionaryV1.Entry]) {

        // データファイル名
        let paths: [String] = self.additionalSystemDictionaries.flatMap {
            switch $0 {
            case .emoji:
                if #available(iOS 18.4, *) {
                    ["emoji_dict_E16.0.txt"]
                } else {
                    // in this case, always satisfies #available(iOS 17.4, *)
                    ["emoji_dict_E15.1.txt"]
                }
            case .kaomoji:
                ["kaomoji_dict.tsv"]
            }
        }

        let useradds: [UserDictionaryData]
        if let dictionary = UserDictionary.get() {
            useradds = dictionary.items
        } else {
            useradds = []
        }

        let hotfix: [HotfixDictionaryV1.Entry]
        if let data = UserDefaults.standard.data(forKey: "azooKey_hotfix_dictionary_storage"),
           let dictionary = try? HotfixDictionaryV1.load(from: data) {
            var entries = dictionary.data
            entries.append(
                HotfixDictionaryV1.Entry(
                    word: String(dictionary.metadata.lastUpdate.dropLast(3)),
                    ruby: "ホットフィックスアップデート",
                    wordWeight: -15.0,
                    lcid: CIDData.固有名詞.cid,
                    rcid: CIDData.固有名詞.cid,
                    mid: MIDData.数.mid,
                    date: "",
                    author: "auto"
                )
            )
            print(entries)
            hotfix = entries
        } else {
            print("azooKey_hotfix_dictionary_storage not found")
            hotfix = []
        }

        return (paths, useradds, hotfix)
    }

    func makeDictionaryForm(_ data: UserDictionaryData) -> [String] {
        let katakanaRuby = data.ruby.toKatakana()
        if data.isVerb {
            let cid = 772
            let conjunctions = ConjunctionBuilder.getConjugations(data: (word: data.word, ruby: katakanaRuby, cid: cid), addStandardForm: true)
            return conjunctions.map {
                "\($0.ruby)\t\($0.word)\t\($0.cid)\t\($0.cid)\t\(501)\t-5.0000"
            }
        }
        let cid: Int
        if data.isPersonName {
            cid = CIDData.人名一般.cid
        } else if data.isPlaceName {
            cid = CIDData.地名一般.cid
        } else {
            cid = CIDData.固有名詞.cid
        }
        // 変換モード: 直接リテラル（<date …> / <random …> など）を埋め込む
        let exportedWord: String
        if data.isTemplateMode, let literal = data.formatLiteral, !literal.isEmpty {
            exportedWord = literal
        } else {
            exportedWord = data.word
        }
        return ["\(katakanaRuby)\t\(exportedWord)\t\(cid)\t\(cid)\t\(501)\t-5.0000"]
    }

    func makeDictionaryForm(_ data: HotfixDictionaryV1.Entry) -> [String] {
        let katakanaRuby = data.ruby.toKatakana()
        return ["\(katakanaRuby)\t\(data.word)\t\(data.lcid)\t\(data.rcid)\t\(data.mid)\t\(data.wordWeight)"]
    }

    @MainActor func process() {
        var (paths, useradds, hotfix) = self.loadUserDictInfo()
        // 重複削除（ユーザ辞書とホットフィックスの重複を取り除く）
        hotfix = hotfix.filter { hotfixEntry in
            !useradds.contains {
                $0.word == hotfixEntry.word && $0.ruby.toKatakana() == hotfixEntry.ruby.toKatakana()
            }
        }

        // すべての行を読み込んで、DicdataElementへ変換
        var entries: [DicdataElement] = []
        var shortcutEntries: [DicdataElement] = []
        do {
            var csvLines: [Substring] = []
            for path in paths {
                let string = try String(contentsOfFile: Bundle.main.bundlePath + "/" + path, encoding: .utf8)
                csvLines.append(contentsOf: string.split(separator: "\n"))
            }
            csvLines.append(contentsOf: useradds.flatMap { self.makeDictionaryForm($0) }.map { Substring($0) })
            csvLines.append(contentsOf: hotfix.flatMap { self.makeDictionaryForm($0) }.map { Substring($0) })

            for line in csvLines {
                let items = line.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
                guard items.count == 6 else {
                    continue
                }
                let ruby = items[0]
                let rawWord = items[1]
                // variation selector を除去
                let normalizedWord = String(rawWord.unicodeScalars.filter { $0.value != 0xFE0F })
                // denylist フィルタ
                guard normalizedWord.allSatisfy({ !self.denylist.contains(String($0)) }) else {
                    continue
                }

                let lcid = Int(items[2]) ?? 0
                let rcid = Int(items[3]) ?? lcid
                let mid = Int(items[4]) ?? 0
                let value = PValue(items[5]) ?? -30.0
                let entry = DicdataElement(
                    word: normalizedWord,
                    ruby: ruby,
                    lcid: lcid,
                    rcid: rcid,
                    mid: mid,
                    value: value
                )
                // templateが含まれる場合ショートカット扱いする
                let isShortcut = Candidate.parseTemplate(normalizedWord) != normalizedWord
                if isShortcut {
                    shortcutEntries.append(entry)
                } else {
                    entries.append(entry)
                }
            }
        } catch {
            debug("ファイルが存在しません: \(error)")
            return
        }

        // 書き出し先と設定
        let directoryURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: SharedStore.appGroupKey)!
        // charID を利用（既存のマッピングを維持）
        let cmap = self.char2UInt8

        do {
            try DictionaryBuilder.exportDictionary(
                entries: entries,
                to: directoryURL,
                baseName: "user",
                shardByFirstCharacter: false,
                char2UInt8: cmap
            )
            try DictionaryBuilder.exportDictionary(
                entries: shortcutEntries,
                to: directoryURL,
                baseName: "user_shortcuts",
                shardByFirstCharacter: false,
                char2UInt8: cmap
            )
            debug(#function, "successfully exported dictionary", directoryURL)

            var manager = MessageManager()
            manager.done(.ver1_9_user_dictionary_update)
        } catch {
            debug(#function, "failed to export dictionary:", error)
        }
    }

}
