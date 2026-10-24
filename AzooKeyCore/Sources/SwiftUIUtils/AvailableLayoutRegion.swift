import Foundation
import SwiftUI

/// Finds a rectangular interaction area without crossing an active fold or
/// occlusion. Reserved-region frames already contain the system's margins.
public enum AvailableLayoutRegion {
    public static func largest(in bounds: CGRect, avoiding obstacles: [CGRect]) -> CGRect {
        guard isUsable(bounds) else {
            return .zero
        }
        var candidates = [bounds]
        for obstacle in obstacles where isUsable(obstacle) {
            candidates = candidates.flatMap { rect -> [CGRect] in
                let overlap = rect.intersection(obstacle)
                guard isUsable(overlap) else {
                    return [rect]
                }
                return [
                    CGRect(x: rect.minX, y: rect.minY, width: overlap.minX - rect.minX, height: rect.height),
                    CGRect(x: overlap.maxX, y: rect.minY, width: rect.maxX - overlap.maxX, height: rect.height),
                    CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: overlap.minY - rect.minY),
                    CGRect(x: rect.minX, y: overlap.maxY, width: rect.width, height: rect.maxY - overlap.maxY),
                ].filter(isUsable)
            }
            // Remove duplicates and contained candidates to bound the search.
            candidates = candidates.enumerated().filter { index, rect in
                !candidates.enumerated().contains { otherIndex, other in
                    otherIndex != index && other.contains(rect) && (other != rect || otherIndex < index)
                }
            }.map(\.element)
        }
        return candidates.sorted {
            if $0.width * $0.height != $1.width * $1.height {
                return $0.width * $0.height > $1.width * $1.height
            }
            if $0.minY != $1.minY {
                return $0.minY < $1.minY
            }
            return $0.minX < $1.minX
        }.first ?? .zero
    }

    private static func isUsable(_ rect: CGRect) -> Bool {
        !rect.isNull && !rect.isInfinite && rect.origin.x.isFinite && rect.origin.y.isFinite
            && rect.width.isFinite && rect.height.isFinite
            && rect.width > 0 && rect.height > 0
    }

    @MainActor
    public static func obstacles(in geometry: GeometryProxy) -> [CGRect] {
        // Xcode 27.1 SDK APIs must also be hidden from older SDK builds.
        #if os(iOS) && compiler(>=6.4) && canImport(SwiftUI, _version: 8.0.85.29)
        if #available(iOS 27.1, *) {
            // Use physical local coordinates, including for right-to-left UI.
            return geometry.reservedRegions(kind: .division, layoutDirectionBehavior: .fixed).map(\.frame)
                + geometry.reservedRegions(kind: .occlusion, layoutDirectionBehavior: .fixed).map(\.frame)
        }
        #endif
        return []
    }
}

/// For a single row of custom controls. Scrolling inside the content preserves
/// access to all actions when the usable rectangle becomes narrower.
public struct ReservedRegionAvoidingContent<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        GeometryReader { geometry in
            let frame = AvailableLayoutRegion.largest(
                in: CGRect(origin: .zero, size: geometry.size),
                avoiding: AvailableLayoutRegion.obstacles(in: geometry)
            )
            content
                .frame(width: frame.width, height: frame.height)
                .clipped()
                .allowsHitTesting(!frame.isEmpty)
                .accessibilityHidden(frame.isEmpty)
                .position(x: frame.midX, y: frame.midY)
        }
    }
}
