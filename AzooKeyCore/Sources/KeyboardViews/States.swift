//
//  EnvironmentValue.swift
//  Keyboard
//
//  Created by ensan on 2021/02/06.
//  Copyright © 2021 ensan. All rights reserved.
//

import enum UIKit.UIReturnKeyType
import enum KanaKanjiConverterModule.KeyboardLanguage

extension KeyboardLanguage {
    var shortSymbol: String {
        switch self {
        case .en_US:
            "A"
        case .el_GR:
            "Ω"
        case .ja_JP:
            "あ"
        case .none:
            ""
        }
    }
    var symbol: String {
        switch self {
        case .en_US:
            "ABC"
        case .el_GR:
            "ΑΒΓ"
        case .ja_JP:
            "あいう"
        case .none:
            ""
        }
    }
}

public enum ResizingState: Sendable {
    case fullwidth // 両手モードの利用（高さ変更は有効の場合がある）
    case onehanded // 片手モードの利用
    case resizing  // 編集モード
}

public enum KeyboardOrientation: Equatable, Sendable {
    case vertical       // width<height
    case horizontal     // height<width
}

public enum RoughEnterKeyState: Sendable {
    case `return`
    case complete
}

public enum EnterKeyState: Sendable {
    case complete   // 決定
    case `return`(UIReturnKeyType)   // 改行
}

public enum BarState: Sendable {
    case none   // なし
    case tab    // タブバー
    case cursor // カーソルバー
}
