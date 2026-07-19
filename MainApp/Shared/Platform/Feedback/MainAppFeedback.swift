//
//  MainAppFeedback.swift
//  azooKey
//
//  Created by ensan on 2023/03/14.
//  Copyright © 2023 ensan. All rights reserved.
//

import class UIKit.UINotificationFeedbackGenerator

@MainActor enum MainAppFeedback {
    private static let feedbackGenerator = UINotificationFeedbackGenerator()
    static func success() {
        feedbackGenerator.notificationOccurred(.success)
    }
}
