import UIKit

/// The input window can be only as tall as the keyboard. Its aspect ratio and
/// local size class therefore cannot identify the host screen's orientation.
public struct KeyboardPresentation: Equatable, Sendable {
    public let orientation: KeyboardOrientation

    public init(sceneSize: CGSize, interfaceOrientation: UIInterfaceOrientation, fallbackOrientation: KeyboardOrientation = .vertical) {
        if interfaceOrientation.isPortrait {
            orientation = .vertical
        } else if interfaceOrientation.isLandscape {
            orientation = .horizontal
        } else if sceneSize.width.isFinite, sceneSize.height.isFinite, sceneSize.width > 0, sceneSize.height > 0 {
            orientation = sceneSize.width > sceneSize.height ? .horizontal : .vertical
        } else {
            orientation = fallbackOrientation
        }
    }
}
