//
//  VerticalCustomKeyboard.swift
//  azooKey
//
//  Created by ensan on 2021/02/18.
//  Copyright © 2021 ensan. All rights reserved.
//

import CustardKit
import Foundation
import SwiftUI

fileprivate extension CustardKeyLabelStyle {
    var keyLabelType: KeyLabelType {
        switch self {
        case let .text(value):
            return .text(value)
        case let .systemImage(value):
            return .image(value)
        case let .mainAndSub(main, sub):
            return .symbols([main, sub])
        }
    }
}

fileprivate extension CustardInterfaceLayoutScrollValue {
    var scrollDirection: Axis.Set {
        switch self.direction {
        case .horizontal:
            return .horizontal
        case .vertical:
            return .vertical
        }
    }
}

fileprivate extension CustardInterfaceStyle {
    var keyboardLayout: KeyboardLayout {
        switch self {
        case .tenkeyStyle:
            return .flick
        case .pcStyle:
            return .qwerty
        }
    }
}

fileprivate extension CustardInterface {
    func tabDesign(interfaceSize: CGSize, keyboardOrientation: KeyboardOrientation) -> TabDependentDesign {
        switch self.keyLayout {
        case let .gridFit(value):
            return TabDependentDesign(width: value.rowCount, height: value.columnCount, interfaceSize: interfaceSize, orientation: keyboardOrientation)
        case let .gridScroll(value):
            switch value.direction {
            case .vertical:
                return TabDependentDesign(width: CGFloat(Int(value.rowCount)), height: CGFloat(value.columnCount), interfaceSize: interfaceSize, orientation: keyboardOrientation)
            case .horizontal:
                return TabDependentDesign(width: CGFloat(value.rowCount), height: CGFloat(Int(value.columnCount)), interfaceSize: interfaceSize, orientation: keyboardOrientation)
            }
        }
    }

    @MainActor func flickKeyModels<Extension: ApplicationSpecificKeyboardViewExtension>(extension _: Extension.Type) -> [KeyPosition: (model: any FlickKeyModelProtocol<Extension>, width: Int, height: Int)] {
        self.keys.reduce(into: [:]) {dictionary, value in
            switch value.key {
            case let .gridFit(data):
                dictionary[.gridFit(x: data.x, y: data.y)] = (value.value.flickKeyModel(extension: Extension.self), data.width, data.height)
            case let .gridScroll(data):
                dictionary[.gridScroll(index: data.index)] = (value.value.flickKeyModel(extension: Extension.self), 1, 1)
            }
        }
    }

    @MainActor func qwertyKeyModels<Extension: ApplicationSpecificKeyboardViewExtension>(extension _: Extension.Type) -> [KeyPosition: (model: any QwertyKeyModelProtocol<Extension>, sizeType: QwertyKeySizeType)] {
        self.keys.reduce(into: [:]) {dictionary, value in
            switch value.key {
            case let .gridFit(data):
                dictionary[.gridFit(x: data.x, y: data.y)] = (value.value.qwertyKeyModel(layout: self.keyLayout, extension: Extension.self), .unit(width: data.width, height: data.height))
            case let .gridScroll(data):
                dictionary[.gridScroll(index: data.index)] = (value.value.qwertyKeyModel(layout: self.keyLayout, extension: Extension.self), .unit(width: 1, height: 1))
            }
        }
    }
}

fileprivate extension CustardKeyDesign.ColorType {
    var flickKeyBackgroundStyle: FlickKeyBackgroundStyle {
        switch self {
        case .normal:
            return .normal
        case .special:
            return .tabkey
        case .selected:
            return .selected
        case .unimportant:
            return .unimportant
        }
    }

    var qwertyKeyColorType: QwertyUnpressedKeyBackground {
        switch self {
        case .normal:
            return .normal
        case .special:
            return .special
        case .selected:
            return .selected
        case .unimportant:
            return .unimportant
        }
    }

    var simpleKeyColorType: SimpleUnpressedKeyColorType {
        switch self {
        case .normal:
            return .normal
        case .special:
            return .special
        case .selected:
            return .selected
        case .unimportant:
            return .unimportant
        }
    }

}

extension CustardInterfaceKey {
    @MainActor public func flickKeyModel<Extension: ApplicationSpecificKeyboardViewExtension>(extension _: Extension.Type) -> any FlickKeyModelProtocol<Extension> {
        switch self {
        case let .system(value):
            switch value {
            case .changeKeyboard:
                return FlickChangeKeyboardModel.shared
            case .enter:
                return FlickEnterKeyModel()
            case .upperLower:
                return FlickAaKeyModel()
            case .nextCandidate:
                return FlickNextCandidateKeyModel.shared
            case .flickKogaki:
                return FlickKogakiKeyModel.shared
            case .flickKutoten:
                return FlickKanaSymbolsKeyModel.shared
            case .flickHiraTab:
                return FlickTabKeyModel.hiraTabKeyModel()
            case .flickAbcTab:
                return FlickTabKeyModel.abcTabKeyModel()
            case .flickStar123Tab:
                return FlickTabKeyModel.numberTabKeyModel()
            }
        case let .custom(value):
            let flickKeyModels: [FlickDirection: FlickedKeyModel] = value.variations.reduce(into: [:]) {dictionary, variation in
                switch variation.type {
                case let .flickVariation(direction):
                    dictionary[direction] = FlickedKeyModel(
                        labelType: variation.key.design.label.keyLabelType,
                        pressActions: variation.key.press_actions.map {$0.actionType},
                        longPressActions: variation.key.longpress_actions.longpressActionType
                    )
                case .longpressVariation:
                    break
                }
            }
            return FlickKeyModel(
                labelType: value.design.label.keyLabelType,
                pressActions: value.press_actions.map {$0.actionType},
                longPressActions: value.longpress_actions.longpressActionType,
                flickKeys: flickKeyModels,
                needSuggestView: value.longpress_actions == .none && !value.variations.isEmpty,
                keycolorType: value.design.color.flickKeyBackgroundStyle
            )
        }
    }

    private func convertToQwertyKeyModel<Extension: ApplicationSpecificKeyboardViewExtension>(customKey: KeyFlickSetting.SettingData, extension _: Extension.Type) -> any QwertyKeyModelProtocol<Extension> {
        let variations = VariationsModel([customKey.flick[.left], customKey.flick[.top], customKey.flick[.right], customKey.flick[.bottom]].compactMap {$0}.map {(label: $0.labelType, actions: $0.pressActions)})
        return QwertyKeyModel(labelType: customKey.labelType, pressActions: customKey.actions, longPressActions: customKey.longpressActions, variationsModel: variations, keyColorType: .normal, needSuggestView: false, for: (1, 1))
    }

    @MainActor func qwertyKeyModel<Extension: ApplicationSpecificKeyboardViewExtension>(layout: CustardInterfaceLayout, extension: Extension.Type) -> any QwertyKeyModelProtocol<Extension> {
        let rowInfo = switch layout {
        case let .gridFit(value): (normal: value.rowCount, functional: 0, space: 0, enter: 0)
        case let .gridScroll(value): (normal: Int(value.rowCount), functional: 0, space: 0, enter: 0)
        }
        switch self {
        case let .system(value):
            switch value {
            case .changeKeyboard:
                let changeKeyboardKeySize: QwertyKeySizeType = .normal(of: 1, for: 1)
                return if let second = Extension.SettingProvider.preferredLanguage.second {
                    QwertyConditionalKeyModel(keySizeType: changeKeyboardKeySize, needSuggestView: false, unpressedKeyBackground: .special) { states in
                        if SemiStaticStates.shared.needsInputModeSwitchKey {
                            return QwertyChangeKeyboardKeyModel(keySizeType: changeKeyboardKeySize)
                        } else {
                            // 普通のキーで良い場合
                            let targetTab: TabData = switch second {
                            case .en_US:
                                .system(.user_english)
                            case .ja_JP, .none, .el_GR:
                                .system(.user_japanese)
                            }
                            return switch states.tabManager.existentialTab() {
                            case .qwerty_hira, .qwerty_abc:
                                QwertyFunctionalKeyModel(labelType: .text("#+="), rowInfo: rowInfo, pressActions: [.moveTab(.system(.qwerty_symbols))], longPressActions: .init(start: [.setTabBar(.toggle)]))
                            case .qwerty_numbers, .qwerty_symbols:
                                QwertyFunctionalKeyModel(labelType: .text(second.symbol), rowInfo: rowInfo, pressActions: [.moveTab(targetTab)])
                            default:
                                QwertyFunctionalKeyModel(labelType: .image("arrowtriangle.left.and.line.vertical.and.arrowtriangle.right"), rowInfo: rowInfo, pressActions: [.setCursorBar(.toggle)])
                            }
                        }
                    }
                } else {
                    QwertyConditionalKeyModel(keySizeType: changeKeyboardKeySize, needSuggestView: false, unpressedKeyBackground: .special) { states in
                        if SemiStaticStates.shared.needsInputModeSwitchKey {
                            // 地球儀キーが必要な場合
                            QwertyChangeKeyboardKeyModel(keySizeType: changeKeyboardKeySize)
                        } else {
                            QwertyFunctionalKeyModel(labelType: .image("arrowtriangle.left.and.line.vertical.and.arrowtriangle.right"), rowInfo: rowInfo, pressActions: [.setCursorBar(.toggle)])
                        }
                    }
                }
            case .enter:
                return QwertyEnterKeyModel(keySizeType: .enter)
            case .upperLower:
                return QwertyAaKeyModel()
            case .nextCandidate:
                return QwertyNextCandidateKeyModel()
            case .flickKogaki:
                return convertToQwertyKeyModel(customKey: Extension.SettingProvider.koganaFlickCustomKey.compiled(), extension: Extension.self)
            case .flickKutoten:
                return convertToQwertyKeyModel(customKey: Extension.SettingProvider.kanaSymbolsFlickCustomKey.compiled(), extension: Extension.self)
            case .flickHiraTab:
                return convertToQwertyKeyModel(customKey: Extension.SettingProvider.hiraTabFlickCustomKey.compiled(), extension: Extension.self)
            case .flickAbcTab:
                return convertToQwertyKeyModel(customKey: Extension.SettingProvider.abcTabFlickCustomKey.compiled(), extension: Extension.self)
            case .flickStar123Tab:
                return convertToQwertyKeyModel(customKey: Extension.SettingProvider.symbolsTabFlickCustomKey.compiled(), extension: Extension.self)
            }
        case let .custom(value):
            let variations: [(label: KeyLabelType, actions: [ActionType])] = value.variations.reduce(into: []) {array, variation in
                switch variation.type {
                case .flickVariation:
                    break
                case .longpressVariation:
                    array.append((variation.key.design.label.keyLabelType, variation.key.press_actions.map {$0.actionType}))
                }
            }

            return QwertyKeyModel(
                labelType: value.design.label.keyLabelType,
                pressActions: value.press_actions.map {$0.actionType},
                longPressActions: value.longpress_actions.longpressActionType,
                variationsModel: VariationsModel(variations),
                keyColorType: value.design.color.qwertyKeyColorType,
                needSuggestView: value.longpress_actions == .none,
                for: (1, 1)
            )
        }
    }

    func simpleKeyModel<Extension: ApplicationSpecificKeyboardViewExtension>(extension _: Extension.Type) -> any SimpleKeyModelProtocol<Extension> {
        switch self {
        case let .system(value):
            switch value {
            case .changeKeyboard:
                return SimpleChangeKeyboardKeyModel()
            case .enter:
                return SimpleEnterKeyModel()
            case .upperLower:
                return SimpleKeyModel(keyLabelType: .text("a/A"), unpressedKeyColorType: .special, pressActions: [.changeCharacterType])
            case .nextCandidate:
                return SimpleNextCandidateKeyModel()
            case .flickKogaki:
                return SimpleKeyModel(keyLabelType: .text("小ﾞﾟ"), unpressedKeyColorType: .special, pressActions: [.changeCharacterType])
            case .flickKutoten:
                return SimpleKeyModel(keyLabelType: .text("、"), unpressedKeyColorType: .normal, pressActions: [.input("、")])
            case .flickHiraTab:
                return SimpleKeyModel(keyLabelType: .text("あいう"), unpressedKeyColorType: .special, pressActions: [.moveTab(.system(.user_japanese))])
            case .flickAbcTab:
                return SimpleKeyModel(keyLabelType: .text("abc"), unpressedKeyColorType: .special, pressActions: [.moveTab(.system(.user_english))])
            case .flickStar123Tab:
                return SimpleKeyModel(keyLabelType: .text("☆123"), unpressedKeyColorType: .special, pressActions: [.moveTab(.system(.flick_numbersymbols))])
            }
        case let .custom(value):
            return SimpleKeyModel(
                keyLabelType: value.design.label.keyLabelType,
                unpressedKeyColorType: value.design.color.simpleKeyColorType,
                pressActions: value.press_actions.map {$0.actionType},
                longPressActions: value.longpress_actions.longpressActionType
            )
        }
    }
}

@MainActor
struct CustomKeyboardView<Extension: ApplicationSpecificKeyboardViewExtension>: View {
    private let custard: Custard
    private var tabDesign: TabDependentDesign {
        custard.interface.tabDesign(interfaceSize: variableStates.interfaceSize, keyboardOrientation: variableStates.keyboardOrientation)
    }
    @EnvironmentObject private var variableStates: VariableStates

    init(custard: Custard) {
        self.custard = custard
    }

    private func qwertyKeyData(x: Int, y: Int, size: QwertyKeySizeType) -> (position: CGPoint, size: CGSize) {
        let width = size.width(design: tabDesign)
        let height = size.height(design: tabDesign)
        let dx = width * 0.5 + tabDesign.keyViewWidth * CGFloat(x) + tabDesign.horizontalSpacing * CGFloat(x)
        let dy = height * 0.5 + tabDesign.keyViewHeight * CGFloat(y) + tabDesign.verticalSpacing * CGFloat(y)
        return (CGPoint(x: dx, y: dy), CGSize(width: width, height: height))
    }

    var body: some View {
        switch custard.interface.keyLayout {
        case let .gridFit(value):
            switch custard.interface.keyStyle {
            case .tenkeyStyle:
                CustardFlickKeysView(models: custard.interface.flickKeyModels(extension: Extension.self), tabDesign: tabDesign, layout: value) {(view: FlickKeyView<Extension>, _, _) in
                    view
                }
            case .pcStyle:
                let models = custard.interface.qwertyKeyModels(extension: Extension.self)
                ZStack {
                    ForEach(0..<value.columnCount, id: \.self) {y in
                        ForEach(0..<value.rowCount, id: \.self) {x in
                            if let data = models[.gridFit(x: x, y: y)] {
                                let info = qwertyKeyData(x: x, y: y, size: data.sizeType)
                                QwertyKeyView<Extension>(model: data.model, tabDesign: tabDesign, size: info.size)
                                    .position(x: info.position.x, y: info.position.y)
                            }
                        }
                    }.frame(width: tabDesign.keysWidth, height: tabDesign.keysHeight)
                }
            }
        case let .gridScroll(value):
            let models = (0..<custard.interface.keys.count).compactMap { index in
                (custard.interface.keys[.gridScroll(GridScrollPositionSpecifier(index))]).map {($0, index)}
            }
            CustardScrollKeysView<Extension, Int, _>(models: models, tabDesign: tabDesign, layout: value) { (view, _) in
                view
            }
        }
    }
}

public struct CustardScrollKeysView<Extension: ApplicationSpecificKeyboardViewExtension, ID: Hashable, Content: View>: View {
    public init(models: [(CustardInterfaceKey, ID)], tabDesign: TabDependentDesign, layout: CustardInterfaceLayoutScrollValue, @ViewBuilder generator: @escaping (_ view: SimpleKeyView<Extension>, _ id: ID) -> (Content)) {
        self.models = models
        self.tabDesign = tabDesign
        self.layout = layout
        self.contentGenerator = generator
    }

    private let contentGenerator: (_ view: SimpleKeyView<Extension>, _ id: ID) -> (Content)
    private let models: [(CustardInterfaceKey, ID)]
    private let tabDesign: TabDependentDesign
    private let layout: CustardInterfaceLayoutScrollValue

    public var body: some View {
        let height = tabDesign.keysHeight
        switch layout.direction {
        case .vertical:
            let gridItem = GridItem(.fixed(tabDesign.keyViewWidth), spacing: tabDesign.horizontalSpacing / 2)
            ScrollView(.vertical) {
                LazyVGrid(columns: Array(repeating: gridItem, count: Int(layout.rowCount)), spacing: tabDesign.verticalSpacing / 2) {
                    ForEach(models, id: \.1) {(model, id) in
                        contentGenerator(
                            SimpleKeyView<Extension>(
                                model: model.simpleKeyModel(extension: Extension.self),
                                tabDesign: tabDesign
                            ),
                            id
                        )
                    }
                }
            }.frame(height: height)
        case .horizontal:
            let gridItem = GridItem(.fixed(tabDesign.keyViewHeight), spacing: tabDesign.verticalSpacing / 2)
            ScrollView(.horizontal) {
                LazyHGrid(rows: Array(repeating: gridItem, count: Int(layout.columnCount)), spacing: tabDesign.horizontalSpacing / 2) {
                    ForEach(models, id: \.1) {(model, id) in
                        contentGenerator(
                            SimpleKeyView<Extension>(
                                model: model.simpleKeyModel(extension: Extension.self),
                                tabDesign: tabDesign
                            ),
                            id
                        )
                    }
                }
            }.frame(height: height)
        }
    }
}


public struct CustardFlickKeysView<Extension: ApplicationSpecificKeyboardViewExtension, Content: View>: View {
    @State private var suggestState = FlickSuggestState()

    public init(models: [KeyPosition: (model: any FlickKeyModelProtocol<Extension>, width: Int, height: Int)], tabDesign: TabDependentDesign, layout: CustardInterfaceLayoutGridValue, blur: Bool = false, @ViewBuilder generator: @escaping (FlickKeyView<Extension>, Int, Int) -> (Content)) {
        self.models = models
        self.tabDesign = tabDesign
        self.layout = layout
        self.blur = blur
        self.contentGenerator = generator
    }

    private let contentGenerator: (FlickKeyView<Extension>, Int, Int) -> (Content)
    private let models: [KeyPosition: (model: any FlickKeyModelProtocol<Extension>, width: Int, height: Int)]
    private let tabDesign: TabDependentDesign
    private let layout: CustardInterfaceLayoutGridValue
    private let blur: Bool

    @MainActor private func flickKeyData(x: Int, y: Int, width: Int, height: Int) -> (position: CGPoint, size: CGSize, contentSize: CGSize) {
        let width = tabDesign.keyViewWidth(widthCount: width)
        let height = tabDesign.keyViewHeight(heightCount: height)
        let dx = width * 0.5 + tabDesign.keyViewWidth * CGFloat(x) + tabDesign.horizontalSpacing * CGFloat(x)
        let dy = height * 0.5 + tabDesign.keyViewHeight * CGFloat(y) + tabDesign.verticalSpacing * CGFloat(y)
        let contentWidth = width + tabDesign.horizontalSpacing
        let contentHeight = height + tabDesign.verticalSpacing
        return (CGPoint(x: dx, y: dy), CGSize(width: width, height: height), CGSize(width: contentWidth, height: contentHeight))
    }

    public var body: some View {
        ZStack {
            let hasAllSuggest = self.suggestState.items.contains(where: {$0.value.contains(where: {$0.value == .all})})
            let needKeyboardBlur = blur && hasAllSuggest
            ForEach(0..<layout.rowCount, id: \.self) {x in
                let columnSuggestStates = self.suggestState.items[x, default: [:]]
                // 可能ならカラムごとにblurをかけることで描画コストを減らす
                let needColumnWideBlur = needKeyboardBlur && columnSuggestStates.allSatisfy {$0.value != .all}
                ForEach(0..<layout.columnCount, id: \.self) {y in
                    if let data = models[.gridFit(x: x, y: y)] {
                        let info = flickKeyData(x: x, y: y, width: data.width, height: data.height)
                        let suggestState = columnSuggestStates[y]
                        let needBlur = needKeyboardBlur && !needColumnWideBlur && suggestState == nil
                        contentGenerator(FlickKeyView(model: data.model, size: info.size, position: (x, y), suggestState: $suggestState), x, y)
                            .zIndex(suggestState != nil ? 1 : 0)
                            .overlay(alignment: .center) {
                                if let suggestType = suggestState {
                                    FlickSuggestView<Extension>(model: data.model, tabDesign: tabDesign, size: info.size, suggestType: suggestType)
                                        .zIndex(2)
                                }
                            }
                            .frame(width: info.contentSize.width, height: info.contentSize.height)
                            .contentShape(Rectangle())
                            .position(x: info.position.x, y: info.position.y)
                            .opacity(needBlur ? 0.75 : 1.0)
                    }
                }
                .zIndex(columnSuggestStates.isEmpty ? 0 : 1)
                .opacity(needColumnWideBlur ? 0.75 : 1.0)
            }
            .frame(width: tabDesign.keysWidth, height: tabDesign.keysHeight)
        }
    }
}
