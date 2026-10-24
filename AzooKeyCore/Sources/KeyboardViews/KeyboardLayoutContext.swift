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

    public init(
        containerWidth: CGFloat,
        orientation: KeyboardOrientation,
        idiom: KeyboardLayoutIdiom,
        duoFlickEnabled: Bool = false
    ) {
        self.containerWidth = containerWidth
        self.orientation = orientation
        self.idiom = idiom
        self.duoFlickEnabled = duoFlickEnabled
    }
}
