//
//  ApplicationSpecificTheme.swift
//
//
//  Created by ensan on 2023/07/20.
//

import Foundation
import SwiftUI

public protocol ApplicationSpecificTheme {
    associatedtype ApplicationColor: ApplicationSpecificColor
}

public protocol ApplicationSpecificColor: Codable, Equatable, Sendable {
    var color: Color { get }
}
