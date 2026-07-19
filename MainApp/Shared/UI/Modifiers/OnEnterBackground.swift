//
//  OnEnterBackground.swift
//  MainApp
//
//  Created by ensan on 2021/04/22.
//  Copyright © 2021 ensan. All rights reserved.
//

import Foundation
import SwiftUI

extension View {
    @inlinable nonisolated func onEnterBackground(perform action: @escaping (NotificationCenter.Publisher.Output) -> Void ) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification), perform: action)
    }

    @inlinable nonisolated func onEnterForeground(perform action: @escaping (NotificationCenter.Publisher.Output) -> Void ) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification), perform: action)
    }
}
