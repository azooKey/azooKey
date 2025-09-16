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
}

fileprivate extension CustardKeyDesign.ColorType {
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

fileprivate extension CustardInterface {
    @MainActor func unifiedFlickKeyModels<Extension: ApplicationSpecificKeyboardViewExtension>(extension _: Extension.Type) -> [(position: GridFitPositionSpecifier, model: any UnifiedKeyModelProtocol<Extension>)] {
        self.keys.reduce(into: []) { models, value in
            if case let .gridFit(data) = value.key {
                switch value.value {
                case let .system(sys):
                    let key: CustardInterfaceKey = .system(sys)
                    let unified = key.unifiedFlickKeyModel(extension: Extension.self)
                    models.append((data, unified))
                case let .custom(val):
                    var map: [FlickDirection: UnifiedVariation] = [:]
                    val.variations.forEach { variation in
                        if case let .flickVariation(direction) = variation.type {
                            let v = UnifiedVariation(label: variation.key.design.label.keyLabelType, pressActions: variation.key.press_actions.map { $0.actionType }, longPressActions: variation.key.longpress_actions.longpressActionType)
                            map[direction] = v
                        }
                    }
                    let colorRole: FlickCustomKeyModel<Extension>.ColorRole = switch val.design.color {
                    case .normal: .normal
                    case .special: .special
                    case .selected: .selected
                    case .unimportant: .unimportant
                    }
                    let model = FlickCustomKeyModel<Extension>(
                        labelType: val.design.label.keyLabelType,
                        pressActions: val.press_actions.map { $0.actionType },
                        longPressActions: val.longpress_actions.longpressActionType,
                        flick: map,
                        showsTapBubble: false,
                        colorRole: colorRole
                    )
                    models.append((data, model))
                }
            }
        }
    }

    @MainActor func unifiedQwertyKeyModels<Extension: ApplicationSpecificKeyboardViewExtension>(extension _: Extension.Type) -> [(position: UnifiedPositionSpecifier, model: any UnifiedKeyModelProtocol<Extension>)] {
        self.keys.reduce(into: []) { models, value in
            if case let .gridFit(data) = value.key {
                switch value.value {
                case let .system(sys):
                    let unified: any UnifiedKeyModelProtocol<Extension> = {
                        switch sys {
                        case .enter: return UnifiedEnterKeyModel<Extension>()
                        case .upperLower: return QwertyAaKeyModel<Extension>()
                        case .nextCandidate: return QwertyNextCandidateKeyModel<Extension>()
                        case .changeKeyboard: return QwertyChangeKeyboardKeyModel<Extension>()
                        case .flickKogaki:
                            let d = Extension.SettingProvider.koganaFlickCustomKey.compiled()
                            let vars = [d.flick[.left], d.flick[.top], d.flick[.right], d.flick[.bottom]].compactMap { $0 }.map { QwertyVariationsModel.VariationElement(label: $0.labelType, actions: $0.pressActions) }
                            return QwertyGeneralKeyModel(
                                labelType: d.labelType, pressActions: d.actions, longPressActions: d.longpressActions, variations: vars, direction: .center, showsTapBubble: true, role: .special, shouldUppercaseForEnglish: false
                            )
                        case .flickKutoten:
                            let d = Extension.SettingProvider.kanaSymbolsFlickCustomKey.compiled()
                            let vars = [d.flick[.left], d.flick[.top], d.flick[.right], d.flick[.bottom]].compactMap { $0 }.map { QwertyVariationsModel.VariationElement(label: $0.labelType, actions: $0.pressActions) }
                            return QwertyGeneralKeyModel(
                                labelType: d.labelType, pressActions: d.actions, longPressActions: d.longpressActions, variations: vars, direction: .center, showsTapBubble: true, role: .special, shouldUppercaseForEnglish: false
                            )
                        case .flickHiraTab:
                            let d = Extension.SettingProvider.hiraTabFlickCustomKey.compiled()
                            let vars = [d.flick[.left], d.flick[.top], d.flick[.right], d.flick[.bottom]].compactMap { $0 }.map { QwertyVariationsModel.VariationElement(label: $0.labelType, actions: $0.pressActions) }
                            return QwertyGeneralKeyModel(
                                labelType: d.labelType, pressActions: d.actions, longPressActions: d.longpressActions, variations: vars, direction: .center, showsTapBubble: true, role: .special, shouldUppercaseForEnglish: false
                            )
                        case .flickAbcTab:
                            let d = Extension.SettingProvider.abcTabFlickCustomKey.compiled()
                            let vars = [d.flick[.left], d.flick[.top], d.flick[.right], d.flick[.bottom]].compactMap { $0 }.map { QwertyVariationsModel.VariationElement(label: $0.labelType, actions: $0.pressActions) }
                            return QwertyGeneralKeyModel(
                                labelType: d.labelType, pressActions: d.actions, longPressActions: d.longpressActions, variations: vars, direction: .center, showsTapBubble: true, role: .special, shouldUppercaseForEnglish: false
                            )
                        case .flickStar123Tab:
                            let d = Extension.SettingProvider.symbolsTabFlickCustomKey.compiled()
                            let vars = [d.flick[.left], d.flick[.top], d.flick[.right], d.flick[.bottom]].compactMap { $0 }.map { QwertyVariationsModel.VariationElement(label: $0.labelType, actions: $0.pressActions) }
                            return QwertyGeneralKeyModel(
                                labelType: d.labelType, pressActions: d.actions, longPressActions: d.longpressActions, variations: vars, direction: .center, showsTapBubble: true, role: .special, shouldUppercaseForEnglish: false
                            )
                        }
                    }()
                    models.append((.init(x: CGFloat(data.x), y: CGFloat(data.y), width: CGFloat(data.width), height: CGFloat(data.height)), unified))
                case let .custom(val):
                    let variations = val.variations.compactMap { variation -> QwertyVariationsModel.VariationElement? in
                        switch variation.type {
                        case .flickVariation:
                            return nil
                        case .longpressVariation:
                            return .init(label: variation.key.design.label.keyLabelType, actions: variation.key.press_actions.map { $0.actionType })
                        }
                    }
                    let needSuggest = val.longpress_actions.isEmpty
                    let colorRole: QwertyGeneralKeyModel<Extension>.UnpressedRole = switch val.design.color {
                    case .normal: .normal
                    case .special: .special
                    case .selected: .selected
                    case .unimportant: .unimportant
                    }
                    let model = QwertyGeneralKeyModel<Extension>(
                        labelType: val.design.label.keyLabelType,
                        pressActions: val.press_actions.map { $0.actionType },
                        longPressActions: val.longpress_actions.longpressActionType,
                        variations: variations,
                        direction: .center,
                        showsTapBubble: needSuggest,
                        role: colorRole,
                        shouldUppercaseForEnglish: false
                    )
                    models.append((.init(x: CGFloat(data.x), y: CGFloat(data.y), width: CGFloat(data.width), height: CGFloat(data.height)), model))
                }
            }
        }
    }
}

extension CodableLongpressActionData {
    var isEmpty: Bool {
        self.start.isEmpty && self.repeat.isEmpty
    }
}

extension CustardInterfaceKey {
    @MainActor public func unifiedFlickKeyModel<Extension: ApplicationSpecificKeyboardViewExtension>(extension _: Extension.Type) -> any UnifiedKeyModelProtocol<Extension> {
        func fromSetting(_ data: KeyFlickSetting.SettingData, color: FlickCustomKeyModel<Extension>.ColorRole = .special) -> any UnifiedKeyModelProtocol<Extension> {
            let map = data.flick.mapValues { UnifiedVariation(label: $0.labelType, pressActions: $0.pressActions, longPressActions: $0.longPressActions) }
            return FlickCustomKeyModel<Extension>(
                labelType: data.labelType,
                pressActions: data.actions,
                longPressActions: data.longpressActions,
                flick: map,
                showsTapBubble: false,
                colorRole: color
            )
        }

        switch self {
        case let .system(value):
            switch value {
            case .changeKeyboard:
                return FlickChangeKeyboardKeyModel<Extension>()
            case .enter:
                return UnifiedEnterKeyModel<Extension>(textSize: .large)
            case .upperLower:
                return FlickAaKeyModel<Extension>()
            case .nextCandidate:
                return FlickNextCandidateKeyModel<Extension>()
            case .flickKogaki:
                return FlickKogakiKeyModel<Extension>()
            case .flickKutoten:
                return FlickKanaSymbolsKeyModel<Extension>()
            case .flickHiraTab:
                return fromSetting(Extension.SettingProvider.hiraTabFlickCustomKey.compiled())
            case .flickAbcTab:
                return fromSetting(Extension.SettingProvider.abcTabFlickCustomKey.compiled())
            case .flickStar123Tab:
                return fromSetting(Extension.SettingProvider.symbolsTabFlickCustomKey.compiled())
            }
        case let .custom(value):
            var map: [FlickDirection: UnifiedVariation] = [:]
            value.variations.forEach { variation in
                if case let .flickVariation(direction) = variation.type {
                    let v = UnifiedVariation(label: variation.key.design.label.keyLabelType, pressActions: variation.key.press_actions.map { $0.actionType }, longPressActions: variation.key.longpress_actions.longpressActionType)
                    map[direction] = v
                }
            }
            let colorRole: FlickCustomKeyModel<Extension>.ColorRole = switch value.design.color {
            case .normal: .normal
            case .special: .special
            case .selected: .selected
            case .unimportant: .unimportant
            }
            return FlickCustomKeyModel<Extension>(
                labelType: value.design.label.keyLabelType,
                pressActions: value.press_actions.map { $0.actionType },
                longPressActions: value.longpress_actions.longpressActionType,
                flick: map,
                showsTapBubble: false,
                colorRole: colorRole
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
                return SimpleKeyModel(keyLabelType: .text("a/A"), unpressedKeyColorType: .special, pressActions: [.changeCharacterType(.default)])
            case .nextCandidate:
                return SimpleNextCandidateKeyModel()
            case .flickKogaki:
                return SimpleKeyModel(keyLabelType: .text("小ﾞﾟ"), unpressedKeyColorType: .special, pressActions: [.changeCharacterType(.default)])
            case .flickKutoten:
                return SimpleKeyModel(keyLabelType: .text("、"), unpressedKeyColorType: .normal, pressActions: [.input("、")])
            case .flickHiraTab:
                return SimpleKeyModel(keyLabelType: .text("あいう"), unpressedKeyColorType: .special, pressActions: [.moveTab(.system(.user_japanese))])
            case .flickAbcTab:
                return SimpleKeyModel(keyLabelType: .text("ABC"), unpressedKeyColorType: .special, pressActions: [.moveTab(.system(.user_english))])
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
    @State private var activeSuggestKeys: Set<String> = []

    init(custard: Custard) {
        self.custard = custard
    }

    var body: some View {
        switch custard.interface.keyLayout {
        case let .gridFit(value):
            switch custard.interface.keyStyle {
            case .tenkeyStyle:
                let models = custard.interface.unifiedFlickKeyModels(extension: Extension.self)
                let unifiedModels: [(UnifiedPositionSpecifier, any UnifiedKeyModelProtocol<Extension>, UnifiedGenericKeyView<Extension>.GestureSet)] = models.map { item in
                    (
                        UnifiedPositionSpecifier(
                            x: CGFloat(item.position.x),
                            y: CGFloat(item.position.y),
                            width: CGFloat(item.position.width),
                            height: CGFloat(item.position.height)
                        ),
                        item.model,
                        .directionalFlick
                    )
                }
                UnifiedKeysView(models: unifiedModels, tabDesign: tabDesign) { keyView, _ in keyView }
            case .pcStyle:
                let models = custard.interface.unifiedQwertyKeyModels(extension: Extension.self)
                let unifiedModels: [(UnifiedPositionSpecifier, any UnifiedKeyModelProtocol<Extension>, UnifiedGenericKeyView<Extension>.GestureSet)] = models.map { item in
                    (
                        UnifiedPositionSpecifier(
                            x: item.position.x,
                            y: item.position.y,
                            width: item.position.width,
                            height: item.position.height
                        ),
                        item.model,
                        .linearVariation
                    )
                }
                UnifiedKeysView(models: unifiedModels, tabDesign: tabDesign) { keyView, _ in keyView }
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
