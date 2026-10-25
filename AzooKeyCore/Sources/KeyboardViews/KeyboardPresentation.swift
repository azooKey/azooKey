import UIKit

/// キーボードのウィンドウは高さが低いので、その縦横比だけでは画面の向きが分かりません。
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
