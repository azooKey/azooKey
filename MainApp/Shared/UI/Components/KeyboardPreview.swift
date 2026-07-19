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

enum KeyboardPreviewSizing: Equatable {
    case responsive
    case thumbnail(scale: CGFloat)
    case fixed(containerWidth: CGFloat, scale: CGFloat)

    fileprivate var initialContainerWidth: CGFloat? {
        switch self {
        case .responsive, .thumbnail:
            nil
        case let .fixed(containerWidth, _):
            containerWidth
        }
    }

    fileprivate var scale: CGFloat {
        switch self {
        case .responsive:
            1
        case let .thumbnail(scale), let .fixed(_, scale):
            max(scale, 0.01)
        }
    }

    fileprivate var measuresAvailableWidth: Bool {
        switch self {
        case .responsive, .thumbnail:
            true
        case .fixed:
            false
        }
    }
}

@MainActor
struct KeyboardPreview: View {
    private let theme: AzooKeyTheme

    private let sizing: KeyboardPreviewSizing
    private let defaultTab: KeyboardTab.ExistentialTab?
    @State private var availableWidth: CGFloat
    @StateObject private var variableStates: VariableStates

    init(
        theme: AzooKeyTheme? = nil,
        sizing: KeyboardPreviewSizing = .responsive,
        defaultTab: KeyboardTab.ExistentialTab? = nil
    ) {
        self.theme = theme ?? AzooKeySpecificTheme.default
        self.sizing = sizing
        self.defaultTab = defaultTab
        self._availableWidth = State(initialValue: sizing.initialContainerWidth ?? 0)

        let variableStates = VariableStates(
            interfaceWidth: sizing.initialContainerWidth,
            orientation: MainAppDesign.keyboardOrientation,
            clipboardHistoryManagerConfig: ClipboardHistoryManagerConfig(),
            tabManagerConfig: TabManagerConfig(),
            userDefaults: UserDefaults.standard
        )
        variableStates.resultModel.setResults([
            CandidateMock(text: "azooKey"),
            CandidateMock(text: "あずーきー"),
            CandidateMock(text: "アズーキー"),
        ])
        self._variableStates = StateObject(wrappedValue: variableStates)
    }

    var body: some View {
        Color.clear
            .frame(
                width: sizing.measuresAvailableWidth ? nil : displaySize.width,
                height: displaySize.height
            )
            .frame(maxWidth: sizing.measuresAvailableWidth ? .infinity : nil)
            .overlay(alignment: .top) {
                if availableWidth > 0 {
                    KeyboardView<AzooKeyKeyboardViewExtension>(defaultTab: defaultTab)
                        .environmentObject(variableStates)
                        .themeEnvironment(theme)
                        .environment(\.showMessage, false)
                        .frame(
                            width: availableWidth,
                            height: keyboardHeight
                        )
                        .scaleEffect(sizing.scale, anchor: .topLeading)
                        .frame(
                            width: displaySize.width,
                            height: displaySize.height,
                            alignment: .topLeading
                        )
                }
            }
            .onGeometryChange(for: CGFloat.self) { proxy in
                sizing.measuresAvailableWidth ? proxy.size.width : 0
            } action: { width in
                guard sizing.measuresAvailableWidth, width > 0 else {
                    return
                }
                updateContainerWidth(width)
            }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: UIDevice.orientationDidChangeNotification
                )
            ) { _ in
                updateContainerWidth(availableWidth)
            }
    }

    private var keyboardHeight: CGFloat {
        Design.keyboardScreenHeight(
            context: variableStates.layoutContext,
            upsideComponent: nil
        )
    }

    private var displaySize: CGSize {
        CGSize(
            width: availableWidth * sizing.scale,
            height: keyboardHeight * sizing.scale
        )
    }

    private func updateContainerWidth(_ width: CGFloat) {
        guard width > 0 else {
            return
        }
        if availableWidth != width {
            availableWidth = width
        }
        variableStates.setContainerWidth(
            width,
            orientation: MainAppDesign.keyboardOrientation
        )
    }
}
