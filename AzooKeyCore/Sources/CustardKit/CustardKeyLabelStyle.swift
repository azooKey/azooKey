/// - キーに指定するラベル
/// - labels on the key
public enum CustardKeyLabelStyle: Codable, Equatable, Hashable, Sendable {
    case text(String)
    case systemImage(String)
    case mainAndSub(String, String)
    case mainAndDirections(String, CustardKeyDirectionalLabel)
}

public struct CustardKeyDirectionalLabel: Codable, Equatable, Hashable, Sendable {
    public init(left: String? = nil, top: String? = nil, right: String? = nil, bottom: String? = nil) {
        self.left = left
        self.top = top
        self.right = right
        self.bottom = bottom
    }

    public var left: String?
    public var top: String?
    public var right: String?
    public var bottom: String?
}

public extension CustardKeyLabelStyle {
    private enum CodingKeys: CodingKey {
        case text
        case system_image
        case type
        case main
        case sub
        case directions
    }

    private enum ValueType: String, Codable {
        case text
        case system_image
        case main_and_sub
        case main_and_directions
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .text(value):
            try container.encode(value, forKey: .text)
        case let .systemImage(value):
            try container.encode(value, forKey: .system_image)
        case let .mainAndSub(main, sub):
            try container.encode(ValueType.main_and_sub, forKey: .type)
            try container.encode(main, forKey: .main)
            try container.encode(sub, forKey: .sub)
        case let .mainAndDirections(main, directions):
            try container.encode(ValueType.main_and_directions, forKey: .type)
            try container.encode(main, forKey: .main)
            try container.encode(directions, forKey: .directions)
        }
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // "type"が見つかった場合
        if let type = try? container.decode(ValueType.self, forKey: .type) {
            switch type {
            case .text:
                let value = try container.decode(
                    String.self,
                    forKey: .text
                )
                self = .text(value)
            case .system_image:
                let value = try container.decode(
                    String.self,
                    forKey: .system_image
                )
                self = .systemImage(value)
            case .main_and_sub:
                let main = try container.decode(
                    String.self,
                    forKey: .main
                )
                let sub = try container.decode(
                    String.self,
                    forKey: .sub
                )
                self = .mainAndSub(main, sub)
            case .main_and_directions:
                let main = try container.decode(
                    String.self,
                    forKey: .main
                )
                let directions = try container.decode(
                    CustardKeyDirectionalLabel.self,
                    forKey: .directions
                )
                self = .mainAndDirections(main, directions)
            }
            return
        }

        // それ以外の場合(old cases)
        guard container.allKeys.count == 1, let key = container.allKeys.first else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Unabled to decode CustardKeyLabelStyle."
                )
            )
        }
        switch key {
        case .text:
            let value = try container.decode(
                String.self,
                forKey: .text
            )
            self = .text(value)
        case .system_image:
            let value = try container.decode(
                String.self,
                forKey: .system_image
            )
            self = .systemImage(value)
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Unabled to decode CustardKeyLabelStyle."
                )
            )
        }
    }
}
