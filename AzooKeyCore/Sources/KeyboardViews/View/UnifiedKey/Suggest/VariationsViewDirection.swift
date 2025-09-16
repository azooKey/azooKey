import Foundation
import SwiftUI

public enum VariationsViewDirection: Sendable, Equatable {
    case center, right, left

    var alignment: Alignment {
        switch self {
        case .center: return .center
        case .right: return .leading
        case .left: return .trailing
        }
    }

    var edge: Edge.Set {
        switch self {
        case .center: return []
        case .right: return .leading
        case .left: return .trailing
        }
    }
}
