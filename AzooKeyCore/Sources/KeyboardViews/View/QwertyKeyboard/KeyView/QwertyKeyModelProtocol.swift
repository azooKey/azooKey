//
//  QwertyKeyModelProtocol.swift
//  Keyboard
//
//  Created by ensan on 2020/09/18.
//  Copyright © 2020 ensan. All rights reserved.
//

import Foundation
import KeyboardThemes
import SwiftUI

public typealias QwertyKeyBackgroundStyleValue = (color: Color, blendMode: BlendMode)

extension ThemeColor {
    var qwertyKeyBackgroundStyle: QwertyKeyBackgroundStyleValue {
        (self.color, self.blendMode)
    }
}

enum QwertyKeySizeType: Sendable {
    case unit(width: Int, height: Int)
    case normal(of: Int, for: Int)
    case functional(normal: Int, functional: Int, enter: Int, space: Int)
    case enter
    case space

    func width(design: TabDependentDesign) -> CGFloat {
        switch self {
        case let .unit(width: width, _):
            return design.keyViewWidth(widthCount: width)
        case let .normal(of: normalCount, for: keyCount):
            return design.qwertyScaledKeyWidth(normal: normalCount, for: keyCount)
        case let .functional(normal: normal, functional: functional, enter: enter, space: space):
            return design.qwertyFunctionalKeyWidth(normal: normal, functional: functional, enter: enter, space: space)
        case .enter:
            return design.qwertyEnterKeyWidth
        case .space:
            return design.qwertySpaceKeyWidth
        }
    }

    @MainActor func height(design: TabDependentDesign) -> CGFloat {
        switch self {
        case let .unit(_, height: height):
            return design.keyViewHeight(heightCount: height)
        default:
            return design.keyViewHeight
        }
    }
}

enum QwertyUnpressedKeyBackground: Sendable {
    case normal
    case special
    case enter
    case selected
    case unimportant

    func color<ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable>(states: VariableStates, theme: ThemeData<ThemeExtension>) -> QwertyKeyBackgroundStyleValue {
        switch self {
        case .normal:
            theme.normalKeyFillColor.qwertyKeyBackgroundStyle
        case .special:
            theme.specialKeyFillColor.qwertyKeyBackgroundStyle
        case .selected:
            theme.pushedKeyFillColor.qwertyKeyBackgroundStyle
        case .unimportant:
            (Color(white: 0, opacity: 0.001), .normal)
        case .enter:
            switch states.enterKeyState {
            case .complete:
                theme.specialKeyFillColor.qwertyKeyBackgroundStyle
            case let .return(type):
                switch type {
                case .default:
                    theme.specialKeyFillColor.qwertyKeyBackgroundStyle
                default:
                    if theme == ThemeExtension.default(layout: .qwerty) {
                        (Design.colors.specialEnterKeyColor, .normal)
                    } else if theme == ThemeExtension.native(layout: .qwerty) {
                        (.accentColor, .normal)
                    } else {
                        theme.specialKeyFillColor.qwertyKeyBackgroundStyle
                    }
                }
            }
        }
    }
}

protocol QwertyKeyModelProtocol<Extension> {
    associatedtype Extension: ApplicationSpecificKeyboardViewExtension

    var keySizeType: QwertyKeySizeType {get}
    var needSuggestView: Bool {get}

    var variationsModel: VariationsModel {get}

    @MainActor func pressActions(variableStates: VariableStates) -> [ActionType]
    @MainActor func longPressActions(variableStates: VariableStates) -> LongpressActionType
    /// 二回連続で押した際に発火するActionを指定する
    @MainActor func doublePressActions(variableStates: VariableStates) -> [ActionType]
    @MainActor func label<ThemeExtension: ApplicationSpecificKeyboardViewExtensionLayoutDependentDefaultThemeProvidable>(width: CGFloat, theme: ThemeData<ThemeExtension>, states: VariableStates, color: Color?) -> KeyLabel<Extension>
    func backgroundStyleWhenPressed(theme: Extension.Theme) -> QwertyKeyBackgroundStyleValue
    var unpressedKeyBackground: QwertyUnpressedKeyBackground {get}

    @MainActor func feedback(variableStates: VariableStates)
}

extension QwertyKeyModelProtocol {
    func backgroundStyleWhenPressed(theme: ThemeData<some ApplicationSpecificTheme>) -> QwertyKeyBackgroundStyleValue {
        theme.pushedKeyFillColor.qwertyKeyBackgroundStyle
    }
    func doublePressActions(variableStates _: VariableStates) -> [ActionType] {
        []
    }
}
