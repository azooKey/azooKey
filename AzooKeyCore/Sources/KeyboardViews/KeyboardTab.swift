//
//  KeyboardTab.swift
//  azooKey
//
//  Created by ensan on 2022/12/20.
//  Copyright © 2022 ensan. All rights reserved.
//

import Foundation
import KanaKanjiConverterModule

public enum UpsideComponent: Equatable, Sendable {
    case search([ConverterBehaviorSemantics.ReplacementTarget])
    case supplementaryCandidates
    case reportSuggestion(ReportContent)
}

public enum KeyboardTab: Equatable {
    case resolved(ResolvedTab)
    case userDependent(UserDependentTab)
    case lastTab

    public enum UserDependentTab: Equatable {
        case japanese
        case english
    }
}
