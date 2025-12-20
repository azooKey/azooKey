//
//  KeyLabel.swift
//  Keyboard
//
//  Created by ensan on 2020/10/20.
//  Copyright © 2020 ensan. All rights reserved.
//

import Foundation
import SwiftUI
import struct CustardKit.CustardKeyDirectionalLabel

public enum KeyLabelType: Sendable, Equatable {
    case text(String)
    case symbols([String])
    case mainAndDirections(String, CustardKeyDirectionalLabel)
    case image(String)
    case customImage(String)
    case changeKeyboard
    case selectable(String, String)
}

public struct DirectionalKeyLabel: View {
    public init(main: String, directions: CustardKeyDirectionalLabel, font: Font = .body, subFont: Font = .caption) {
        self.main = main
        self.directions = directions
        self.font = font
        self.subFont = subFont
    }
    
    let main: String
    let directions: CustardKeyDirectionalLabel
    let font: Font
    let subFont: Font

    @ViewBuilder
    private func optionalLabel(_ label: String?, font: Font) -> some View {
        if let label {
            Text(label)
                .font(font)
        }
    }

    public var body: some View {
        ZStack {
            HStack {
                self.optionalLabel(directions.left, font: subFont)
                Spacer(minLength: 0)
                self.optionalLabel(directions.right, font: subFont)
            }
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack {
                self.optionalLabel(directions.top, font: subFont)
                Spacer(minLength: 0)
                self.optionalLabel(directions.bottom, font: subFont)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Text(main)
                .font(font)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

@MainActor
public struct KeyLabel<Extension: ApplicationSpecificKeyboardViewExtension>: View {
    private let labelType: KeyLabelType
    private let width: CGFloat
    private var textColor: Color?
    private var textSize: Design.Fonts.LabelFontSizeStrategy
    @Environment(Extension.Theme.self) private var theme
    @Environment(\.userActionManager) private var action
    @EnvironmentObject private var variableStates: VariableStates

    private var mainKeyColor: Color {
        textColor ?? theme.textColor.color
    }

    init(_ type: KeyLabelType, width: CGFloat, textSize: Design.Fonts.LabelFontSizeStrategy = .large, textColor: Color? = nil) {
        self.labelType = type
        self.width = width
        self.textColor = textColor
        self.textSize = textSize
    }

    private var keyViewFontSize: CGFloat {
        Extension.SettingProvider.keyViewFontSize
    }

    public var body: some View {
        switch self.labelType {
        case let .text(text):
            let font = Design.fonts.keyLabelFont(text: text, width: width, fontSize: self.textSize, userDecidedSize: keyViewFontSize, theme: theme)
            Text(text)
                .font(font)
                .foregroundStyle(mainKeyColor)
                .allowsHitTesting(false)

        case let .symbols(symbols):
            let mainText = symbols.first!
            let font = Design.fonts.keyLabelFont(text: mainText, width: width, fontSize: self.textSize, userDecidedSize: keyViewFontSize, theme: theme)
            let subText = symbols.dropFirst().joined()
            let subFont = Design.fonts.keyLabelFont(text: subText, width: width, fontSize: .xxsmall, userDecidedSize: keyViewFontSize, theme: theme)
            VStack {
                Text(mainText)
                    .font(font)
                Text(subText)
                    .font(subFont)
            }
            .foregroundStyle(mainKeyColor)
            .allowsHitTesting(false)

        case let .mainAndDirections(mainText, directions):
            let font = Design.fonts.keyLabelFont(text: mainText, width: width, fontSize: self.textSize, userDecidedSize: keyViewFontSize, theme: theme)
            let directionLabels = [
                directions.top,
                directions.left,
                directions.right,
                directions.bottom
            ]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            let subFontText = directionLabels.max(by: { $0.count < $1.count }) ?? ""
            let subFont = Design.fonts.keyLabelFont(text: subFontText, width: width, fontSize: .xsmall, userDecidedSize: keyViewFontSize, theme: theme)
            DirectionalKeyLabel(main: mainText, directions: directions, font: font, subFont: subFont)
                .foregroundStyle(mainKeyColor)
                .allowsHitTesting(false)
        case let .image(imageName):
            Image(systemName: imageName)
                .font(Design.fonts.iconImageFont(keyViewFontSizePreference: Extension.SettingProvider.keyViewFontSize, theme: theme))
                .foregroundStyle(mainKeyColor)
                .allowsHitTesting(false)

        case let .customImage(imageName):
            Image(imageName)
                .resizable()
                .frame(width: 30, height: 30, alignment: .leading)
                .allowsHitTesting(false)

        case .changeKeyboard:
            (self.action.makeChangeKeyboardButtonView() as ChangeKeyboardButtonView<Extension>)
                .foregroundStyle(mainKeyColor)

        case let .selectable(primary, secondery):
            let font = Design.fonts.keyLabelFont(text: primary + primary, width: width, fontSize: self.textSize, userDecidedSize: keyViewFontSize, theme: theme)
            let subFont = Design.fonts.keyLabelFont(text: secondery + secondery, width: width, fontSize: .small, userDecidedSize: keyViewFontSize, theme: theme)

            HStack(alignment: .bottom) {
                Text(primary)
                    .font(font)
                    .padding(.trailing, -5)
                    .foregroundStyle(mainKeyColor)
                Text(secondery)
                    .font(subFont.bold())
                    .foregroundStyle(.gray)
                    .padding(.leading, -5)
                    .offset(y: -1)
            }.allowsHitTesting(false)
        }
    }

    consuming func textColor(_ color: Color?) -> Self {
        self.textColor = color
        return self
    }
    consuming func textSize(_ textSize: Design.Fonts.LabelFontSizeStrategy) -> Self {
        self.textSize = textSize
        return self
    }
}
