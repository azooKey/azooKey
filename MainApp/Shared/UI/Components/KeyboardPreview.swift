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
    case fitToExtension
    case fixed(containerWidth: CGFloat, scale: CGFloat)

    fileprivate var initialContainerWidth: CGFloat? {
        switch self {
        case .responsive, .thumbnail, .fitToExtension:
            nil
        case let .fixed(containerWidth, _):
            containerWidth
        }
    }

    fileprivate var staticScale: CGFloat? {
        switch self {
        case .responsive:
            1
        case let .thumbnail(scale), let .fixed(_, scale):
            max(scale, 0.01)
        case .fitToExtension:
            nil
        }
    }

    fileprivate var measuresAvailableWidth: Bool {
        switch self {
        case .responsive, .thumbnail, .fitToExtension:
            true
        case .fixed:
            false
        }
    }

    @MainActor
    fileprivate func resolvedContainerSize(
        for measuredWidth: CGFloat
    ) -> CGSize {
        switch self {
        case .responsive:
            return CGSize(width: measuredWidth, height: 0)
        case .thumbnail:
            return CGSize(
                width: measuredWidth / (staticScale ?? 1),
                height: 0
            )
        case .fitToExtension:
            let orientation = MainAppDesign.keyboardOrientation
            if let size = SharedStore.resolvedKeyboardSize(
                orientation: orientation
            ) {
                return size
            }
            let context = MainAppDesign.keyboardLayoutContext(
                containerWidth: measuredWidth
            )
            return CGSize(
                width: measuredWidth,
                height: Design.keyboardHeight(
                    context: context,
                    upsideComponent: nil
                ) * CGFloat(AzooKeySettingProvider.keyboardHeight)
                    + Design.keyboardScreenBottomPadding
            )
        case let .fixed(containerWidth, _):
            return CGSize(width: containerWidth, height: 0)
        }
    }
}

@MainActor
struct KeyboardPreview: View {
    private let theme: AzooKeyTheme

    @Environment(\.scenePhase) private var scenePhase
    private let sizing: KeyboardPreviewSizing
    private let defaultTab: KeyboardTab.ExistentialTab?
    @State private var availableWidth: CGFloat
    @State private var measuredDisplayWidth: CGFloat = 0
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
                guard let containerWidth = sizing.initialContainerWidth else {
                    return
                }
                updateContainerWidth(containerWidth)
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
        } else if let containerWidth = sizing.initialContainerWidth {
            updateContainerWidth(containerWidth)
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
