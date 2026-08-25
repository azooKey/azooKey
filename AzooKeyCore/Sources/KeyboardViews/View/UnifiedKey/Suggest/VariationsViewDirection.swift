import Foundation
import SwiftUI

public enum VariationsViewDirection: Sendable, Equatable {
    case center, right, left

    static func automatic(
        position: UnifiedPositionSpecifier,
        variationCount: Int,
        horizontalKeyCount: CGFloat
    ) -> Self {
        guard variationCount > 1, horizontalKeyCount > 0 else {
            return .center
        }

        let variationWidth = CGFloat(variationCount)
        let keyLeading = position.x
        let keyTrailing = position.x + position.width
        let keyCenter = (keyLeading + keyTrailing) / 2

        func overflow(leading: CGFloat, trailing: CGFloat) -> CGFloat {
            max(0, -leading) + max(0, trailing - horizontalKeyCount)
        }

        let centerOverflow = overflow(
            leading: keyCenter - variationWidth / 2,
            trailing: keyCenter + variationWidth / 2
        )
        guard centerOverflow > 0 else {
            return .center
        }

        let rightOverflow = overflow(
            leading: keyLeading,
            trailing: keyLeading + variationWidth
        )
        let leftOverflow = overflow(
            leading: keyTrailing - variationWidth,
            trailing: keyTrailing
        )

        if centerOverflow <= min(rightOverflow, leftOverflow) {
            return .center
        }
        if rightOverflow == leftOverflow {
            return keyCenter <= horizontalKeyCount / 2 ? .right : .left
        }
        return rightOverflow < leftOverflow ? .right : .left
    }

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
