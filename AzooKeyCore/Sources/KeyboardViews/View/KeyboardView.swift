//
//  KeyboardView.swift
//  azooKey
//
//  Created by ensan on 2020/04/08.
//  Copyright © 2020 ensan. All rights reserved.
//

import CustardKit
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
        let baseHeight = Design.keyboardHeight(
            context: variableStates.layoutContext,
            upsideComponent: nil
        )
        let scaledHeight = baseHeight * variableStates.heightScaleFromKeyboardHeightSetting
        return scaledHeight
    }

    private var componentOverlayHeight: CGFloat {
        guard let component = variableStates.upsideComponent else {
            return 0
        }
        return Design.upsideComponentHeight(
            component,
            context: variableStates.layoutContext
        )
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
                width: variableStates.containerWidth,
                height: resolvedInterfaceHeight + Design.keyboardScreenBottomPadding
            )
    }

    @ViewBuilder
    private var extendedBackground: some View {
        if variableStates.upsideComponent != nil {
            Rectangle()
                .fill(theme.backgroundColor.color)
                .blendMode(theme.backgroundColor.blendMode)
                .frame(width: variableStates.containerWidth, height: totalBackgroundHeight)
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
                        case let .reportSuggestion(content):
                            ReportSuggestionView<Extension>(content: content)
                        }
                    }
                    .frame(
                        height: Design.upsideComponentHeight(
                            upsideComponent,
                            context: variableStates.layoutContext
                        )
                    )
                }
                // キーボード本体部分を新しいVStackで囲み、モディファイアをこちらに移動
                VStack(spacing: 0) {
                    if let detailState = variableStates.reportDetailState {
                        ExpandedReportView<Extension>(state: detailState)
                    } else if isResultViewExpanded {
                        ExpandedResultView<Extension>(isResultViewExpanded: $isResultViewExpanded)
                    } else {
                        KeyboardBarView<Extension>(isResultViewExpanded: $isResultViewExpanded)
                            .frame(
                                height: Design.keyboardBarHeight(
                                    interfaceHeight: variableStates.interfaceSize.height,
                                    context: variableStates.layoutContext
                                )
                            )
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
                    initialSize: CGSize(
                        width: variableStates.containerWidth,
                        height: Design.keyboardHeight(context: variableStates.layoutContext)
                    ),
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

    private var standardEnglishQwertyCustard: Custard {
        switch Extension.SettingProvider.qwertyShiftBehaviorPreference {
        case .left:
            .qwertyEnglish(
                useShiftKey: true,
                useDeprecatedShiftKeyBehavior: true
            )
        case .leftBottom:
            .qwertyEnglish(
                useShiftKey: true,
                useDeprecatedShiftKeyBehavior: false
            )
        case .off:
            .qwertyEnglish(
                useShiftKey: false,
                useDeprecatedShiftKeyBehavior: false
            )
        }
    }

    @MainActor @ViewBuilder
    func keyboardView(tab: KeyboardTab.ExistentialTab) -> some View {
        switch tab {
        case .flick_hira:
            CustomKeyboardView<Extension>(custard: settingAppliedFlickCustard(.flickJapanese))
        case .flick_abc:
            CustomKeyboardView<Extension>(custard: settingAppliedFlickCustard(.flickEnglish))
        case .flick_numbersymbols:
            CustomKeyboardView<Extension>(custard: settingAppliedFlickCustard(.flickNumberSymbols))
        case .qwerty_hira:
            CustomKeyboardView<Extension>(custard: .qwertyJapanese)
        case .qwerty_abc:
            CustomKeyboardView<Extension>(
                custard: standardEnglishQwertyCustard
            )
        case .qwerty_numbers:
            CustomKeyboardView<Extension>(
                custard: .qwertyNumbers(
                    customKeys: Extension.SettingProvider.numberTabCustomKeysSetting
                )
            )
        case .qwerty_symbols:
            CustomKeyboardView<Extension>(custard: .qwertySymbols)
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

    private func settingAppliedFlickCustard(_ custard: Custard) -> Custard {
        var custard = custard
        if Extension.SettingProvider.useNextCandidateKey {
            var interface = custard.interface
            interface.keys[.gridFit(.init(x: 4, y: 1))] = .system(.nextCandidate)
            custard.interface = interface
        }
        return custard
    }
}
