//
//  KeyboardPreview.swift
//  MainApp
//
//  Created by ensan on 2021/02/06.
//  Copyright © 2021 ensan. All rights reserved.
//

import AzooKeyUtils
import Foundation
import KeyboardViews
import SwiftUI

private struct CandidateMock: ResultViewItemData {
    let inputable: Bool = true
    var text: String
    var label: ResultViewItemLabelStyle {
        .text(text)
    }
    #if DEBUG
    func getDebugInformation() -> String {
        "CandidateMock: \(text)"
    }
    #endif
}

@MainActor
struct KeyboardPreview: View {
    private let theme: AzooKeyTheme

    private let scale: CGFloat
    private let defaultTab: KeyboardTab.ExistentialTab?
    @StateObject private var variableStates = VariableStates(
        interfaceWidth: UIScreen.main.bounds.width,
        orientation: MainAppDesign.keyboardOrientation,
        clipboardHistoryManagerConfig: ClipboardHistoryManagerConfig(),
        tabManagerConfig: TabManagerConfig(),
        userDefaults: UserDefaults.standard
    )

    init(theme: AzooKeyTheme? = nil, scale: CGFloat = 1, defaultTab: KeyboardTab.ExistentialTab? = nil) {
        self.theme = theme ?? AzooKeySpecificTheme.default
        self.scale = scale
        self.defaultTab = defaultTab
    }

    var body: some View {
        let context = MainAppDesign.keyboardLayoutContext(
            containerWidth: SemiStaticStates.shared.screenWidth
        )
        KeyboardView<AzooKeyKeyboardViewExtension>(defaultTab: defaultTab)
            .environmentObject(variableStates)
            .themeEnvironment(theme)
            .environment(\.showMessage, false)
            .scaleEffect(scale)
            .frame(
                width: context.containerWidth * scale,
                height: Design.keyboardScreenHeight(
                    context: context,
                    upsideComponent: nil
                ) * scale
            )
            .onAppear {
                variableStates.resultModel.setResults([
                    CandidateMock(text: "azooKey"),
                    CandidateMock(text: "あずーきー"),
                    CandidateMock(text: "アズーキー"),
                ])
            }
    }
}
