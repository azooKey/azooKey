//
//  checkKeyboardActivation.swift
//  azooKey
//
//  Created by ensan on 2023/03/14.
//  Copyright © 2023 ensan. All rights reserved.
//

import Foundation
import class UIKit.UITextInputMode
import enum AzooKeyUtils.SharedStore

extension SharedStore {
    @MainActor static func checkKeyboardActivation() -> Bool {
        let keyboards = UITextInputMode.activeInputModes.compactMap {$0.value(forKey: "identifier") as? String}
        return keyboards.contains { $0.hasPrefix(SharedStore.bundleName) }
    }
}
