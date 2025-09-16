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

public extension CustardInterface {
    @MainActor func unifiedKeyModels<Extension: ApplicationSpecificKeyboardViewExtension>(extension _: Extension.Type) -> [(position: UnifiedPositionSpecifier, model: any UnifiedKeyModelProtocol<Extension>)] {
        func flickTabKeyModel(_ data: KeyFlickSetting.SettingData) -> any UnifiedKeyModelProtocol<Extension> {
            FlickTabKeyModel<Extension>(
                labelType: data.labelType,
                pressActions: data.actions,
                longPressActions: data.longpressActions,
                flick: data.flick.mapValues {
                    UnifiedVariation(label: $0.labelType, pressActions: $0.pressActions, longPressActions: $0.longPressActions)
                },
                showsTapBubble: false,
                colorRole: .special
            )
        }

        return self.keys.reduce(into: []) { models, value in
            guard case let .gridFit(data) = value.key else {
                return
            }
            let pos = UnifiedPositionSpecifier(
                x: CGFloat(data.x),
                y: CGFloat(data.y),
                width: CGFloat(data.width),
                height: CGFloat(data.height)
            )
            switch value.value {
            case let .system(sys):
                let model: any UnifiedKeyModelProtocol<Extension> = switch sys {
                case .enter:
                    switch self.keyStyle {
                    case .tenkeyStyle:
                        UnifiedEnterKeyModel<Extension>(textSize: .large)
                    case .pcStyle:
                        QwertyAaKeyModel<Extension>()
                    }
                case .upperLower:
                    switch self.keyStyle {
                    case .tenkeyStyle:
                        FlickAaKeyModel<Extension>()
                    case .pcStyle:
                        QwertyAaKeyModel<Extension>()
                    }
                case .nextCandidate:
                    switch self.keyStyle {
                    case .tenkeyStyle:
                        FlickNextCandidateKeyModel<Extension>()
                    case .pcStyle:
                        QwertyNextCandidateKeyModel<Extension>()
                    }
                case .changeKeyboard:
                    switch self.keyStyle {
                    case .tenkeyStyle:
                        FlickChangeKeyboardKeyModel<Extension>()
                    case .pcStyle:
                        QwertyChangeKeyboardKeyModel<Extension>()
                    }
                case .flickKogaki:
                    FlickKogakiKeyModel<Extension>()
                case .flickKutoten:
                    FlickKanaSymbolsKeyModel<Extension>()
                case .flickHiraTab:
                    flickTabKeyModel(Extension.SettingProvider.hiraTabFlickCustomKey.compiled())
                case .flickAbcTab:
                    flickTabKeyModel(Extension.SettingProvider.abcTabFlickCustomKey.compiled())
                case .flickStar123Tab:
                    flickTabKeyModel(Extension.SettingProvider.symbolsTabFlickCustomKey.compiled())
                }
                models.append((pos, model))
            case let .custom(val):
                var flickMap: [FlickDirection: UnifiedVariation] = [:]
                var linear: [QwertyVariationsModel.VariationElement] = []
                val.variations.forEach { variation in
                    switch variation.type {
                    case let .flickVariation(direction):
                        let v = UnifiedVariation(label: variation.key.design.label.keyLabelType, pressActions: variation.key.press_actions.map { $0.actionType }, longPressActions: variation.key.longpress_actions.longpressActionType)
                        flickMap[direction] = v
                    case .longpressVariation:
                        linear.append(.init(label: variation.key.design.label.keyLabelType, actions: variation.key.press_actions.map { $0.actionType }))
                    }
                }
                let colorRole: UnifiedGeneralKeyModel<Extension>.ColorRole = switch val.design.color {
                case .normal: .normal
                case .special: .special
                case .selected: .selected
                case .unimportant: .unimportant
                }
                let needSuggest = switch self.keyStyle {
                case .tenkeyStyle: false
                case .pcStyle: val.longpress_actions.isEmpty
                }
                let model = UnifiedGeneralKeyModel<Extension>(
                    labelType: val.design.label.keyLabelType,
                    pressActions: val.press_actions.map { $0.actionType },
                    longPressActions: val.longpress_actions.longpressActionType,
                    flick: flickMap,
                    linearVariations: linear,
                    linearDirection: .center,
                    showsTapBubble: needSuggest,
                    colorRole: colorRole
                )
                models.append((pos, model))
            }
        }
    }
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

extension CodableLongpressActionData {
    var isEmpty: Bool {
        self.start.isEmpty && self.repeat.isEmpty
    }
}

extension CustardInterfaceKey {
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
        case .gridFit:
            let unifiedModels = custard.interface.unifiedKeyModels(extension: Extension.self)
            UnifiedKeysView(models: unifiedModels, tabDesign: tabDesign) { keyView, _ in keyView }
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
