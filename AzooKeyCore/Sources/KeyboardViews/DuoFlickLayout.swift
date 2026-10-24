import Foundation
import SwiftUIUtils

/// Device-independent geometry: the keyboard follows its actual container,
/// including folding, rotation, and multitasking, rather than a model name.
public struct DuoFlickLayout: Equatable, Sendable {
    public static let minimumContainerWidth: CGFloat = 600
    public static let keyboardHeight: CGFloat = 270
    static let keySpacing: CGFloat = 8

    public let panelWidth: CGFloat
    public let centerGap: CGFloat
    public let edgeInset: CGFloat

    public init?(containerWidth: CGFloat, preferredPanelWidth: Double, minimumCenterGap: Double) {
        guard containerWidth.isFinite, containerWidth >= Self.minimumContainerWidth else {
            return nil
        }
        edgeInset = 7
        let availableWidth = containerWidth - edgeInset * 2
        // Zero means automatic: use the full half-screen rather than leaving
        // unused space when the unfolded display is wider than a phone.
        let preferredWidth = preferredPanelWidth.isFinite && preferredPanelWidth > 0
            ? min(700, max(250, preferredPanelWidth))
            : availableWidth / 2
        let requestedGap = minimumCenterGap.isFinite ? min(240, max(0, minimumCenterGap)) : 16
        let gap = min(requestedGap, availableWidth - 500)
        panelWidth = min(preferredWidth, (availableWidth - gap) / 2)
        centerGap = availableWidth - panelWidth * 2
    }

    /// Coordinates are local to the key grid, not to the display or window.
    public func panelFrames(keyAreaHeight: CGFloat, avoiding obstacles: [CGRect]) -> [CGRect] {
        guard keyAreaHeight.isFinite, keyAreaHeight > 0 else {
            return []
        }
        let width = panelWidth * 2 + centerGap + edgeInset * 2
        let left = CGRect(x: edgeInset, y: 0, width: panelWidth, height: keyAreaHeight)
        let right = CGRect(x: width - edgeInset - panelWidth, y: 0, width: panelWidth, height: keyAreaHeight)
        let frames = [left, right].map { AvailableLayoutRegion.largest(in: $0, avoiding: obstacles) }
        if frames.allSatisfy({ $0.width >= 250 && $0.height >= min(200, keyAreaHeight) }) {
            return frames
        }
        // Both panels offer the same actions. Preserve a complete single panel
        // rather than squeezing two unusable panels around an obstruction.
        let usable = AvailableLayoutRegion.largest(
            in: CGRect(x: edgeInset, y: 0, width: width - edgeInset * 2, height: keyAreaHeight),
            avoiding: obstacles
        )
        return usable.isEmpty ? [] : [usable]
    }
}
