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

    public init(
        containerWidth: CGFloat,
        orientation: KeyboardOrientation,
        idiom: KeyboardLayoutIdiom
    ) {
        self.containerWidth = containerWidth
        self.orientation = orientation
        self.idiom = idiom
    }
}
