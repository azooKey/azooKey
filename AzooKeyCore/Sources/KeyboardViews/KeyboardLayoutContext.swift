import UIKit

public enum KeyboardLayoutIdiom: Equatable, Sendable {
    case phone
    case pad

    @MainActor
    public static var current: Self {
        UIDevice.current.userInterfaceIdiom == .pad ? .pad : .phone
    }
}

public struct KeyboardLayoutContext: Sendable {
    public var containerWidth: CGFloat
    public var orientation: KeyboardOrientation
    public var idiom: KeyboardLayoutIdiom
    public var duoFlickEnabled: Bool
    public var allowsDuoFlickPanels: Bool

    public var usesSplitFlick: Bool {
        duoFlickEnabled && allowsDuoFlickPanels && containerWidth >= DuoFlickLayout.minimumContainerWidth
    }

    public var resolvedSizeCacheIdentifier: String {
        guard duoFlickEnabled else {
            return "standard"
        }
        return usesSplitFlick ? "duo-split-v1" : "duo-compact-v1"
    }

    public init(
        containerWidth: CGFloat,
        orientation: KeyboardOrientation,
        idiom: KeyboardLayoutIdiom,
        duoFlickEnabled: Bool = false,
        allowsDuoFlickPanels: Bool = true
    ) {
        self.containerWidth = containerWidth
        self.orientation = orientation
        self.idiom = idiom
        self.duoFlickEnabled = duoFlickEnabled
        self.allowsDuoFlickPanels = allowsDuoFlickPanels
    }
}
