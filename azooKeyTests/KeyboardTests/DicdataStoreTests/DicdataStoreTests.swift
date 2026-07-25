//
//  DicdataStoreTests.swift
//  azooKeyTests
//
//  Created by ensan on 2023/02/09.
//  Copyright © 2023 ensan. All rights reserved.
//

import KanaKanjiConverterModuleWithDefaultDictionary
import XCTest

final class DicdataStoreTests: XCTestCase {
    func sequentialInput(_ composingText: inout ComposingText, sequence: String, inputStyle: KanaKanjiConverterModule.InputStyle) {
        for char in sequence {
            composingText.insertAtCursorPosition(String(char), inputStyle: inputStyle)
        }
    }

    /// 絶対に変換できるべき候補をここに記述する
    ///  - 主に「変換できない」と報告のあった候補を追加する
    func testMustWords() throws {
        let dicdataStore = DicdataStore.withDefaultDictionary()
        let mustWords = [
            ("アサッテ", "明後日"),
            ("オトトシ", "一昨年"),
            ("ダイヒョウ", "代表"),
            ("テキナ", "的な"),
            ("ヤマダ", "山田"),
            ("アイロ", "隘路"),
            ("フツカ", "二日"),
            ("フツカ", "2日"),
            ("ガデンインスイ", "我田引水"),
            ("フトウフクツ", "不撓不屈"),
            ("ナンタイ", "軟体"),
            ("ナンジ", "何時"),
            ("ナド", "等"),
        ]
        for (key, word) in mustWords {
            var c = ComposingText()
            c.insertAtCursorPosition(key, inputStyle: .direct)
            let result = dicdataStore.getLOUDSData(inputData: c, from: 0, to: c.input.endIndex - 1)
            // 冗長な書き方だが、こうすることで「どの項目でエラーが発生したのか」がはっきりするため、こう書いている。
            XCTAssertEqual(result.first(where: {$0.data.word == word})?.data.word, word)
        }
    }

    /// 入っていてはおかしい候補をここに記述する
    ///  - 主に以前混入していたが取り除いた語を記述する
    func testMustNotWords() throws {
        let dicdataStore = DicdataStore.withDefaultDictionary()
        let mustWords = [
            ("タイ", "体."),
            ("アサッテ", "明日"),
            ("チョ", "ちょwww"),
            ("シンコウホウホウ", "進行方向"),
            ("a", "あ"),   // direct入力の場合「a」で「あ」をサジェストしてはいけない
            ("\\n", "\n"),
        ]
        for (key, word) in mustWords {
            var c = ComposingText()
            c.insertAtCursorPosition(key, inputStyle: .direct)
            let result = dicdataStore.getLOUDSData(inputData: c, from: 0, to: c.input.endIndex - 1)
            XCTAssertNil(result.first(where: {$0.data.word == word && $0.data.ruby == key}))
        }
    }

    func testGetLOUDSDataInRange() throws {
        let dicdataStore = DicdataStore.withDefaultDictionary()
        do {
            var c = ComposingText()
            c.insertAtCursorPosition("ヘンカン", inputStyle: .roman2kana)
            let result = dicdataStore.getLOUDSDataInRange(inputData: c, from: 0, toIndexRange: 2..<4)
            XCTAssertFalse(result.contains(where: {$0.data.word == "変"}))
            XCTAssertTrue(result.contains(where: {$0.data.word == "変化"}))
            XCTAssertTrue(result.contains(where: {$0.data.word == "変換"}))
        }
        do {
            var c = ComposingText()
            c.insertAtCursorPosition("ヘンカン", inputStyle: .roman2kana)
            let result = dicdataStore.getLOUDSDataInRange(inputData: c, from: 0, toIndexRange: 0..<4)
            XCTAssertTrue(result.contains(where: {$0.data.word == "変"}))
            XCTAssertTrue(result.contains(where: {$0.data.word == "変化"}))
            XCTAssertTrue(result.contains(where: {$0.data.word == "変換"}))
        }
        do {
            var c = ComposingText()
            c.insertAtCursorPosition("ツカッ", inputStyle: .roman2kana)
            let result = dicdataStore.getLOUDSDataInRange(inputData: c, from: 0, toIndexRange: 2..<3)
            XCTAssertTrue(result.contains(where: {$0.data.word == "使っ"}))
        }
        do {
            var c = ComposingText()
            c.insertAtCursorPosition("ツカッt", inputStyle: .roman2kana)
            let result = dicdataStore.getLOUDSDataInRange(inputData: c, from: 0, toIndexRange: 2..<4)
            XCTAssertTrue(result.contains(where: {$0.data.word == "使っ"}))
        }
        do {
            var c = ComposingText()
            sequentialInput(&c, sequence: "tukatt", inputStyle: .roman2kana)
            let result = dicdataStore.getLOUDSDataInRange(inputData: c, from: 0, toIndexRange: 4..<6)
            XCTAssertTrue(result.contains(where: {$0.data.word == "使っ"}))
        }
    }
}
