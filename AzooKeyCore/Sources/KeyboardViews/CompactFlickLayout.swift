import Foundation

/// Single-panel metrics for a narrow or vertically compact presentation.
/// The host keyboard already supplies the screen's outside safe-area inset.
public enum CompactFlickLayout {
    public static let maximumPortraitHeight: CGFloat = 270
    public static let maximumLandscapeHeight: CGFloat = 200

    public static func keyboardHeight(containerWidth: CGFloat, orientation: KeyboardOrientation) -> CGFloat {
        let width = containerWidth.isFinite ? max(0, containerWidth) : 0
        switch orientation {
        case .vertical:
            return min(maximumPortraitHeight, 51 / 74 * width + 12)
        case .horizontal:
            return min(maximumLandscapeHeight, 17 / 56 * width + 12)
        }
    }

    static func keySpacing(orientation: KeyboardOrientation) -> CGFloat {
        orientation == .vertical ? 7 : 6
    }

    static func barHeight(orientation: KeyboardOrientation) -> CGFloat {
        orientation == .vertical ? 36 : 32
    }
}
