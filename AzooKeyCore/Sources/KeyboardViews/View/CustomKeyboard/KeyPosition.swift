//
//  KeyPosition.swift
//  azooKey
//
//  Created by ensan on 2021/04/24.
//  Copyright © 2021 ensan. All rights reserved.
//

import Foundation
public enum KeyPosition: Hashable, Codable, Sendable {
    case gridFit(x: Double, y: Double)
    case gridScroll(index: Int)

    private enum CodingKeys: CodingKey {
        case type, x, y, index
    }
    private enum ValueType: String, Codable {
        case gridFit, gridScroll
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .gridFit(x: x, y: y):
            try container.encode(ValueType.gridFit, forKey: .type)
            try container.encode(x, forKey: .x)
            try container.encode(y, forKey: .y)
        case let .gridScroll(index: index):
            try container.encode(ValueType.gridScroll, forKey: .type)
            try container.encode(index, forKey: .index)
        }
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ValueType.self, forKey: .type)
        switch type {
        case .gridFit:
            self = .gridFit(
                x: try container.decode(Double.self, forKey: .x),
                y: try container.decode(Double.self, forKey: .y)
            )
        case .gridScroll:
            self = .gridScroll(
                index: try container.decode(Int.self, forKey: .index)
            )
        }
    }
}

public extension KeyPosition {
    static func gridFit(x: Int, y: Int) -> Self {
        .gridFit(x: Double(x), y: Double(y))
    }
}
