//
//  InKeyboardSearchBar.swift
//  azooKey
//
//  Created by β α on 2023/03/17.
//  Copyright © 2023 DevEn3. All rights reserved.
//

import SwiftUI
import SwiftUtils

struct InKeyboardSearchBar<Extension: ApplicationSpecificKeyboardViewExtension>: View {
    init(text: Binding<String>, configuration: Configuration, initiallyFocused: Bool = false) {
        self._text = text
        self.configuration = configuration
        self.initiallyFocused = initiallyFocused
    }
    struct Configuration {
        var placeholder: String?
        var clearButtonMode: UITextField.ViewMode?
        var theme: Extension.Theme?
    }

    private let configuration: Configuration
    private let initiallyFocused: Bool
    private let id = UUID()
    @Binding private var text: String
    @State private var proxyWrapper = IKTextDocumentProxyWrapper()
    @Environment(\.userActionManager) private var action

    var body: some View {
        SearchBarWrapper(proxyWrapper: $proxyWrapper, text: $text, configuration: configuration, initiallyFocused: self.initiallyFocused)
            .onDisappear {
                action.setTextDocumentProxy(.ikTextFieldProxy(id, nil))
            }
            .onChange(of: proxyWrapper) { newValue in
                action.setTextDocumentProxy(.ikTextFieldProxy(id, newValue.proxy))
                if newValue.proxy != nil {
                    action.setTextDocumentProxy(.preference(.ikTextField))
                }
            }
    }
}

private final class IKSearchBar: UISearchBar {}

private struct SearchBarWrapper<Extension: ApplicationSpecificKeyboardViewExtension>: UIViewRepresentable {
    @Binding var proxyWrapper: IKTextDocumentProxyWrapper
    @Binding var text: String
    @Environment(\.userActionManager) private var action
    @EnvironmentObject private var variableStates: VariableStates
    var configuration: InKeyboardSearchBar<Extension>.Configuration
    var initiallyFocused: Bool

    func makeUIView(context: UIViewRepresentableContext<Self>) -> IKSearchBar {
        let view = IKSearchBar(frame: .zero)

        view.searchTextField.delegate = context.coordinator
        // MARK: `inputView`に空の`UIView`を入れないと、フォーカスが当たったタイミングで標準のキーボードを開こうとしてエラーになることがある。
        view.searchTextField.inputView = UIView()
        // inputDelegateの調整
        view.searchTextField.inputDelegate = context.coordinator

        if let placeholder = configuration.placeholder, let theme = configuration.theme {
            let weight: UIFont.Weight
            switch theme.textFont {
            case .ultraLight:
                weight = .ultraLight
            case .thin:
                weight = .thin
            case .light:
                weight = .light
            case .regular:
                weight = .regular
            case .medium:
                weight = .medium
            case .semibold:
                weight = .semibold
            case .bold:
                weight = .bold
            case .heavy:
                weight = .heavy
            case .black:
                weight = .black
            }
            let font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize, weight: weight)
            view.searchTextField.attributedPlaceholder = .init(string: placeholder, attributes: [
                .foregroundColor: UIColor(theme.resultTextColor.color),
                .font: font
            ])
            view.searchTextField.textColor = UIColor(theme.resultTextColor.color)
            view.searchTextField.rightView?.tintColor = UIColor(theme.resultTextColor.color)
            view.searchTextField.leftView?.tintColor = UIColor(theme.resultTextColor.color)
        } else {
            view.placeholder = configuration.placeholder
        }

        if let mode = configuration.clearButtonMode {
            view.searchTextField.clearButtonMode = mode
        }

        view.barStyle = .default
        view.searchBarStyle = .minimal
        if let theme = configuration.theme {
            view.searchTextField.backgroundColor = UIColor(theme.prominentBackgroundColor)
        }

        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.searchTextField.addTarget(context.coordinator, action: #selector(context.coordinator.textFieldDidChange), for: .editingChanged)
        view.sizeToFit()
        if initiallyFocused {
            view.searchTextField.becomeFirstResponder()
        }
        proxyWrapper.proxy = IKTextDocumentProxy(input: view.searchTextField)
        return view
    }

    func updateUIView(_ view: IKSearchBar, context: UIViewRepresentableContext<Self>) {
        if view.text != text {
            Task {
                view.text = text
            }
        }
    }

    func makeCoordinator() -> Self.Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, UITextFieldDelegate, UISearchTextFieldDelegate, UITextInputDelegate {
        @available(iOS 18.4, *)
        func conversationContext(_ context: UIConversationContext?, didChange textInput: (any UITextInput)?) {}

        var parent: SearchBarWrapper

        init(parent: SearchBarWrapper) {
            self.parent = parent
        }

        func textFieldDidBeginEditing(_ view: UITextField) {
            debug("textFieldDidBeginEditing")
            parent.text = view.text ?? ""
            parent.proxyWrapper.proxy = IKTextDocumentProxy(input: view)
        }

        func textFieldDidChangeSelection(_ view: UITextField) {
            parent.text = view.text ?? ""
        }

        @objc func textFieldDidChange(_ view: UITextField) {
            parent.text = view.text ?? ""
        }

        func textFieldDidEndEditing(_ view: UITextField) {
            parent.text = view.text ?? ""
            parent.proxyWrapper.proxy = nil
        }

        func notifyWillChange(_ textInput: any UITextInput) {
            let proxy = IKTextDocumentProxy(input: textInput)
            self.parent.action.notifySomethingWillChange(
                left: proxy.documentContextBeforeInput ?? "",
                center: proxy.selectedText ?? "",
                right: proxy.documentContextAfterInput ?? ""
            )
        }

        func notifyDidChange(_ textInput: any UITextInput) {
            let proxy = IKTextDocumentProxy(input: textInput)
            self.parent.action.notifySomethingDidChange(
                a_left: proxy.documentContextBeforeInput ?? "",
                a_center: proxy.selectedText ?? "",
                a_right: proxy.documentContextAfterInput ?? "",
                variableStates: self.parent.variableStates
            )
            self.parent.action.setTextDocumentProxy(.preference(.ikTextField))
            self.parent.variableStates.setUIReturnKeyType(type: .default)
        }

        // MARK: こちらで`textWillChange`などをハンドルすることで、`KeyboardViewController`では扱われなくなる
        func selectionWillChange(_ textInput: (any UITextInput)?) {
            debug("TextViewWrapper.Coordinator.selectionWillChange")
            guard let textInput else {
                return
            }
            self.notifyWillChange(textInput)
        }

        func selectionDidChange(_ textInput: (any UITextInput)?) {
            debug("TextViewWrapper.Coordinator.selectionDidChange")
            guard let textInput else {
                return
            }
            self.notifyDidChange(textInput)
        }

        func textWillChange(_ textInput: (any UITextInput)?) {
            debug("TextViewWrapper.Coordinator.textWillChange")
            guard let textInput else {
                return
            }
            self.notifyWillChange(textInput)
        }

        func textDidChange(_ textInput: (any UITextInput)?) {
            debug("TextViewWrapper.Coordinator.textDidChange")
            guard let textInput else {
                return
            }
            self.notifyDidChange(textInput)
        }
    }
}
