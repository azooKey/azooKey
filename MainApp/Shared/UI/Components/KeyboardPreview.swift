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
    case fitToExtension
    case render(resolvedSize: CGSize, scale: CGFloat)

    fileprivate var initialResolvedSize: CGSize? {
        switch self {
        case .fitToExtension:
            nil
        case let .render(resolvedSize, _):
            resolvedSize
        }
    }

    fileprivate var staticScale: CGFloat? {
        switch self {
        case .fitToExtension:
            nil
        case let .render(_, scale):
            max(scale, 0.01)
        }
    }

    fileprivate var measuresAvailableWidth: Bool {
        switch self {
        case .fitToExtension:
            true
        case .render:
            false
        }
    }

    @MainActor
    static func resolvedExtensionSize(
        fallbackWidth: CGFloat
    ) -> CGSize {
        let orientation = MainAppDesign.keyboardOrientation
        if let size = SharedStore.resolvedKeyboardSize(
            orientation: orientation
        ) {
            return size
        }
        let context = MainAppDesign.keyboardLayoutContext(
            containerWidth: fallbackWidth
        )
        return CGSize(
            width: fallbackWidth,
            height: Design.keyboardHeight(
                context: context,
                upsideComponent: nil
            ) * CGFloat(AzooKeySettingProvider.keyboardHeight)
                + Design.keyboardScreenBottomPadding
        )
    }

    @MainActor
    fileprivate func resolvedContainerSize(
        for measuredWidth: CGFloat
    ) -> CGSize {
        switch self {
        case .fitToExtension:
            Self.resolvedExtensionSize(fallbackWidth: measuredWidth)
        case let .render(resolvedSize, _):
            resolvedSize
        }
    }
}

@MainActor
struct KeyboardPreview: View {
    private let theme: AzooKeyTheme

    @Environment(\.scenePhase) private var scenePhase
    private let sizing: KeyboardPreviewSizing
    private let defaultTab: ResolvedTab?
    @State private var availableWidth: CGFloat
    @State private var measuredDisplayWidth: CGFloat = 0
    @StateObject private var variableStates: VariableStates

    init(
        theme: AzooKeyTheme? = nil,
        sizing: KeyboardPreviewSizing = .fitToExtension,
        defaultTab: ResolvedTab? = nil
    ) {
        self.theme = theme ?? AzooKeySpecificTheme.default
        self.sizing = sizing
        self.defaultTab = defaultTab
        self._availableWidth = State(
            initialValue: sizing.initialResolvedSize?.width ?? 0
        )

        let variableStates = VariableStates(
            interfaceWidth: sizing.initialResolvedSize?.width,
            orientation: MainAppDesign.keyboardOrientation,
            clipboardHistoryManagerConfig: ClipboardHistoryManagerConfig(),
            tabManagerConfig: TabManagerConfig(),
            userDefaults: UserDefaults.standard
        )
        if let resolvedHeight = sizing.initialResolvedSize?.height {
            variableStates.interfaceSize.height = max(
                0,
                resolvedHeight - Design.keyboardScreenBottomPadding
            )
        }
        if let defaultTab {
            variableStates.setTabForPreview(defaultTab)
        }
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
                        .scaleEffect(displayScale, anchor: .topLeading)
                        .frame(
                            width: displaySize.width,
                            height: displaySize.height,
                            alignment: .topLeading
                        )
                }
            }
            .onGeometryChange(for: CGFloat.self) { proxy in
                sizing.measuresAvailableWidth ? proxy.size.width : 0
            } action: { displayWidth in
                guard sizing.measuresAvailableWidth, displayWidth > 0 else {
                    return
                }
                measuredDisplayWidth = displayWidth
                updateLayout(for: displayWidth)
            }
            .onChange(of: sizing) { _, sizing in
                if sizing.measuresAvailableWidth, measuredDisplayWidth > 0 {
                    updateLayout(for: measuredDisplayWidth)
                    return
                }
                guard let resolvedSize = sizing.initialResolvedSize else {
                    return
                }
                updateContainerWidth(
                    resolvedSize.width,
                    resolvedKeyboardHeight: resolvedSize.height
                )
            }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: UIDevice.orientationDidChangeNotification
                )
            ) { _ in
                updateCurrentLayout()
            }
            .onChange(of: scenePhase) { _, scenePhase in
                guard scenePhase == .active else {
                    return
                }
                updateCurrentLayout()
            }
    }

    private var keyboardHeight: CGFloat {
        variableStates.interfaceSize.height + Design.keyboardScreenBottomPadding
    }

    private var displaySize: CGSize {
        CGSize(
            width: availableWidth * displayScale,
            height: keyboardHeight * displayScale
        )
    }

    private var displayScale: CGFloat {
        if let staticScale = sizing.staticScale {
            return staticScale
        }
        guard availableWidth > 0 else {
            return 0
        }
        return measuredDisplayWidth / availableWidth
    }

    private func updateLayout(for displayWidth: CGFloat) {
        let resolvedSize = sizing.resolvedContainerSize(
            for: displayWidth
        )
        updateContainerWidth(
            resolvedSize.width,
            resolvedKeyboardHeight: resolvedSize.height > 0
                ? resolvedSize.height
                : nil
        )
    }

    private func updateCurrentLayout() {
        if sizing.measuresAvailableWidth, measuredDisplayWidth > 0 {
            updateLayout(for: measuredDisplayWidth)
        } else if let resolvedSize = sizing.initialResolvedSize {
            updateContainerWidth(
                resolvedSize.width,
                resolvedKeyboardHeight: resolvedSize.height
            )
        }
    }

    private func updateContainerWidth(
        _ width: CGFloat,
        resolvedKeyboardHeight: CGFloat? = nil
    ) {
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
        if let resolvedKeyboardHeight {
            variableStates.interfaceSize.height = max(
                0,
                resolvedKeyboardHeight - Design.keyboardScreenBottomPadding
            )
        }
    }
}
