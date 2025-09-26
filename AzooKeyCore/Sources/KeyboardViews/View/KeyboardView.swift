//
//  KeyboardView.swift
//  azooKey
//
//  Created by ensan on 2020/04/08.
//  Copyright © 2020 ensan. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
public struct KeyboardView<Extension: ApplicationSpecificKeyboardViewExtension>: View {
    @State private var messageManager = MessageManager(necessaryMessages: Extension.MessageProvider.messages, userDefaults: Extension.MessageProvider.userDefaults)
    @State private var isResultViewExpanded = false

    @Environment(Extension.Theme.self) private var theme
    @Environment(\.showMessage) private var showMessage
    @EnvironmentObject private var variableStates: VariableStates

    private let defaultTab: KeyboardTab.ExistentialTab?

    public init(defaultTab: KeyboardTab.ExistentialTab? = nil) {
        self.defaultTab = defaultTab
    }

    private var backgroundColor: Color {
        if theme.picture.image != nil {
            Color.white.opacity(0.001)
        } else {
            theme.backgroundColor.color
        }
    }

    private var resolvedInterfaceHeight: CGFloat {
        let current = variableStates.interfaceSize.height
        if current > 0 {
            return current
        }
        let screenWidth = SemiStaticStates.shared.screenWidth
        let baseHeight = Design.keyboardHeight(screenWidth: screenWidth, orientation: variableStates.keyboardOrientation, upsideComponent: nil)
        let scaledHeight = baseHeight * variableStates.heightScaleFromKeyboardHeightSetting
        return scaledHeight
    }

    private var componentOverlayHeight: CGFloat {
        guard let component = variableStates.upsideComponent else {
            return 0
        }
        return Design.upsideComponentHeight(component, orientation: variableStates.keyboardOrientation)
    }

    private var totalBackgroundHeight: CGFloat {
        resolvedInterfaceHeight + Design.keyboardScreenBottomPadding + componentOverlayHeight
    }

    @ViewBuilder
    private var backgroundCore: some View {
        Rectangle()
            .foregroundStyle(self.backgroundColor)
            .frame(maxWidth: .infinity)
            .overlay {
                if let image = theme.picture.image {
                    image
                        .resizable()
                        .scaledToFill()
                }
            }
            .frame(
                width: SemiStaticStates.shared.screenWidth,
                height: resolvedInterfaceHeight + Design.keyboardScreenBottomPadding
            )
    }

    @ViewBuilder
    private var extendedBackground: some View {
        if variableStates.upsideComponent != nil {
            Rectangle()
                .fill(theme.backgroundColor.color)
                .blendMode(theme.backgroundColor.blendMode)
                .frame(width: SemiStaticStates.shared.screenWidth, height: totalBackgroundHeight)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .allowsHitTesting(false)
        }
    }

    @MainActor
    public var body: some View {
        ZStack { [unowned variableStates] in
            ZStack(alignment: .bottom) {
                if #available(iOS 26, *), variableStates.keyboardOrientation == .vertical {
                    let shape = UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28)
                    extendedBackground.clipShape(shape)
                    backgroundCore.clipShape(shape)
                } else {
                    extendedBackground.clipped()
                    backgroundCore.clipped()
                }
            }
            VStack(spacing: 0) {
                if let upsideComponent = variableStates.upsideComponent {
                    Group {
                        switch upsideComponent {
                        case let .search(target):
                            UpsideSearchView<Extension>(target: target)
                        case .supplementaryCandidates:
                            SupplementaryCandidateView<Extension>()
                        }
                    }
                    .frame(height: Design.upsideComponentHeight(upsideComponent, orientation: variableStates.keyboardOrientation))
                }
                // キーボード本体部分を新しいVStackで囲み、モディファイアをこちらに移動
                VStack(spacing: 0) {
                    if isResultViewExpanded {
                        ExpandedResultView<Extension>(isResultViewExpanded: $isResultViewExpanded)
                    } else {
                        KeyboardBarView<Extension>(isResultViewExpanded: $isResultViewExpanded)
                            .frame(height: Design.keyboardBarHeight(interfaceHeight: variableStates.interfaceSize.height, orientation: variableStates.keyboardOrientation))
                            // バーのタッチ判定領域はpaddingより前まで
                            .contentShape(Rectangle())
                            .padding(.vertical, 6)
                        keyboardView(tab: defaultTab ?? variableStates.tabManager.existentialTab())
                            .zIndex(1)
                    }
                }
                .resizingFrame(
                    size: $variableStates.interfaceSize,
                    position: $variableStates.interfacePosition,
                    initialSize: CGSize(width: SemiStaticStates.shared.screenWidth, height: Design.keyboardHeight(screenWidth: SemiStaticStates.shared.screenWidth, orientation: variableStates.keyboardOrientation)),
                    extension: Extension.self
                )
                .padding(.bottom, Design.keyboardScreenBottomPadding)
                .onChange(of: variableStates.resultModel.results.isEmpty) { (_, isEmpty) in
                    if isEmpty {
                        self.isResultViewExpanded = false
                    }
                }
            }

            if variableStates.boolStates.isTextMagnifying {
                LargeTextView(text: variableStates.magnifyingText, isViewOpen: $variableStates.boolStates.isTextMagnifying)
            }
            if showMessage {
                ForEach(messageManager.necessaryMessages, id: \.id) {data in
                    if messageManager.requireShow(data.id) {
                        MessageView(data: data, manager: $messageManager)
                    }
                }
            }
            if showMessage, let message = variableStates.temporalMessage {
                let isPresented = Binding(
                    get: { variableStates.temporalMessage != nil },
                    set: { if !$0 {variableStates.temporalMessage = nil} }
                )
                TemporalMessageView(message: message, isPresented: isPresented)
            }
        }
        .frame(height: totalBackgroundHeight)
    }

    @MainActor @ViewBuilder
    func renderUnified(
        modelsDict: [UnifiedPositionSpecifier: any UnifiedKeyModelProtocol<Extension>],
        width: Int,
        height: Int,
        gestureFor: (any UnifiedKeyModelProtocol<Extension>) -> UnifiedGenericKeyView<Extension>.GestureSet
    ) -> some View {
        let design = TabDependentDesign(width: width, height: height, interfaceSize: variableStates.interfaceSize, orientation: variableStates.keyboardOrientation)
        let unifiedModels: [(UnifiedPositionSpecifier, any UnifiedKeyModelProtocol<Extension>, UnifiedGenericKeyView<Extension>.GestureSet)] = modelsDict.map { (pos, model) in
            (pos, model, gestureFor(model))
        }
        UnifiedKeysView(models: unifiedModels, tabDesign: design) { keyView, _ in keyView }
    }

    @MainActor @ViewBuilder
    func keyboardView(tab: KeyboardTab.ExistentialTab) -> some View {
        let qwertyGesture: (any UnifiedKeyModelProtocol<Extension>) -> UnifiedGenericKeyView<Extension>.GestureSet = { model in
            if case let .fourWay(map) = model.variationSpace(variableStates: variableStates), !map.isEmpty {
                return .directionalFlick
            } else {
                return .linearVariation
            }
        }

        switch tab {
        case .flick_hira:
            renderUnified(modelsDict: FlickLayoutProvider<Extension>.hiraKeyboard, width: 5, height: 4, gestureFor: qwertyGesture)
        case .flick_abc:
            renderUnified(modelsDict: FlickLayoutProvider<Extension>.abcKeyboard, width: 5, height: 4, gestureFor: qwertyGesture)
        case .flick_numbersymbols:
            renderUnified(modelsDict: FlickLayoutProvider<Extension>.numberKeyboard, width: 5, height: 4, gestureFor: qwertyGesture)
        case .qwerty_hira:
            renderUnified(modelsDict: QwertyLayoutProvider<Extension>.hiraKeyboard(), width: 10, height: 4, gestureFor: qwertyGesture)
        case .qwerty_abc:
            renderUnified(modelsDict: QwertyLayoutProvider<Extension>.abcKeyboard(), width: 10, height: 4, gestureFor: qwertyGesture)
        case .qwerty_numbers:
            renderUnified(modelsDict: QwertyLayoutProvider<Extension>.numberKeyboard, width: 10, height: 4, gestureFor: qwertyGesture)
        case .qwerty_symbols:
            renderUnified(modelsDict: QwertyLayoutProvider<Extension>.symbolsKeyboard(), width: 10, height: 4, gestureFor: qwertyGesture)
        case let .custard(custard):
            CustomKeyboardView<Extension>(custard: custard)
        case let .special(tab):
            switch tab {
            case .clipboard_history_tab:
                ClipboardHistoryTab<Extension>()
            case .emoji:
                EmojiTab<Extension>()
            }
        }
    }
}
