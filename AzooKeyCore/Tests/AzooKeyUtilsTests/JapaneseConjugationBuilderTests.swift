import AzooKeyUtils
import XCTest

final class JapaneseConjugationBuilderTests: XCTestCase {
    func test_godanRaRowConjugations() {
        let conjugations = JapaneseConjugationBuilder.conjugations(
            for: (word: "走る", ruby: "ハシル", cid: 772),
            includingStandardForm: true
        )

        XCTAssertEqual(conjugations.count, 11)
        XCTAssertEqual(conjugations.map { $0.word }, [
            "走れ",
            "走りゃ",
            "走ん",
            "走",
            "走ろ",
            "走ら",
            "走ん",
            "走れ",
            "走っ",
            "走り",
            "走る",
        ])
        XCTAssertEqual(conjugations.map { $0.cid }, [
            768,
            770,
            774,
            776,
            778,
            780,
            782,
            784,
            786,
            788,
            772,
        ])
    }

    func test_ichidanConjugations() {
        let conjugations = JapaneseConjugationBuilder.conjugations(
            for: (word: "食べる", ruby: "タベル", cid: 619)
        )

        XCTAssertEqual(conjugations.map { $0.word }, [
            "食べれ",
            "食べりゃ",
            "食べん",
            "食べよ",
            "食べ",
            "食べろ",
            "食べよ",
            "食べ",
        ])
        XCTAssertEqual(conjugations.map { $0.ruby }, [
            "タベレ",
            "タベリャ",
            "タベン",
            "タベヨ",
            "タベ",
            "タベロ",
            "タベヨ",
            "タベ",
        ])
    }

    func test_unknownConnectionIDHasNoConjugations() {
        XCTAssertTrue(
            JapaneseConjugationBuilder.conjugations(
                for: (word: "未知", ruby: "ミチ", cid: -1)
            ).isEmpty
        )
    }
}
