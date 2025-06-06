//
//  LOUDSBuilder.swift
//  MainApp
//
//  Created by ensan on 2020/11/13.
//  Copyright © 2020 ensan. All rights reserved.
//

import AzooKeyUtils
import Foundation
import struct KanaKanjiConverterModule.TemplateData
import enum KanaKanjiConverterModule.CIDData
import enum KanaKanjiConverterModule.MIDData
import KeyboardViews
import SwiftUtils

extension LOUDSBuilder {
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

struct LOUDSBuilder {
    let txtFileSplit: Int
    let templateData: [TemplateData]
    let char2UInt8: [Character: UInt8]
    let additionalSystemDictionaries: [AdditionalSystemDictionarySetting.SystemDictionaryType]
    let denylist: Set<String>

    /// `LOUDSBuilder.init`
    /// - Parameters:
    ///   - txtFileSplit: Entry-per-File
    ///   - additionalSystemDictionaries: "emoji" and "kaomoji" can be in this
    ///   - blockTarget: Target items to remove from additional dictionary
    init(txtFileSplit: Int, additionalSystemDictionaries: [AdditionalSystemDictionarySetting.SystemDictionaryType], denylist: Set<String>) {
        self.txtFileSplit = txtFileSplit
        self.char2UInt8 = Self.loadCharID()
        self.templateData = TemplateData.load()
        self.additionalSystemDictionaries = additionalSystemDictionaries
        self.denylist = denylist
    }

    private func BoolToUInt64(_ bools: [Bool]) -> [UInt64] {
        let unit = 64
        let value = bools.count.quotientAndRemainder(dividingBy: unit)
        let _bools = bools + [Bool].init(repeating: true, count: (unit - value.remainder) % unit)
        var result = [UInt64]()
        for i in 0...value.quotient {
            var value: UInt64 = 0
            for j in 0..<unit {
                value += (_bools[i * unit + j] ? 1 : 0) << (unit - j - 1)
            }
            result.append(value)
        }
        return result
    }

    struct DataBlock {
        var count: Int {
            data.count
        }
        var ruby: String
        var data: [(word: String, lcid: Int, rcid: Int, mid: Int, score: Float)]

        init(entries: [String]) {
            self.ruby = ""
            self.data = []

            for entry in entries {
                let items = entry.utf8.split(separator: UInt8(ascii: "\t"), omittingEmptySubsequences: false).map {String($0)!}
                assert(items.count == 6)
                let ruby = String(items[0])
                let word = items[1].isEmpty ? self.ruby : String(items[1])
                let lcid = Int(items[2]) ?? .zero
                let rcid = Int(items[3]) ?? lcid
                let mid = Int(items[4]) ?? .zero
                let score = Float(items[5]) ?? -30.0

                if self.ruby.isEmpty {
                    self.ruby = ruby
                } else {
                    assert(self.ruby == ruby)
                }
                self.data.append((word, lcid, rcid, mid, score))
            }
        }

        func makeLoudstxt3Entry() -> Data {
            var data = Data()
            // エントリのカウントを2byteでエンコード
            var count = UInt16(self.count)
            data.append(contentsOf: Data(bytes: &count, count: MemoryLayout<UInt16>.size))

            // 数値データ部をエンコード
            // 10byteが1つのエントリに対応するので、10*count byte
            for (_, lcid, rcid, mid, score) in self.data {
                assert(0 <= lcid && lcid <= UInt16.max)
                assert(0 <= rcid && rcid <= UInt16.max)
                assert(0 <= mid && mid <= UInt16.max)
                var lcid = UInt16(lcid)
                var rcid = UInt16(rcid)
                var mid = UInt16(mid)
                data.append(contentsOf: Data(bytes: &lcid, count: MemoryLayout<UInt16>.size))
                data.append(contentsOf: Data(bytes: &rcid, count: MemoryLayout<UInt16>.size))
                data.append(contentsOf: Data(bytes: &mid, count: MemoryLayout<UInt16>.size))
                var score = Float32(score)
                data.append(contentsOf: Data(bytes: &score, count: MemoryLayout<Float32>.size))
            }

            // wordをエンコード
            // 最先頭の要素はrubyになる
            let text = ([self.ruby] + self.data.map { $0.word == self.ruby ? "" : $0.word }).joined(separator: "\t")
            data.append(contentsOf: text.data(using: .utf8, allowLossyConversion: false)!)
            return data
        }
    }

    func loadUserDictInfo() -> (paths: [String], useradds: [UserDictionaryData], hotfixDictionary: [HotfixDictionaryV1.Entry]) {

        // データファイル名
        let paths: [String] = self.additionalSystemDictionaries.flatMap {
            switch $0 {
            case .emoji:
                if #available(iOS 18.4, *) {
                    ["emoji_dict_E16.0.txt"]
                } else if #available(iOS 17.4, *) {
                    ["emoji_dict_E15.1.txt"]
                } else if #available(iOS 16.4, *) {
                    ["emoji_dict_E15.0.txt"]
                } else {
                    ["emoji_dict_E14.0.txt"]
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

    func parseTemplate(_ word: some StringProtocol) -> String {
        if let range = word.range(of: "\\{\\{.*?\\}\\}", options: .regularExpression) {
            let center: String
            if let data = templateData.first(where: {$0.name == word[range].dropFirst(2).dropLast(2)}) {
                center = data.literal.export()
            } else {
                center = String(word[range])
            }

            let left = word[word.startIndex..<range.lowerBound]
            let right = word[range.upperBound..<word.endIndex]
            return parseTemplate(left) + center + parseTemplate(right)
        } else {
            return String(word)
        }
    }

    func makeDictionaryForm(_ data: UserDictionaryData) -> [String] {
        let katakanaRuby = data.ruby.toKatakana()
        if data.isVerb {
            let cid = 772
            let conjunctions = ConjunctionBuilder.getConjugations(data: (word: data.word, ruby: katakanaRuby, cid: cid), addStandardForm: true)
            return conjunctions.map {
                "\($0.ruby)\t\(parseTemplate($0.word))\t\($0.cid)\t\($0.cid)\t\(501)\t-5.0000"
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
        return ["\(katakanaRuby)\t\(parseTemplate(data.word))\t\(cid)\t\(cid)\t\(501)\t-5.0000"]
    }

    func makeDictionaryForm(_ data: HotfixDictionaryV1.Entry) -> [String] {
        let katakanaRuby = data.ruby.toKatakana()
        return ["\(katakanaRuby)\t\(data.word)\t\(data.lcid)\t\(data.rcid)\t\(data.mid)\t\(data.wordWeight)"]
    }

    func make_loudstxt3(lines: [DataBlock]) -> Data {
        let lc = lines.count    // データ数
        let count = Data(bytes: [UInt16(lc)], count: 2) // データ数をUInt16でマップ

        let data = lines.map { $0.makeLoudstxt3Entry() }
        let body = data.reduce(Data(), +)   // データ

        let header_endIndex: UInt32 = 2 + UInt32(lc) * UInt32(MemoryLayout<UInt32>.size)
        let headerArray = data.dropLast().reduce(into: [header_endIndex]) {array, value in // ヘッダの作成
            array.append(array.last! + UInt32(value.count))
        }

        let header = Data(bytes: headerArray, count: MemoryLayout<UInt32>.size * headerArray.count)
        let binary = count + header + body

        return binary
    }

    @MainActor func process(to identifier: String = "user") {
        let trieroot = TrieNode<Character, Int>()

        var (paths, useradds, hotfix) = self.loadUserDictInfo()
        // 重複削除
        hotfix = hotfix.filter { hotfixEntry in
            !useradds.contains {
                $0.word == hotfixEntry.word && $0.ruby.toKatakana() == hotfixEntry.ruby.toKatakana()
            }
        }

        var csvLines: [Substring] = []
        do {
            for path in paths {
                let string = try String(contentsOfFile: Bundle.main.bundlePath + "/" + path, encoding: String.Encoding.utf8)
                csvLines.append(contentsOf: string.split(separator: "\n"))
            }
            csvLines.append(contentsOf: useradds.flatMap {self.makeDictionaryForm($0)}.map {Substring($0)})
            csvLines.append(contentsOf: hotfix.flatMap {self.makeDictionaryForm($0)}.map {Substring($0)})
            let csvData = csvLines.map {$0.components(separatedBy: "\t")}
            csvData.indices.forEach {index in
                // variation selectorを外す
                let normalized = String(csvData[index][1].unicodeScalars.filter { $0.value != 0xFE0F })
                // 1文字でもdenylistに含まれるものがあったらエラー
                guard normalized.allSatisfy({!self.denylist.contains(String($0))}) else {
                    return
                }
                trieroot.insertValue(for: csvData[index][0], value: index)
            }
        } catch {
            debug("ファイルが存在しません: \(error)")
            csvLines = []
            return
        }

        let directoryURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: SharedStore.appGroupKey)!

        let binaryFileURL = directoryURL.appendingPathComponent("\(identifier).louds", isDirectory: false)
        let loudsCharsFileURL = directoryURL.appendingPathComponent("\(identifier).loudschars2", isDirectory: false)
        let loudsTxtFileURL: (String) -> URL = {directoryURL.appendingPathComponent("\(identifier + $0).loudstxt", isDirectory: false)}
        let loudsTxt2FileURL: (String) -> URL = {directoryURL.appendingPathComponent("\(identifier + $0).loudstxt2", isDirectory: false)}
        let loudsTxt3FileURL: (String) -> URL = {directoryURL.appendingPathComponent("\(identifier + $0).loudstxt3", isDirectory: false)}

        var currentID = 0
        var nodes2Characters: [Character] = ["\0", "\0"]
        var data: [DataBlock] = [.init(entries: []), .init(entries: [])]
        var bits: [Bool] = [true, false]
        trieroot.id = currentID
        currentID += 1
        var currentNodes: [(Character, TrieNode<Character, Int>)] = trieroot.children.map {($0.key, $0.value)}.sorted(by: {$0.0 < $1.0})
        bits += [Bool].init(repeating: true, count: trieroot.children.count) + [false]
        while !currentNodes.isEmpty {
            currentNodes.forEach {char, node in
                node.id = currentID
                nodes2Characters.append(char)
                let loudstxt3Entry = DataBlock(entries: Array(node.value).sorted().map {String(csvLines[$0])})
                data.append(loudstxt3Entry)
                bits += [Bool].init(repeating: true, count: node.children.count) + [false]
                currentID += 1
            }
            currentNodes = currentNodes.flatMap {$0.1.children.map {($0.key, $0.value)}.sorted(by: {$0.0 < $1.0})}
        }

        let bytes = BoolToUInt64(bits)

        do {
            let binary = Data(bytes: bytes, count: bytes.count * 8)
            try binary.write(to: binaryFileURL)
        } catch {
            debug(error)
        }

        do {
            let uint8s = nodes2Characters.map {self.char2UInt8[$0] ?? 0}    // エラー回避。0は"\0"に対応し、呼ばれることはない。
            let binary = Data(bytes: uint8s, count: uint8s.count)
            try binary.write(to: loudsCharsFileURL)
        } catch {
            debug(error)
        }

        do {
            let count = (data.count) / txtFileSplit
            let indiceses: [Range<Int>] = (0...count).map {
                let start = $0 * txtFileSplit
                let _end = ($0 + 1) * txtFileSplit
                let end = data.count < _end ? data.count : _end
                return start..<end
            }

            for indices in indiceses {
                do {
                    let start = indices.startIndex / txtFileSplit
                    let binary = make_loudstxt3(lines: Array(data[indices]))
                    try binary.write(to: loudsTxt3FileURL("\(start)"), options: .atomic)
                    // 存在しなければしないで良いのでtry?としている
                    try? FileManager.default.removeItem(at: loudsTxtFileURL("\(start)"))
                    try? FileManager.default.removeItem(at: loudsTxt2FileURL("\(start)"))
                } catch {
                    debug("LOUDSBuilder.process", error)
                }
            }

            var manager = MessageManager()
            manager.done(.ver1_9_user_dictionary_update)
        }
    }

}
