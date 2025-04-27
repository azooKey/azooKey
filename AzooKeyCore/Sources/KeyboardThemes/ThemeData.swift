//
//  ThemeData.swift
//  azooKey
//
//  Created by ensan on 2021/02/04.
//  Copyright © 2021 ensan. All rights reserved.
//

import Foundation
import SwiftUI
import SwiftUIUtils

public struct ThemeData<ApplicationExtension: ApplicationSpecificTheme>: Codable, Equatable, Sendable {
    public typealias ColorData = ThemeColor<ApplicationExtension.ApplicationColor>
    public var id: Int?
    public var backgroundColor: ColorData
    public var picture: ThemePicture
    public var textColor: ColorData
    public var textFont: ThemeFontWeight
    public var resultTextColor: ColorData
    public var resultBackgroundColor: ColorData
    public var borderColor: ColorData
    public var borderWidth: Double
    public var normalKeyFillColor: ColorData
    public var specialKeyFillColor: ColorData
    public var pushedKeyFillColor: ColorData   // 自動で設定する
    public var suggestKeyFillColor: ColorData?  // 自動で設定する
    public var suggestLabelTextColor: ColorData?        // 設定は露出させない
    public var keyShadow: ThemeShadowData<ColorData>?   // 設定は露出させない

    public init(id: Int? = nil, backgroundColor: ColorData, picture: ThemePicture, textColor: ColorData, textFont: ThemeFontWeight, resultTextColor: ColorData, resultBackgroundColor: ColorData, borderColor: ColorData, borderWidth: Double, normalKeyFillColor: ColorData, specialKeyFillColor: ColorData, pushedKeyFillColor: ColorData, suggestKeyFillColor: ColorData? = nil, suggestLabelTextColor: ColorData? = nil, keyShadow: ThemeShadowData<ColorData>? = nil) {
        self.id = id
        self.backgroundColor = backgroundColor
        self.picture = picture
        self.textColor = textColor
        self.textFont = textFont
        self.resultTextColor = resultTextColor
        self.resultBackgroundColor = resultBackgroundColor
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.normalKeyFillColor = normalKeyFillColor
        self.specialKeyFillColor = specialKeyFillColor
        self.pushedKeyFillColor = pushedKeyFillColor
        self.suggestKeyFillColor = suggestKeyFillColor
        self.suggestLabelTextColor = suggestLabelTextColor
        self.keyShadow = keyShadow
    }

    enum CodingKeys: CodingKey {
        case id
        case backgroundColor
        case picture
        case textColor
        case textFont
        case resultTextColor
        case resultBackgroundColor
        case borderColor
        case borderWidth
        case normalKeyFillColor
        case specialKeyFillColor
        case pushedKeyFillColor
        case suggestKeyFillColor
        case suggestLabelTextColor
        case keyShadow
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let backgroundColor = try container.decode(ColorData.self, forKey: .backgroundColor)
        self.id = try container.decode(Int.self, forKey: .id)
        self.backgroundColor = backgroundColor
        self.picture = try container.decode(ThemePicture.self, forKey: .picture)
        self.textColor = try container.decode(ColorData.self, forKey: .textColor)
        self.textFont = try container.decode(ThemeFontWeight.self, forKey: .textFont)
        self.resultTextColor = try container.decode(ColorData.self, forKey: .resultTextColor)
        self.resultBackgroundColor = (try? container.decode(ColorData.self, forKey: .resultBackgroundColor)) ?? backgroundColor
        self.borderColor = try container.decode(ColorData.self, forKey: .borderColor)
        self.borderWidth = try container.decode(Double.self, forKey: .borderWidth)
        self.normalKeyFillColor = try container.decode(ColorData.self, forKey: .normalKeyFillColor)
        self.specialKeyFillColor = try container.decode(ColorData.self, forKey: .specialKeyFillColor)
        self.pushedKeyFillColor = try container.decode(ColorData.self, forKey: .pushedKeyFillColor)
        self.suggestKeyFillColor = try? container.decode(ColorData?.self, forKey: .suggestKeyFillColor)
        /// エントリがない場合はデフォルトで黒にする
        self.suggestLabelTextColor = (try? container.decode(ColorData?.self, forKey: .suggestLabelTextColor)) ?? .color(Color(white: 0))
        self.keyShadow = try? container.decode(ThemeShadowData<ColorData>?.self, forKey: .keyShadow)
    }

    public var prominentBackgroundColor: Color {
        ColorTools.hsv(self.resultBackgroundColor.color) { h, s, v, a in
            Color(hue: h, saturation: s, brightness: min(1, 0.7 * v + 0.3), opacity: min(1, 0.8 * a + 0.2 ))
        } ?? self.normalKeyFillColor.color
    }

    public var tabBarButtonBackgroundColor: Color {
        if case .dynamic(.clear, .normal) = self.resultBackgroundColor {
            .white
        } else {
            prominentBackgroundColor
        }
    }

    public var tabBarButtonForegroundColor: Color {
        if case .dynamic(.clear, .normal) = self.resultBackgroundColor {
            Color(red: 0.5, green: 0.043, blue: 0.016)
        } else {
            self.resultTextColor.color
        }
    }

}

public struct ThemeShadowData<ColorData>: Codable, Equatable, Sendable where ColorData: Codable & Equatable & Sendable {
    public init(color: ColorData, radius: CGFloat, x: CGFloat, y: CGFloat) {
        self.color = color
        self.radius = radius
        self.x = x
        self.y = y
    }

    public var color: ColorData
    public var radius: CGFloat
    public var x: CGFloat
    public var y: CGFloat
}

public enum ThemeFontWeight: Int, Codable, Sendable {
    case ultraLight = 1
    case thin = 2
    case light = 3
    case regular = 4
    case medium = 5
    case semibold = 6
    case bold = 7
    case heavy = 8
    case black = 9

    public var weight: Font.Weight {
        switch self {
        case .ultraLight:
            return .ultraLight
        case .thin:
            return .thin
        case .light:
            return .light
        case .regular:
            return .regular
        case .medium:
            return .medium
        case .semibold:
            return .semibold
        case .bold:
            return .bold
        case .heavy:
            return .heavy
        case .black:
            return .black
        }
    }

}
