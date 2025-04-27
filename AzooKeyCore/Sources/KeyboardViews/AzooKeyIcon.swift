//
//  AzooKeyIconView.swift
//  AzooKeyIconView
//
//  Created by ensan on 2021/07/22.
//  Copyright © 2021 ensan. All rights reserved.
//

import SwiftUI

public struct AzooKeyIcon: View {
    @Environment(\.colorScheme) private var colorScheme
    private let color: Color
    private let looks: Looks
    private let arguments: Arguments
    public enum Looks {
        case normal
        case king
        case santaClaus
        case strawHat
        case fire
    }
    public enum Color {
        case auto
        case color(SwiftUI.Color)
    }
    private enum Arguments {
        case relative(size: CGFloat, textStyle: Font.TextStyle)
        case fixed(size: CGFloat)
    }
    public init(fontSize: CGFloat, relativeTo textStyle: Font.TextStyle = .body, color: Color = .auto, looks: Looks = .normal) {
        self.color = color
        self.arguments = .relative(size: fontSize, textStyle: textStyle)
        self.looks = looks
    }

    public init(fixedSize: CGFloat, color: Color = .auto, looks: Looks = .normal) {
        self.color = color
        self.arguments = .fixed(size: fixedSize)
        self.looks = looks
    }

    private var foregroundColor: SwiftUI.Color {
        switch self.color {
        case .auto:
            switch colorScheme {
            case .light:
                .init(red: 0.398, green: 0.113, blue: 0.218)
            case .dark:
                .white
            @unknown default:
                .init(red: 0.398, green: 0.113, blue: 0.218)
            }
        case let .color(color):
            color
        }
    }

    @ViewBuilder
    private var icon: some View {
        switch looks {
        case .normal:
            Text("1")
                .foregroundStyle(foregroundColor)
        case .king:
            ZStack(alignment: .center) {
                Text("α")
                    .foregroundStyle(foregroundColor)
                Text("\u{EA00}")
                    .foregroundStyle(.orange)
            }
        case .strawHat:
            ZStack(alignment: .center) {
                Text("β")
                    .foregroundStyle(foregroundColor)
                Text("\u{EA10}")
                    .foregroundStyle(SwiftUI.Color(red: 243 / 255, green: 210 / 255, blue: 82 / 255))
                Text("\u{EA11}")
                    .foregroundStyle(.white)
            }
        case .santaClaus:
            ZStack(alignment: .center) {
                Text("γ")
                    .foregroundStyle(foregroundColor)
                Text("\u{EA20}")
                    .foregroundStyle(.black)
                Text("\u{EA21}")
                    .foregroundStyle(.white)
                Text("\u{EA22}")
                    .foregroundStyle(.red)
            }
        case .fire:
            Text("δ")
                .foregroundStyle(foregroundColor)
        }
    }

    private var font: Font {
        switch self.arguments {
        case let .relative(size: size, textStyle: textStyle):
            return Design.fonts.azooKeyIconFont(size, relativeTo: textStyle)
        case let .fixed(size: size):
            return Design.fonts.azooKeyIconFont(fixedSize: size)
        }
    }

    public var body: some View {
        icon.font(font)
    }
}
