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

    @MainActor
    public var body: some View {
        ZStack { [unowned variableStates] in
            Rectangle()
                .foregroundStyle(theme.backgroundColor.color)
                .frame(maxWidth: .infinity)
                .overlay {
                    if let image = theme.picture.image {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: SemiStaticStates.shared.screenWidth, height: Design.keyboardScreenHeight(upsideComponent: variableStates.upsideComponent, orientation: variableStates.keyboardOrientation))
                            .clipped()
                    }
                }
            VStack(spacing: 0) {
                if let upsideComponent = variableStates.upsideComponent {
                    Group {
                        switch upsideComponent {
                        case let .search(target):
                            UpsideSearchView<Extension>(target: target)
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
                    }
                }
                .resizingFrame(
                    size: $variableStates.interfaceSize,
                    position: $variableStates.interfacePosition,
                    initialSize: CGSize(width: SemiStaticStates.shared.screenWidth, height: Design.keyboardHeight(screenWidth: SemiStaticStates.shared.screenWidth, orientation: variableStates.keyboardOrientation)),
                    extension: Extension.self
                )
                .padding(.bottom, Design.keyboardScreenBottomPadding)
                // ▲ 修正箇所 ▲
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
        .frame(height: Design.keyboardScreenHeight(upsideComponent: variableStates.upsideComponent, orientation: variableStates.keyboardOrientation))
    }

    @MainActor @ViewBuilder
    func keyboardView(tab: KeyboardTab.ExistentialTab) -> some View {
        switch tab {
        case .flick_hira:
            FlickKeyboardView<Extension>(keyModels: FlickDataProvider<Extension>.hiraKeyboard, interfaceSize: variableStates.interfaceSize, keyboardOrientation: variableStates.keyboardOrientation)
        case .flick_abc:
            FlickKeyboardView<Extension>(keyModels: FlickDataProvider<Extension>.abcKeyboard, interfaceSize: variableStates.interfaceSize, keyboardOrientation: variableStates.keyboardOrientation)
        case .flick_numbersymbols:
            FlickKeyboardView<Extension>(keyModels: FlickDataProvider<Extension>.numberKeyboard, interfaceSize: variableStates.interfaceSize, keyboardOrientation: variableStates.keyboardOrientation)
        case .qwerty_hira:
            QwertyKeyboardView<Extension>(keyModels: QwertyDataProvider<Extension>.hiraKeyboard(), interfaceSize: variableStates.interfaceSize, keyboardOrientation: variableStates.keyboardOrientation)
        case .qwerty_abc:
            QwertyKeyboardView<Extension>(keyModels: QwertyDataProvider<Extension>.abcKeyboard(), interfaceSize: variableStates.interfaceSize, keyboardOrientation: variableStates.keyboardOrientation)
        case .qwerty_numbers:
            QwertyKeyboardView<Extension>(keyModels: QwertyDataProvider<Extension>.numberKeyboard, interfaceSize: variableStates.interfaceSize, keyboardOrientation: variableStates.keyboardOrientation)
        case .qwerty_symbols:
            QwertyKeyboardView<Extension>(keyModels: QwertyDataProvider<Extension>.symbolsKeyboard(), interfaceSize: variableStates.interfaceSize, keyboardOrientation: variableStates.keyboardOrientation)
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
