//
//  AzooKeyUserDictionaryData.swift
//  MainApp
//
//  Created by ensan on 2020/12/23.
//  Copyright © 2020 ensan. All rights reserved.
//

import Foundation
import SwiftUI

final class EditableUserDictionaryData: ObservableObject {
    lazy var availableChars: [Character] = {
        do {
            let string = try String(contentsOfFile: Bundle.main.bundlePath + "/charID.chid", encoding: String.Encoding.utf8)

            return Array(string).filter {!["\t", ",", " ", "\0"].contains($0)}
        } catch {
            return []
        }
    }()

    @Published var data: UserDictionaryData
    let id: Int

    init(data: UserDictionaryData) {
        self.data = data
        self.id = data.id
    }

    func neadVerbCheck() -> Bool {
        let result = self.data.ruby.last == "る" && ["る", "ル"].contains(self.data.word.last)
        return result
    }

    var mizenkeiRuby: String {
        self.data.ruby.dropLast() + "らない"
    }

    var mizenkeiWord: String {
        self.data.word.dropLast() + "らない"
    }

    enum AppendError {
        case rubyEmpty
        case wordEmpty
        case unavailableCharacter
        case templateFormatEmpty

        var message: LocalizedStringKey {
            switch self {
            case .rubyEmpty:
                return "読みが空です"
            case .wordEmpty:
                return "単語が空です"
            case .unavailableCharacter:
                return "読みに使用できない文字が含まれます。ひらがな、英字、数字を指定してください"
            case .templateFormatEmpty:
                return "時刻・ランダム変換の書式が未設定です"
            }
        }

    }

    var error: AppendError? {
        if self.data.isTemplateMode {
            if (self.data.formatLiteral?.isEmpty ?? true) {
                return .templateFormatEmpty
            }
        } else if self.data.word.isEmpty {
            return .wordEmpty
        }
        if self.data.ruby.isEmpty {
            return .rubyEmpty
        }
        if !self.data.ruby.applyingTransform(.hiraganaToKatakana, reverse: false)!.allSatisfy({self.availableChars.contains($0)}) {
            return .unavailableCharacter
        }
        return nil
    }

    func makeStableData() -> UserDictionaryData {
        var result = self.data
        if !self.neadVerbCheck() && self.data.isVerb {
            result.isVerb = false
        }
        return result
    }

    func copy() -> EditableUserDictionaryData {
        .init(data: data)
    }

    func reset(from copy: EditableUserDictionaryData) {
        self.data = copy.data
    }
}

struct UserDictionary: Codable {
    let items: [UserDictionaryData]

    init(items: [UserDictionaryData]) {
        self.items = items.indices.map {i in
            let item = items[i]
            return UserDictionaryData(
                ruby: item.ruby.toHiragana(),
                word: item.word,
                isVerb: item.isVerb,
                isPersonName: item.isPersonName,
                isPlaceName: item.isPlaceName,
                id: i,
                shared: item.shared,
                isTemplateMode: item.isTemplateMode,
                formatLiteral: item.formatLiteral
            )
        }
    }

    func save() {
        let encoder = JSONEncoder()
        let saveData: Data
        if let encodedValue = try? encoder.encode(self) {
            saveData = encodedValue
        } else {
            saveData = Data()
        }
        UserDefaults.standard.set(saveData, forKey: "user_dict")
    }
    static func get() -> Self? {
        if let value = UserDefaults.standard.value(forKey: "user_dict") as? Data {
            let decoder = JSONDecoder()
            if let userDictionary = try? decoder.decode(UserDictionary.self, from: value) {
                return userDictionary
            }
        }
        return nil
    }
}

struct UserDictionaryData: Equatable, Identifiable, Codable {
    var ruby: String
    var word: String
    var isVerb: Bool
    var isPersonName: Bool
    var isPlaceName: Bool
    let id: Int
    var shared: Bool? = false
    var isTemplateMode: Bool = false
    var formatLiteral: String?

    func makeEditableData() -> EditableUserDictionaryData {
        EditableUserDictionaryData(data: self)
    }

    static func emptyData(id: Int) -> Self {
        UserDictionaryData(ruby: "", word: "", isVerb: false, isPersonName: false, isPlaceName: false, id: id, shared: false, isTemplateMode: false, formatLiteral: nil)
    }
}

// Codable 後方互換: 追加フィールドがない古い保存データを読み込めるようにする
extension UserDictionaryData {
    private enum CodingKeys: String, CodingKey {
        case ruby, word, isVerb, isPersonName, isPlaceName, id, shared, isTemplateMode, formatLiteral
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.ruby = try container.decode(String.self, forKey: .ruby)
        self.word = try container.decode(String.self, forKey: .word)
        self.isVerb = (try? container.decode(Bool.self, forKey: .isVerb)) ?? false
        self.isPersonName = (try? container.decode(Bool.self, forKey: .isPersonName)) ?? false
        self.isPlaceName = (try? container.decode(Bool.self, forKey: .isPlaceName)) ?? false
        self.id = try container.decode(Int.self, forKey: .id)
        self.shared = try? container.decode(Bool.self, forKey: .shared)
        self.isTemplateMode = (try? container.decode(Bool.self, forKey: .isTemplateMode)) ?? false
        self.formatLiteral = try? container.decode(String.self, forKey: .formatLiteral)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(ruby, forKey: .ruby)
        try container.encode(word, forKey: .word)
        try container.encode(isVerb, forKey: .isVerb)
        try container.encode(isPersonName, forKey: .isPersonName)
        try container.encode(isPlaceName, forKey: .isPlaceName)
        try container.encode(id, forKey: .id)
        try container.encode(shared, forKey: .shared)
        try container.encode(isTemplateMode, forKey: .isTemplateMode)
        try container.encode(formatLiteral, forKey: .formatLiteral)
    }
}
