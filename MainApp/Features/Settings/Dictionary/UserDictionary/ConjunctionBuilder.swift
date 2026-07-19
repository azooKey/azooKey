//
//  ConjunctionBuilder.swift
//  Keyboard
//
//  Created by ensan on 2020/09/10.
//  Copyright © 2020 ensan. All rights reserved.
//

import Foundation

private enum 活用の種類 {
    case 一段
    case 五段
    case サ変
    case ザ変
    case カ変
}
private enum 行 {
    case ア行
    case カ行
    case ガ行
    case サ行
    case タ行
    case ダ行
    case ナ行
    case ハ行
    case バ行
    case マ行
    case ヤ行
    case ラ行
    case ワ行
    case unknown

    var ア段: String {
        switch self {
        case .ア行:
            return "ア"
        case .カ行:
            return "カ"
        case .ガ行:
            return "ガ"
        case .サ行:
            return "サ"
        case .タ行:
            return "タ"
        case .ダ行:
            return "ダ"
        case .ナ行:
            return "ナ"
        case .ハ行:
            return "ハ"
        case .バ行:
            return "バ"
        case .マ行:
            return "マ"
        case .ヤ行:
            return "ヤ"
        case .ラ行:
            return "ラ"
        case .ワ行:
            return "ワ"
        case .unknown:
            return "\0"
        }
    }
    var あ段: String {
        switch self {
        case .ア行:
            return "あ"
        case .カ行:
            return "か"
        case .ガ行:
            return "が"
        case .サ行:
            return "さ"
        case .タ行:
            return "た"
        case .ダ行:
            return "だ"
        case .ナ行:
            return "な"
        case .ハ行:
            return "は"
        case .バ行:
            return "ば"
        case .マ行:
            return "ま"
        case .ヤ行:
            return "や"
        case .ラ行:
            return "ら"
        case .ワ行:
            return "わ"
        case .unknown:
            return "\0"
        }
    }
    var イ段: String {
        switch self {
        case .ア行:
            return "イ"
        case .カ行:
            return "キ"
        case .ガ行:
            return "ギ"
        case .サ行:
            return "シ"
        case .タ行:
            return "チ"
        case .ダ行:
            return "ヂ"
        case .ナ行:
            return "ニ"
        case .ハ行:
            return "ヒ"
        case .バ行:
            return "ビ"
        case .マ行:
            return "ミ"
        case .ヤ行:
            return "イ"
        case .ラ行:
            return "リ"
        case .ワ行:
            return "イ"
        case .unknown:
            return "\0"
        }
    }

    var い段: String {
        switch self {
        case .ア行:
            return "い"
        case .カ行:
            return "き"
        case .ガ行:
            return "ぎ"
        case .サ行:
            return "し"
        case .タ行:
            return "ち"
        case .ダ行:
            return "ぢ"
        case .ナ行:
            return "に"
        case .ハ行:
            return "ひ"
        case .バ行:
            return "び"
        case .マ行:
            return "み"
        case .ヤ行:
            return "い"
        case .ラ行:
            return "り"
        case .ワ行:
            return "い"
        case .unknown:
            return "\0"
        }
    }

    var ウ段: Character {
        switch self {
        case .ア行:
            return "ウ"
        case .カ行:
            return "ク"
        case .ガ行:
            return "グ"
        case .サ行:
            return "ス"
        case .タ行:
            return "ツ"
        case .ダ行:
            return "ヅ"
        case .ナ行:
            return "ヌ"
        case .ハ行:
            return "フ"
        case .バ行:
            return "ブ"
        case .マ行:
            return "ム"
        case .ヤ行:
            return "ユ"
        case .ラ行:
            return "ル"
        case .ワ行:
            return "ウ"
        case .unknown:
            return "\0"
        }
    }
    var う段: String {
        switch self {
        case .ア行:
            return "う"
        case .カ行:
            return "く"
        case .ガ行:
            return "ぐ"
        case .サ行:
            return "す"
        case .タ行:
            return "つ"
        case .ダ行:
            return "づ"
        case .ナ行:
            return "ぬ"
        case .ハ行:
            return "ふ"
        case .バ行:
            return "ぶ"
        case .マ行:
            return "む"
        case .ヤ行:
            return "ゆ"
        case .ラ行:
            return "る"
        case .ワ行:
            return "う"
        case .unknown:
            return "\0"
        }
    }
    var エ段: String {
        switch self {
        case .ア行:
            return "エ"
        case .カ行:
            return "ケ"
        case .ガ行:
            return "ゲ"
        case .サ行:
            return "セ"
        case .タ行:
            return "テ"
        case .ダ行:
            return "デ"
        case .ナ行:
            return "ネ"
        case .ハ行:
            return "ヘ"
        case .バ行:
            return "ベ"
        case .マ行:
            return "メ"
        case .ヤ行:
            return "エ"
        case .ラ行:
            return "レ"
        case .ワ行:
            return "エ"
        case .unknown:
            return "\0"
        }
    }
    var え段: String {
        switch self {
        case .ア行:
            return "え"
        case .カ行:
            return "け"
        case .ガ行:
            return "げ"
        case .サ行:
            return "せ"
        case .タ行:
            return "て"
        case .ダ行:
            return "で"
        case .ナ行:
            return "ね"
        case .ハ行:
            return "へ"
        case .バ行:
            return "べ"
        case .マ行:
            return "め"
        case .ヤ行:
            return "え"
        case .ラ行:
            return "れ"
        case .ワ行:
            return "え"
        case .unknown:
            return "\0"
        }
    }

    var オ段: String {
        switch self {
        case .ア行:
            return "オ"
        case .カ行:
            return "コ"
        case .ガ行:
            return "ゴ"
        case .サ行:
            return "ソ"
        case .タ行:
            return "ト"
        case .ダ行:
            return "ド"
        case .ナ行:
            return "ノ"
        case .ハ行:
            return "ホ"
        case .バ行:
            return "ボ"
        case .マ行:
            return "モ"
        case .ヤ行:
            return "ヨ"
        case .ラ行:
            return "ロ"
        case .ワ行:
            return "オ"
        case .unknown:
            return "\0"
        }
    }
    var お段: String {
        switch self {
        case .ア行:
            return "お"
        case .カ行:
            return "こ"
        case .ガ行:
            return "ご"
        case .サ行:
            return "そ"
        case .タ行:
            return "と"
        case .ダ行:
            return "ど"
        case .ナ行:
            return "の"
        case .ハ行:
            return "ほ"
        case .バ行:
            return "ぼ"
        case .マ行:
            return "も"
        case .ヤ行:
            return "よ"
        case .ラ行:
            return "ろ"
        case .ワ行:
            return "お"
        case .unknown:
            return "\0"
        }
    }
    var ヤ段: String {
        switch self {
        case .ア行:
            return "イ"
        case .カ行:
            return "キャ"
        case .ガ行:
            return "ギャ"
        case .サ行:
            return "シャ"
        case .タ行:
            return "チャ"
        case .ダ行:
            return "ジャ"
        case .ナ行:
            return "ニャ"
        case .ハ行:
            return "ヒャ"
        case .バ行:
            return "ビャ"
        case .マ行:
            return "ミャ"
        case .ヤ行:
            return "イ"
        case .ラ行:
            return "リャ"
        case .ワ行:
            return "ヤ"
        case .unknown:
            return "\0"
        }
    }
    var や段: String {
        switch self {
        case .ア行:
            return "や"
        case .カ行:
            return "きゃ"
        case .ガ行:
            return "ぎゃ"
        case .サ行:
            return "しゃ"
        case .タ行:
            return "ちゃ"
        case .ダ行:
            return "じゃ"
        case .ナ行:
            return "にゃ"
        case .ハ行:
            return "ひゃ"
        case .バ行:
            return "びゃ"
        case .マ行:
            return "みゃ"
        case .ヤ行:
            return "や"
        case .ラ行:
            return "りゃ"
        case .ワ行:
            return "や"
        case .unknown:
            return "\0"
        }
    }

}

private extension String {
    static var い: String {
        "い"
    }
    static var 小書きつ: String {
        "っ"
    }
    static var よ: String {
        "よ"
    }
    static var ろ: String {
        "ろ"
    }
    static var ん: String {
        "ん"
    }
}

struct ConjunctionBuilder {
    static private func 動詞情報照会(cid: Int) -> (活用: 活用の種類, 行の名前: 行)? {
        if cid == 583 {
            return (活用: .サ変, 行の名前: .unknown)
        }
        if cid == 592 {
            return (活用: .ザ変, 行の名前: .unknown)
        }
        if cid == 619 {
            return (活用: .一段, 行の名前: .unknown)
        }
        if cid == 679 {
            return (活用: .五段, 行の名前: .カ行)
        }
        if cid == 695 {
            return (活用: .五段, 行の名前: .カ行)
        }
        if cid == 723 {
            return (活用: .五段, 行の名前: .ガ行)
        }
        if cid == 731 {
            return (活用: .五段, 行の名前: .サ行)
        }
        if cid == 738 {
            return (活用: .五段, 行の名前: .タ行)
        }
        if cid == 746 {
            return (活用: .五段, 行の名前: .ナ行)
        }
        if cid == 754 {
            return (活用: .五段, 行の名前: .バ行)
        }
        if cid == 762 {
            return (活用: .五段, 行の名前: .マ行)
        }
        if cid == 772 {
            return (活用: .五段, 行の名前: .ラ行)
        }
        if cid == 802 {
            return (活用: .五段, 行の名前: .ワ行)
        }
        if cid == 817 {
            return (活用: .五段, 行の名前: .ワ行)
        }
        return nil
    }

    static private func 活用形取得(データ: (word: String, ruby: String, cid: Int), 活用: 活用の種類, 行の名前: 行) -> [(word: String, ruby: String, cid: Int)] {
        switch 活用 {
        case .五段:
            // 可能動詞は無視する
            switch データ.cid {
            case 679:
                let 語幹 = String(データ.word.dropLast())
                let 語幹ルビ = String(データ.ruby.dropLast())
                let 仮定形 = (word: 語幹 + 行の名前.え段, ruby: 語幹ルビ + 行の名前.エ段, cid: 675)
                let 仮定縮約 = (word: 語幹 + 行の名前.や段, ruby: 語幹ルビ + 行の名前.ヤ段, cid: 677)
                let 未然ウ接続 = (word: 語幹 + 行の名前.お段, ruby: 語幹ルビ + 行の名前.オ段, cid: 681)
                let 未然形 = (word: 語幹 + 行の名前.あ段, ruby: 語幹ルビ + 行の名前.ア段, cid: 683)
                let 命令エ = (word: 語幹 + 行の名前.え段, ruby: 語幹ルビ + 行の名前.エ段, cid: 685)
                let 連用タ接続 = (word: 語幹 + String.い, ruby: 語幹ルビ + "イ", cid: 687)
                let 連用形 = (word: 語幹 + 行の名前.い段, ruby: 語幹ルビ + 行の名前.イ段, cid: 689)
                return [仮定形, 仮定縮約, 未然ウ接続, 未然形, 命令エ, 連用タ接続, 連用形]
            case 695:
                let 語幹 = String(データ.word.dropLast())
                let 語幹ルビ = String(データ.ruby.dropLast())
                let 仮定形 = (word: 語幹 + 行の名前.え段, ruby: 語幹ルビ + 行の名前.エ段, cid: 691)
                let 仮定縮約 = (word: 語幹 + 行の名前.や段, ruby: 語幹ルビ + 行の名前.ヤ段, cid: 693)
                let 未然ウ接続 = (word: 語幹 + 行の名前.お段, ruby: 語幹ルビ + 行の名前.オ段, cid: 697)
                let 未然形 = (word: 語幹 + 行の名前.あ段, ruby: 語幹ルビ + 行の名前.ア段, cid: 699)
                let 命令エ = (word: 語幹 + 行の名前.え段, ruby: 語幹ルビ + 行の名前.エ段, cid: 701)
                let 連用タ接続 = (word: 語幹 + String.小書きつ, ruby: 語幹ルビ + "ッ", cid: 703)
                let 連用形 = (word: 語幹 + 行の名前.い段, ruby: 語幹ルビ + 行の名前.イ段, cid: 705)
                return [仮定形, 仮定縮約, 未然ウ接続, 未然形, 命令エ, 連用タ接続, 連用形]
            case 723:
                let 語幹 = String(データ.word.dropLast())
                let 語幹ルビ = String(データ.ruby.dropLast())
                let 仮定形 = (word: 語幹 + 行の名前.え段, ruby: 語幹ルビ + 行の名前.エ段, cid: 721)
                let 仮定縮約 = (word: 語幹 + 行の名前.や段, ruby: 語幹ルビ + 行の名前.ヤ段, cid: 722)
                let 未然ウ接続 = (word: 語幹 + 行の名前.お段, ruby: 語幹ルビ + 行の名前.オ段, cid: 724)
                let 未然形 = (word: 語幹 + 行の名前.あ段, ruby: 語幹ルビ + 行の名前.ア段, cid: 725)
                let 命令エ = (word: 語幹 + 行の名前.え段, ruby: 語幹ルビ + 行の名前.エ段, cid: 726)
                let 連用タ接続 = (word: 語幹 + String.い, ruby: 語幹ルビ + "イ", cid: 727)
                let 連用形 = (word: 語幹 + 行の名前.い段, ruby: 語幹ルビ + 行の名前.イ段, cid: 728)
                return [仮定形, 仮定縮約, 未然ウ接続, 未然形, 命令エ, 連用タ接続, 連用形]
            case 731:
                let 語幹 = String(データ.word.dropLast())
                let 語幹ルビ = String(データ.ruby.dropLast())
                let 仮定形 = (word: 語幹 + 行の名前.え段, ruby: 語幹ルビ + 行の名前.エ段, cid: 729)
                let 仮定縮約 = (word: 語幹 + 行の名前.や段, ruby: 語幹ルビ + 行の名前.ヤ段, cid: 730)
                let 未然ウ接続 = (word: 語幹 + 行の名前.お段, ruby: 語幹ルビ + 行の名前.オ段, cid: 732)
                let 未然形 = (word: 語幹 + 行の名前.あ段, ruby: 語幹ルビ + 行の名前.ア段, cid: 733)
                let 命令エ = (word: 語幹 + 行の名前.え段, ruby: 語幹ルビ + 行の名前.エ段, cid: 734)
                let 連用形 = (word: 語幹 + 行の名前.い段, ruby: 語幹ルビ + 行の名前.イ段, cid: 735)
                return [仮定形, 仮定縮約, 未然ウ接続, 未然形, 命令エ, 連用形]
            case 738:
                let 語幹 = String(データ.word.dropLast())
                let 語幹ルビ = String(データ.ruby.dropLast())
                let 仮定形 = (word: 語幹 + 行の名前.え段, ruby: 語幹ルビ + 行の名前.エ段, cid: 736)
                let 仮定縮約 = (word: 語幹 + 行の名前.や段, ruby: 語幹ルビ + 行の名前.ヤ段, cid: 737)
                let 未然ウ接続 = (word: 語幹 + 行の名前.お段, ruby: 語幹ルビ + 行の名前.オ段, cid: 739)
                let 未然形 = (word: 語幹 + 行の名前.あ段, ruby: 語幹ルビ + 行の名前.ア段, cid: 740)
                let 命令エ = (word: 語幹 + 行の名前.え段, ruby: 語幹ルビ + 行の名前.エ段, cid: 741)
                let 連用タ接続 = (word: 語幹 + String.小書きつ, ruby: 語幹ルビ + "ッ", cid: 742)
                let 連用形 = (word: 語幹 + 行の名前.い段, ruby: 語幹ルビ + 行の名前.イ段, cid: 743)
                return [仮定形, 仮定縮約, 未然ウ接続, 未然形, 命令エ, 連用タ接続, 連用形]
            case 746:
                let 語幹 = String(データ.word.dropLast())
                let 語幹ルビ = String(データ.ruby.dropLast())
                let 仮定形 = (word: 語幹 + 行の名前.え段, ruby: 語幹ルビ + 行の名前.エ段, cid: 744)
                let 仮定縮約 = (word: 語幹 + 行の名前.や段, ruby: 語幹ルビ + 行の名前.ヤ段, cid: 745)
                let 未然ウ接続 = (word: 語幹 + 行の名前.お段, ruby: 語幹ルビ + 行の名前.オ段, cid: 747)
                let 未然形 = (word: 語幹 + 行の名前.あ段, ruby: 語幹ルビ + 行の名前.ア段, cid: 748)
                let 命令エ = (word: 語幹 + 行の名前.え段, ruby: 語幹ルビ + 行の名前.エ段, cid: 749)
                let 連用タ接続 = (word: 語幹 + String.ん, ruby: 語幹ルビ + "ン", cid: 750)
                let 連用形 = (word: 語幹 + 行の名前.い段, ruby: 語幹ルビ + 行の名前.イ段, cid: 751)
                return [仮定形, 仮定縮約, 未然ウ接続, 未然形, 命令エ, 連用タ接続, 連用形]
            case 754:
                let 語幹 = String(データ.word.dropLast())
                let 語幹ルビ = String(データ.ruby.dropLast())
                let 仮定形 = (word: 語幹 + 行の名前.え段, ruby: 語幹ルビ + 行の名前.エ段, cid: 752)
                let 仮定縮約 = (word: 語幹 + 行の名前.や段, ruby: 語幹ルビ + 行の名前.ヤ段, cid: 753)
                let 未然ウ接続 = (word: 語幹 + 行の名前.お段, ruby: 語幹ルビ + 行の名前.オ段, cid: 755)
                let 未然形 = (word: 語幹 + 行の名前.あ段, ruby: 語幹ルビ + 行の名前.ア段, cid: 756)
                let 命令エ = (word: 語幹 + 行の名前.え段, ruby: 語幹ルビ + 行の名前.エ段, cid: 757)
                let 連用タ接続 = (word: 語幹 + String.ん, ruby: 語幹ルビ + "ン", cid: 758)
                let 連用形 = (word: 語幹 + 行の名前.い段, ruby: 語幹ルビ + 行の名前.イ段, cid: 759)
                return [仮定形, 仮定縮約, 未然ウ接続, 未然形, 命令エ, 連用タ接続, 連用形]
            case 762:
                let 語幹 = String(データ.word.dropLast())
                let 語幹ルビ = String(データ.ruby.dropLast())
                let 仮定形 = (word: 語幹 + 行の名前.え段, ruby: 語幹ルビ + 行の名前.エ段, cid: 760)
                let 仮定縮約 = (word: 語幹 + 行の名前.や段, ruby: 語幹ルビ + 行の名前.ヤ段, cid: 761)
                let 未然ウ接続 = (word: 語幹 + 行の名前.お段, ruby: 語幹ルビ + 行の名前.オ段, cid: 763)
                let 未然形 = (word: 語幹 + 行の名前.あ段, ruby: 語幹ルビ + 行の名前.ア段, cid: 764)
                let 命令エ = (word: 語幹 + 行の名前.え段, ruby: 語幹ルビ + 行の名前.エ段, cid: 765)
                let 連用タ接続 = (word: 語幹 + String.ん, ruby: 語幹ルビ + "ン", cid: 766)
                let 連用形 = (word: 語幹 + 行の名前.い段, ruby: 語幹ルビ + 行の名前.イ段, cid: 767)
                return [仮定形, 仮定縮約, 未然ウ接続, 未然形, 命令エ, 連用タ接続, 連用形]
            case 772:
                let 語幹 = String(データ.word.dropLast())
                let 語幹ルビ = String(データ.ruby.dropLast())
                let 仮定形 = (word: 語幹 + 行の名前.え段, ruby: 語幹ルビ + 行の名前.エ段, cid: 768)
                let 仮定縮約 = (word: 語幹 + 行の名前.や段, ruby: 語幹ルビ + 行の名前.ヤ段, cid: 770)
                let 体言接続特殊壱 = (word: 語幹 + String.ん, ruby: 語幹ルビ + "ン", cid: 774) // "走んなよ"などの類。
                let 体言接続特殊弐 = (word: 語幹, ruby: 語幹ルビ, cid: 776)
                let 未然ウ接続 = (word: 語幹 + 行の名前.お段, ruby: 語幹ルビ + 行の名前.オ段, cid: 778)
                let 未然形 = (word: 語幹 + 行の名前.あ段, ruby: 語幹ルビ + 行の名前.ア段, cid: 780)
                let 未然特殊 = (word: 語幹 + String.ん, ruby: 語幹ルビ + "ン", cid: 782) // "走んない"などの類。
                let 命令エ = (word: 語幹 + 行の名前.え段, ruby: 語幹ルビ + 行の名前.エ段, cid: 784)
                let 連用タ接続 = (word: 語幹 + String.小書きつ, ruby: 語幹ルビ + "ッ", cid: 786)
                let 連用形 = (word: 語幹 + 行の名前.い段, ruby: 語幹ルビ + 行の名前.イ段, cid: 788)
                return [仮定形, 仮定縮約, 体言接続特殊壱, 体言接続特殊弐, 未然ウ接続, 未然形, 未然特殊, 命令エ, 連用タ接続, 連用形]
            case 802:                           // ワ行ウ音便
                let 語幹 = String(データ.word.dropLast())
                let 語幹ルビ = String(データ.ruby.dropLast())
                let 仮定形 = (word: 語幹 + 行の名前.え段, ruby: 語幹ルビ + 行の名前.エ段, cid: 800)
                let 未然ウ接続 = (word: 語幹 + 行の名前.お段, ruby: 語幹ルビ + 行の名前.オ段, cid: 804)
                let 未然形 = (word: 語幹 + 行の名前.あ段, ruby: 語幹ルビ + 行の名前.ア段, cid: 806)
                let 命令エ = (word: 語幹 + 行の名前.え段, ruby: 語幹ルビ + 行の名前.エ段, cid: 808)
                let 連用タ接続 = (word: 語幹 + "う", ruby: 語幹ルビ + "ウ", cid: 810)
                let 連用形 = (word: 語幹 + 行の名前.い段, ruby: 語幹ルビ + 行の名前.イ段, cid: 812)
                return [仮定形, 未然ウ接続, 未然形, 命令エ, 連用タ接続, 連用形]
            case 817:                           // ワ行促音便
                let 語幹 = String(データ.word.dropLast())
                let 語幹ルビ = String(データ.ruby.dropLast())
                let 仮定形 = (word: 語幹 + 行の名前.え段, ruby: 語幹ルビ + 行の名前.エ段, cid: 814)
                let 未然ウ接続 = (word: 語幹 + 行の名前.お段, ruby: 語幹ルビ + 行の名前.オ段, cid: 820)
                let 未然形 = (word: 語幹 + 行の名前.あ段, ruby: 語幹ルビ + 行の名前.ア段, cid: 823)
                let 命令エ = (word: 語幹 + 行の名前.え段, ruby: 語幹ルビ + 行の名前.エ段, cid: 826)
                let 連用タ接続 = (word: 語幹 + String.小書きつ, ruby: 語幹ルビ + "ッ", cid: 829)
                let 連用形 = (word: 語幹 + 行の名前.い段, ruby: 語幹ルビ + 行の名前.イ段, cid: 832)
                return [仮定形, 未然ウ接続, 未然形, 命令エ, 連用タ接続, 連用形]
            default:
                break
            }
        case .一段:
            let 語幹 = String(データ.word.dropLast())
            let 語幹ルビ = String(データ.ruby.dropLast())

            let 仮定形 = (word: 語幹 + "れ", ruby: 語幹ルビ + "レ", cid: 617)
            let 仮定縮約 = (word: 語幹 + "りゃ", ruby: 語幹ルビ + "リャ", cid: 618)
            let 体現接続特殊 = (word: 語幹 + String.ん, ruby: 語幹ルビ + "ン", cid: 620)
            let 未然ウ接続 = (word: 語幹 + String.よ, ruby: 語幹ルビ + "ヨ", cid: 621)
            let 未然形 = (word: 語幹, ruby: 語幹ルビ, cid: 622)
            let 命令ロ = (word: 語幹 + String.ろ, ruby: 語幹ルビ + "ロ", cid: 623)
            let 命令ヨ = (word: 語幹 + String.よ, ruby: 語幹ルビ + "ヨ", cid: 624)
            let 連用形 = (word: 語幹, ruby: 語幹ルビ, cid: 625)
            return [仮定形, 仮定縮約, 体現接続特殊, 未然ウ接続, 未然形, 命令ロ, 命令ヨ, 連用形]
        case .サ変:
            let 語幹 = String(データ.word.dropLast(2))
            let 語幹ルビ = String(データ.ruby.dropLast(2))

            let 仮定形 = (word: 語幹 + "すれ", ruby: 語幹ルビ + "スレ", cid: 581)
            let 仮定縮約 = (word: 語幹 + "しゃ", ruby: 語幹ルビ + "シャ", cid: 582)
            let 文語基本形 = (word: 語幹 + "す", ruby: 語幹ルビ + "ス", cid: 584)
            let 未然ウ接続 = (word: 語幹 + "しよ", ruby: 語幹ルビ + "シヨ", cid: 585)
            let 未然レル接続 = (word: 語幹 + "さ", ruby: 語幹ルビ + "サ", cid: 586)
            let 未然形 = (word: 語幹 + "し", ruby: 語幹ルビ + "シ", cid: 587)
            let 命令ロ = (word: 語幹 + "しろ", ruby: 語幹ルビ + "シロ", cid: 588)
            let 命令ヨ = (word: 語幹 + "せよ", ruby: 語幹ルビ + "セヨ", cid: 589)
            return [仮定形, 仮定縮約, 文語基本形, 未然ウ接続, 未然レル接続, 未然形, 命令ロ, 命令ヨ]
        case .ザ変:
            let 語幹 = String(データ.word.dropLast(2))
            let 語幹ルビ = String(データ.ruby.dropLast(2))
            let 仮定形 = (word: 語幹 + "ずれ", ruby: 語幹ルビ + "ズレ", cid: 590)
            let 仮定縮約 = (word: 語幹 + "ずりゃ", ruby: 語幹ルビ + "ズリャ", cid: 591)
            let 文語基本形 = (word: 語幹 + "ず", ruby: 語幹ルビ + "ズ", cid: 593)
            let 未然ウ接続 = (word: 語幹 + "ぜよ", ruby: 語幹ルビ + "ゼヨ", cid: 594)
            let 未然形 = (word: 語幹 + "ぜ", ruby: 語幹ルビ + "ゼ", cid: 595)
            let 命令ヨ = (word: 語幹 + "ぜよ", ruby: 語幹ルビ + "ゼヨ", cid: 596)
            return [仮定形, 仮定縮約, 文語基本形, 未然ウ接続, 未然形, 命令ヨ]
        case .カ変:
            return []
        }
        return []
    }

    static func getConjugations(data: (word: String, ruby: String, cid: Int), addStandardForm: Bool = false) -> [(word: String, ruby: String, cid: Int)] {
        if let 動詞の情報 = 動詞情報照会(cid: data.cid) {
            let 活用形: [(word: String, ruby: String, cid: Int)] = 活用形取得(データ: data, 活用: 動詞の情報.活用, 行の名前: 動詞の情報.行の名前)
            if addStandardForm {
                return 活用形 + [data]
            }
            return 活用形
        }
        return []

    }
}
