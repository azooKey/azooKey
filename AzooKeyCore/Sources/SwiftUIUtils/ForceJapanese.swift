//
//  ForceJapanese.swift
//  AzooKeyCore
//  中華フォント問題を回避するため、文字列の言語属性を強制的に日本語に設定するユーティリティ。
//  Created by Kazuma on 2025-06-25.
//

import SwiftUI

/// 日本語フォントを強制的に適用するためのユーティリティを提供する構造体。
///
/// 使い方:
/// Text(ForceJapanese.create(from: "表示したいテキスト", font: .body))
public struct ForceJapanese {

    /// 文字列とフォントから、言語を日本語に指定した属性付き文字列（AttributedString）を生成します。
    /// - Parameters:
    ///   - text: 対象の文字列。
    ///   - font: 適用したいSwiftUIのFont。
    /// - Returns: 言語とフォントが指定されたAttributedString。
    public static func create(from text: String, font: Font) -> AttributedString {
        var attributedString = AttributedString(text)
        
        // 言語識別子を "ja" (日本語) に設定
        attributedString.languageIdentifier = "ja"
        
        // フォントを設定
        attributedString.font = font
        
        return attributedString
    }
}


// MARK: - String Extension for Convenience
// より便利に呼び出すためのString拡張
//
// 使い方:
// Text("表示したいテキスト".toJapaneseAttributedString(font: .body))
extension String {
    
    /// この文字列を、指定されたフォントで日本語強制表示するAttributedStringに変換します。
    /// - Parameter font: 適用したいSwiftUIのFont。
    /// - Returns: 言語とフォントが指定されたAttributedString。
    public func toJapaneseAttributedString(font: Font) -> AttributedString {
        return ForceJapanese.create(from: self, font: font)
    }
}
