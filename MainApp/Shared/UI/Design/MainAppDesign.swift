//
//  MainAppDesign.swift
//  azooKey
//
//  Created by ensan on 2023/03/14.
//  Copyright © 2023 ensan. All rights reserved.
//

import CoreGraphics
import struct KeyboardViews.KeyboardLayoutContext
import enum KeyboardViews.KeyboardLayoutIdiom
import enum KeyboardViews.KeyboardOrientation
import class UIKit.UIApplication
import class UIKit.UIDevice
import enum UIKit.UIDeviceOrientation
import class UIKit.UIWindowScene

enum MainAppDesign {
    static let imageMaximumWidth: Double = 500

    @MainActor static var keyboardOrientation: KeyboardOrientation {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .vertical
        }
        if let orientation = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })?
            .interfaceOrientation {
            if orientation.isPortrait {
                return .vertical
            }
            if orientation.isLandscape {
                return .horizontal
            }
        }
        switch UIDevice.current.orientation {
        case .landscapeLeft, .landscapeRight:
            return .horizontal
        case .portrait, .portraitUpsideDown, .faceUp, .faceDown, .unknown:
            return .vertical
        @unknown default:
            return .vertical
        }
    }

    @MainActor
    static func keyboardLayoutContext(containerWidth: CGFloat) -> KeyboardLayoutContext {
        KeyboardLayoutContext(
            containerWidth: containerWidth,
            orientation: keyboardOrientation,
            idiom: .current
        )
    }
}
