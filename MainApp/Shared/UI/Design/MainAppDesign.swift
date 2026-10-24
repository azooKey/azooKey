//
//  MainAppDesign.swift
//  azooKey
//
//  Created by ensan on 2023/03/14.
//  Copyright © 2023 ensan. All rights reserved.
//

// Container geometry belongs to each view, not to a device model or a global screen.
import CoreGraphics
import struct KeyboardViews.KeyboardLayoutContext
import enum KeyboardViews.KeyboardOrientation

enum MainAppDesign {
    static let imageMaximumWidth: Double = 500

    @MainActor
    static func keyboardLayoutContext(
        containerWidth: CGFloat,
        orientation: KeyboardOrientation = .vertical
    ) -> KeyboardLayoutContext {
        KeyboardLayoutContext(containerWidth: containerWidth, orientation: orientation, idiom: .current)
    }
}
