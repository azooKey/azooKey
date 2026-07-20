import Foundation

/// - variation of key, includes flick keys and selectable variations in pc style keyboard.
public struct CustardInterfaceVariation: Codable, Equatable, Hashable, Sendable {
    public init(type: VariationType, key: CustardInterfaceVariationKey) {
        self.type = type
        self.key = key
    }

    /// - type of the variation
    public var type: VariationType

    /// - data of variation
    public var key: CustardInterfaceVariationKey

    /// - キーの変種の種類
    /// - type of key variation
    public enum VariationType: Equatable, Hashable, Sendable {
        /// - variation of flick
        /// - warning: when you use pc style, this type of variation would be ignored.
        case flickVariation(FlickDirection)

        /// - variation selectable when keys were longoressed, especially used in pc style keyboard.
        /// - warning: when you use flick key style, this type of variation would be ignored.
        case longpressVariation
    }
}

public extension CustardInterfaceVariation {
    private enum CodingKeys: CodingKey {
        case type
        case direction
        case key
    }

    private enum ValueType: String, Codable {
        case flick_variation
        case longpress_variation
    }

    private var valueType: ValueType {
        switch self.type {
        case .flickVariation: return .flick_variation
        case .longpressVariation: return .longpress_variation
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.key, forKey: .key)
        try container.encode(self.valueType, forKey: .type)
        switch self.type {
        case let .flickVariation(value):
            try container.encode(value, forKey: .direction)
        case .longpressVariation:
            break
        }
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.key = try container.decode(CustardInterfaceVariationKey.self, forKey: .key)
        let valueType = try container.decode(ValueType.self, forKey: .type)
        switch valueType {
        case .flick_variation:
            let direction = try container.decode(FlickDirection.self, forKey: .direction)
            self.type = .flickVariation(direction)
        case .longpress_variation:
            self.type = .longpressVariation
        }
    }
}

/// - data of variation key
public struct CustardInterfaceVariationKey: Codable, Equatable, Hashable, Sendable {
    public init(design: CustardVariationKeyDesign, press_actions: [CodableActionData], longpress_actions: CodableLongpressActionData) {
        self.design = design
        self.press_actions = press_actions
        self.longpress_actions = longpress_actions
    }

    /// - label on this variation
    public var design: CustardVariationKeyDesign

    /// - actions done when you select this variation. actions are done in order..
    public var press_actions: [CodableActionData]

    /// - actions done when you 'long select' this variation, like long-flick. actions are done in order.
    public var longpress_actions: CodableLongpressActionData
}
