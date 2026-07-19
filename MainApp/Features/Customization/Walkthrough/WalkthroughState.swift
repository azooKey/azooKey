//
//  WalkthroughState.swift
//  azooKey
//
//  Created by ensan on 2021/03/21.
//  Copyright © 2021 ensan. All rights reserved.
//

import Foundation
import SwiftUI
import SwiftUIUtils

struct WalkthroughInformation: Codable, StaticInitialValueAvailable {
    static let initialValue = Self()

    var walkthroughs: [Walkthrough: WalkthroughState] = [:]

    enum Walkthrough: String, Codable {
        case extensions
    }

    func shouldDisplay(identifier: Walkthrough) -> Bool {
        let upToDate = walkthroughs[identifier]?.lastDisplayedVersion?.isUpToDate ?? false
        return !upToDate
    }

    mutating func done(identifier: Walkthrough) {
        walkthroughs[identifier, default: .init()].lastDisplayedVersion = .upToDate
    }
}

struct WalkthroughState: Codable {
    // 最後の状態がOneHandedModeだったかどうか
    fileprivate var lastDisplayedVersion: VersionIdentifier?
}

private enum VersionIdentifier: String, Codable {
    case v1_6

    static let upToDate: Self = .v1_6
    // もっとも新しいバージョンか否か
    var isUpToDate: Bool {
        self == Self.upToDate
    }
}
