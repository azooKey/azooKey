//
//  MainAppDesign.swift
//  azooKey
//
//  Created by ensan on 2023/03/14.
//  Copyright © 2023 ensan. All rights reserved.
//

import class UIKit.UIDevice
import enum UIKit.UIDeviceOrientation
import enum KeyboardViews.KeyboardOrientation

enum MainAppDesign {
    static let imageMaximumWidth: Double = 500

    @MainActor static var keyboardOrientation: KeyboardOrientation {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .vertical
        } else {
            return UIDevice.current.orientation == UIDeviceOrientation.unknown ? .vertical : (UIDevice.current.orientation == UIDeviceOrientation.portrait ? .vertical : .horizontal)
        }
    }
}
