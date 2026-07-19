import AzooKeyUtils
import CustardKit
import Foundation
import KeyboardViews
import SwiftUI

enum CustardInterfaceKeyEditingService {
    static func inputText(in actions: [CodableActionData]) -> String? {
        actions.compactMap { action in
            switch action {
            case let .input(text), let .directInput(text):
                text
            default:
                nil
            }
        }.first
    }

    static func usesDirectInput(_ actions: [CodableActionData]) -> Bool {
        if case .directInput = actions.first {
            return true
        }
        return false
    }

    static func isInputActionEditable(_ actions: [CodableActionData]) -> Bool {
        if actions.isEmpty {
            return true
        }
        if actions.count == 1 {
            switch actions.first {
            case .input, .directInput:
                return true
            default:
                break
            }
        }
        return false
    }

    static func initialLabelType(
        for key: CustardInterfaceCustomKey,
        position: FlickKeyPosition
    ) -> CustardKeyLabelType? {
        initialLabelType(
            pressActions: key[.pressAction, position],
            keyLabel: key[.label, position]
        )
    }

    static func initialLabelType(
        pressActions: [CodableActionData],
        keyLabel: CustardKeyLabelStyle
    ) -> CustardKeyLabelType? {
        switch keyLabel {
        case let .text(string):
            if inputText(in: pressActions) == string {
                return nil
            }
            return .text
        case .systemImage:
            return .systemImage
        case .mainAndSub:
            return .mainAndSub
        case .mainAndDirections:
            return .mainAndDirections
        }
    }

    static func initialLabelSelection(
        for variation: CustardInterfaceVariationKey
    ) -> CustardKeyLabelSelection {
        switch variation.design.label {
        case let .text(text):
            if inputText(in: variation.press_actions) == text {
                return .auto
            }
            return .text
        case .systemImage:
            return .systemImage
        case .mainAndSub:
            return .mainAndSub
        case .mainAndDirections:
            return .mainAndDirections
        }
    }
}

extension CustardInterfaceKey {
    enum SystemKey {
        case system
    }

    enum CustomKey {
        case custom
    }

    subscript(key: CustomKey) -> CustardInterfaceCustomKey {
        get {
            if case let .custom(value) = self {
                return value
            }
            return .init(
                design: .init(label: .text(""), color: .normal),
                press_actions: [],
                longpress_actions: .none,
                variations: []
            )
        }
        set {
            self = .custom(newValue)
        }
    }

    subscript(key: SystemKey) -> CustardInterfaceSystemKey {
        get {
            if case let .system(value) = self {
                return value
            }
            return .enter
        }
        set {
            self = .system(newValue)
        }
    }
}

extension FlickKeyPosition {
    var flickDirection: FlickDirection? {
        switch self {
        case .left: .left
        case .top: .top
        case .right: .right
        case .bottom: .bottom
        case .center: nil
        }
    }
}

extension CustardInterfaceCustomKey {
    enum LabelKey {
        case label
    }

    enum LabelTextKey {
        case labelText
    }

    enum LabelImageNameKey {
        case labelImageName
    }

    enum LabelTypeKey {
        case labelType
    }

    enum LabelMainKey {
        case labelMain
    }

    enum LabelSubKey {
        case labelSub
    }

    enum LabelDirectionsKey {
        case labelDirections
    }

    enum PressActionKey {
        case pressAction
    }

    enum InputActionKey {
        case inputAction
    }

    enum LongpressActionKey {
        case longpressAction
    }

    subscript(direction: FlickDirection) -> CustardInterfaceVariationKey {
        get {
            if let variation = variations.first(where: { $0.type == .flickVariation(direction) })?.key {
                return variation
            }
            return .init(
                design: .init(label: .text("")),
                press_actions: [.input("")],
                longpress_actions: .none
            )
        }
        set {
            if let index = variations.firstIndex(where: { $0.type == .flickVariation(direction) }) {
                variations[index].key = newValue
            } else {
                variations.append(.init(type: .flickVariation(direction), key: newValue))
            }
        }
    }

    subscript(label: LabelKey, position: FlickKeyPosition) -> CustardKeyLabelStyle {
        get {
            if let direction = position.flickDirection {
                return self[direction].design.label
            }
            return design.label
        }
        set {
            if let direction = position.flickDirection {
                self[direction].design.label = newValue
            } else {
                design.label = newValue
            }
        }
    }

    subscript(label: LabelTextKey, position: FlickKeyPosition) -> String {
        get {
            if let direction = position.flickDirection {
                return self[direction][.labelText]
            }
            if case let .text(value) = design.label {
                return value
            }
            return ""
        }
        set {
            if let direction = position.flickDirection {
                self[direction][.labelText] = newValue
            } else {
                design.label = .text(newValue)
            }
        }
    }

    subscript(label: LabelImageNameKey, position: FlickKeyPosition) -> String {
        get {
            if let direction = position.flickDirection {
                return self[direction][.labelImageName]
            }
            if case let .systemImage(value) = design.label {
                return value
            }
            return ""
        }
        set {
            if let direction = position.flickDirection {
                self[direction][.labelImageName] = newValue
            } else {
                design.label = .systemImage(newValue)
            }
        }
    }

    subscript(label: LabelMainKey, position: FlickKeyPosition) -> String {
        get {
            if let direction = position.flickDirection {
                return self[direction][.labelMain]
            }
            switch design.label {
            case let .mainAndSub(value, _), let .mainAndDirections(value, _), let .text(value):
                return value
            case .systemImage:
                return ""
            }
        }
        set {
            if let direction = position.flickDirection {
                self[direction][.labelMain] = newValue
            } else {
                switch design.label {
                case let .mainAndSub(_, sub):
                    design.label = .mainAndSub(newValue, sub)
                case let .mainAndDirections(_, directions):
                    design.label = .mainAndDirections(newValue, directions)
                default:
                    design.label = .text(newValue)
                }
            }
        }
    }

    subscript(label: LabelSubKey, position: FlickKeyPosition) -> String {
        get {
            if let direction = position.flickDirection {
                return self[direction][.labelSub]
            }
            if case let .mainAndSub(_, value) = design.label {
                return value
            }
            return ""
        }
        set {
            if let direction = position.flickDirection {
                self[direction][.labelSub] = newValue
            } else if case let .mainAndSub(main, _) = design.label {
                design.label = .mainAndSub(main, newValue)
            } else {
                design.label = .mainAndSub("", newValue)
            }
        }
    }

    subscript(label: LabelDirectionsKey, position: FlickKeyPosition) -> CustardKeyDirectionalLabel {
        get {
            if let direction = position.flickDirection {
                return self[direction][.labelDirections]
            }
            if case let .mainAndDirections(_, value) = design.label {
                return value
            }
            return CustardKeyDirectionalLabel()
        }
        set {
            if let direction = position.flickDirection {
                self[direction][.labelDirections] = newValue
            } else {
                design.label = .mainAndDirections(self[.labelMain, position], newValue)
            }
        }
    }

    subscript(label: LabelTypeKey, position: FlickKeyPosition) -> CustardKeyLabelType {
        get {
            if let direction = position.flickDirection {
                return self[direction][.labelType]
            }
            switch design.label {
            case .systemImage: return .systemImage
            case .text: return .text
            case .mainAndSub: return .mainAndSub
            case .mainAndDirections: return .mainAndDirections
            }
        }
        set {
            if let direction = position.flickDirection {
                self[direction][.labelType] = newValue
            } else {
                switch newValue {
                case .text:
                    design.label = .text("")
                case .systemImage:
                    design.label = .systemImage("circle.fill")
                case .mainAndSub:
                    design.label = .mainAndSub("A", "BC")
                case .mainAndDirections:
                    design.label = .mainAndDirections("", .init())
                }
            }
        }
    }

    subscript(action: PressActionKey, position: FlickKeyPosition) -> [CodableActionData] {
        get {
            if let direction = position.flickDirection {
                return self[direction][.pressAction]
            }
            return press_actions
        }
        set {
            if let direction = position.flickDirection {
                self[direction][.pressAction] = newValue
            } else {
                press_actions = newValue
            }
        }
    }

    subscript(inputAction: InputActionKey, position: FlickKeyPosition) -> String {
        get {
            if let direction = position.flickDirection {
                return self[direction][.inputAction]
            }
            switch press_actions.first {
            case let .input(value), let .directInput(value):
                return value
            default:
                return ""
            }
        }
        set {
            if let direction = position.flickDirection {
                self[direction][.inputAction] = newValue
            } else if CustardInterfaceKeyEditingService.usesDirectInput(press_actions) {
                press_actions = [.directInput(newValue)]
            } else {
                press_actions = [.input(newValue)]
            }
        }
    }

    subscript(action: LongpressActionKey, position: FlickKeyPosition) -> CodableLongpressActionData {
        get {
            if let direction = position.flickDirection {
                return self[direction][.longpressAction]
            }
            return longpress_actions
        }
        set {
            if let direction = position.flickDirection {
                self[direction][.longpressAction] = newValue
            } else {
                longpress_actions = newValue
            }
        }
    }

    func longpressKeys() -> [CustardInterfaceVariationKey] {
        variations.compactMap { variation in
            if case .longpressVariation = variation.type {
                return variation.key
            }
            return nil
        }
    }

    mutating func setLongpressKeys(_ keys: [CustardInterfaceVariationKey]) {
        let flickVariations = variations.filter {
            if case .flickVariation = $0.type {
                return true
            }
            return false
        }
        variations = flickVariations + keys.map {
            .init(type: .longpressVariation, key: $0)
        }
    }

    mutating func appendLongpressVariation() {
        var keys = longpressKeys()
        keys.append(
            .init(
                design: .init(label: .text("")),
                press_actions: [.input("")],
                longpress_actions: .none
            )
        )
        setLongpressKeys(keys)
    }

    mutating func removeLongpress(at index: Int) {
        var keys = longpressKeys()
        guard keys.indices.contains(index) else {
            return
        }
        keys.remove(at: index)
        setLongpressKeys(keys)
    }
}

extension CustardInterfaceVariationKey {
    enum LabelTextKey {
        case labelText
    }

    enum PressActionKey {
        case pressAction
    }

    enum InputActionKey {
        case inputAction
    }

    enum LongpressActionKey {
        case longpressAction
    }

    enum LabelImageNameKey {
        case labelImageName
    }

    enum LabelTypeKey {
        case labelType
    }

    enum LabelMainKey {
        case labelMain
    }

    enum LabelSubKey {
        case labelSub
    }

    enum LabelDirectionsKey {
        case labelDirections
    }

    subscript(label: LabelTextKey) -> String {
        get {
            if case let .text(value) = design.label {
                return value
            }
            return ""
        }
        set {
            design.label = .text(newValue)
        }
    }

    subscript(label: LabelImageNameKey) -> String {
        get {
            if case let .systemImage(value) = design.label {
                return value
            }
            return ""
        }
        set {
            design.label = .systemImage(newValue)
        }
    }

    subscript(label: LabelMainKey) -> String {
        get {
            switch design.label {
            case let .mainAndSub(value, _), let .mainAndDirections(value, _), let .text(value):
                return value
            case .systemImage:
                return ""
            }
        }
        set {
            switch design.label {
            case let .mainAndSub(_, sub):
                design.label = .mainAndSub(newValue, sub)
            case let .mainAndDirections(_, directions):
                design.label = .mainAndDirections(newValue, directions)
            default:
                design.label = .text(newValue)
            }
        }
    }

    subscript(label: LabelSubKey) -> String {
        get {
            if case let .mainAndSub(_, value) = design.label {
                return value
            }
            return ""
        }
        set {
            if case let .mainAndSub(main, _) = design.label {
                design.label = .mainAndSub(main, newValue)
            } else {
                design.label = .mainAndSub("", newValue)
            }
        }
    }

    subscript(label: LabelDirectionsKey) -> CustardKeyDirectionalLabel {
        get {
            if case let .mainAndDirections(_, directions) = design.label {
                return directions
            }
            return CustardKeyDirectionalLabel()
        }
        set {
            design.label = .mainAndDirections(self[.labelMain], newValue)
        }
    }

    subscript(label: LabelTypeKey) -> CustardKeyLabelType {
        get {
            switch design.label {
            case .systemImage: return .systemImage
            case .text: return .text
            case .mainAndSub: return .mainAndSub
            case .mainAndDirections: return .mainAndDirections
            }
        }
        set {
            switch newValue {
            case .text:
                design.label = .text("")
            case .systemImage:
                design.label = .systemImage("circle.fill")
            case .mainAndSub:
                design.label = .mainAndSub("A", "BC")
            case .mainAndDirections:
                design.label = .mainAndDirections("", .init())
            }
        }
    }

    subscript(pressAction: PressActionKey) -> [CodableActionData] {
        get {
            press_actions
        }
        set {
            press_actions = newValue
        }
    }

    subscript(inputAction: InputActionKey) -> String {
        get {
            switch press_actions.first {
            case let .input(value), let .directInput(value):
                return value
            default:
                return ""
            }
        }
        set {
            if CustardInterfaceKeyEditingService.usesDirectInput(press_actions) {
                press_actions = [.directInput(newValue)]
            } else {
                press_actions = [.input(newValue)]
            }
        }
    }

    subscript(longpressAction: LongpressActionKey) -> CodableLongpressActionData {
        get {
            longpress_actions
        }
        set {
            longpress_actions = newValue
        }
    }
}
