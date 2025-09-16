//
//  AppVersion.swift
//  azooKey
//
//  Created by ensan on 2022/07/02.
//  Copyright © 2022 ensan. All rights reserved.
//

import Foundation

/// AppVersion is a struct that represents a version of an app.
/// It is a wrapper of String that conforms to Codable, Equatable, Comparable, Hashable, LosslessStringConvertible, CustomStringConvertible.
/// It is initialized with a string that represents a version of an app.
/// The string must be in the format of "major.minor.patch".
/// The string must not contain any other characters than numbers and dots.
public struct AppVersion: Codable, Equatable, Comparable, Hashable, LosslessStringConvertible, CustomStringConvertible, Sendable {

    /// ParseError is an enum that represents an error that occurs when parsing a string to an AppVersion.
    private enum ParseError: Error {
        case nonIntegerValue
    }

    /// Initializes an AppVersion with a string that represents a version of an app.
    public init?(_ description: String) {
        if let versionSequence = try? description.split(separator: ".").map({ (value: Substring) throws -> Int in
            guard let value = Int(value) else { throw ParseError.nonIntegerValue }
            return value
        }) {
            if versionSequence.count < 1 {
                self.majorVersion = 0
            } else {
                self.majorVersion = versionSequence[0]
            }

            if versionSequence.count < 2 {
                self.minorVersion = 0
            } else {
                self.minorVersion = versionSequence[1]
            }

            if versionSequence.count < 3 {
                self.patchVersion = 0
            } else {
                self.patchVersion = versionSequence[2]
            }
        } else {
            return nil
        }
    }

    /// Compares two AppVersions.
    public static func < (lhs: AppVersion, rhs: AppVersion) -> Bool {
        for (l, r) in zip([lhs.majorVersion, lhs.minorVersion, lhs.patchVersion], [rhs.majorVersion, rhs.minorVersion, rhs.patchVersion]) {
            if l == r {
                continue
            }
            return l < r
        }
        return false
    }

    public var majorVersion: Int
    public var minorVersion: Int
    public var patchVersion: Int

    public var description: String {
        "\(majorVersion).\(minorVersion).\(patchVersion)"
    }
}
public extension AppVersion {
    static let azooKey_v2_4_0 = AppVersion("2.4.0")!
    static let azooKey_v2_2_3 = AppVersion("2.2.3")!
    static let azooKey_v2_2_2 = AppVersion("2.2.2")!
    static let azooKey_v2_0_2 = AppVersion("2.0.2")!
    static let azooKey_v1_9 = AppVersion("1.9")!
    static let azooKey_v1_8_1 = AppVersion("1.8.1")!
    static let azooKey_v1_8 = AppVersion("1.8")!
    static let azooKey_v1_7_2 = AppVersion("1.7.2")!
    static let azooKey_v1_7_1 = AppVersion("1.7.1")!
    /// The next app version used for feature gates before finalizing the release version.
    /// Adjust this to the decided version (e.g., "3.1.0" or "3.0.1") before release.
    static let nextVersion: AppVersion = AppVersion("3.1.0")!
}
