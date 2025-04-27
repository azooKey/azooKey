//
//  KeyboardViewController.swift
//  Keyboard
//
//  Created by ensan on 2020/04/06.
//  Copyright © 2020 ensan. All rights reserved.
//

import AzooKeyUtils
import Contacts
import KanaKanjiConverterModule
import KeyboardViews
import SwiftUI
import SwiftUtils
import UIKit

final private class KeyboardHostingController<Content: View>: UIHostingController<Content> {
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        .bottom
    }
}

extension UIInputView: @retroactive UIInputViewAudioFeedback {
    open var enableInputClicksWhenVisible: Bool {
        true
    }
}

extension UIKeyboardType: @retroactive CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .URL: return ".URL"
        case .asciiCapable: return ".asciiCapable"
        case .asciiCapableNumberPad: return ".asciiCapableNumberPad"
        case .decimalPad: return ".decimalPad"
        case .default: return ".default"
        case .emailAddress: return ".emailAddress"
        case .namePhonePad: return ".namePhonePad"
        case .numberPad: return ".numberPad"
        case .numbersAndPunctuation: return ".numbersAndPunctuation"
        case .phonePad: return ".phonePad"
        case .twitter: return ".twitter"
        case .webSearch: return ".webSearch"
        @unknown default:
            return "unknown value: \(self.rawValue)"
        }
    }
}

extension UIView {
    func clearAllView() {
        self.subviews.forEach {
            $0.clearAllView()
        }
        self.removeFromSuperview()
    }
}

final class KeyboardViewController: UIInputViewController {
    private static var keyboardViewHost: KeyboardHostingController<Keyboard>?
    private static var loadedInstanceCount: Int = 0
    private static let action = KeyboardActionManager()
    private static let variableStates = VariableStates(
        clipboardHistoryManagerConfig: ClipboardHistoryManagerConfig(),
        tabManagerConfig: TabManagerConfig(),
        userDefaults: UserDefaults.standard
    )
    private static let notificationCenter = NotificationCenter.default

    struct Keyboard: View {
        let theme: AzooKeyTheme
        var body: some View {
            KeyboardView<AzooKeyKeyboardViewExtension>()
                .themeEnvironment(theme)
                .environment(\.userActionManager, KeyboardViewController.action)
                .environmentObject(KeyboardViewController.variableStates)
        }
    }

    override func loadView() {
        super.loadView()
        // これをやることで背景が透け透けになり、OSネイティブに近い表示になる
        self.view.backgroundColor = .clear
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        SemiStaticStates.shared.setup()
        // 初回のみscreenWidthに初期値を与える
        // FIXME: アドホックな対処であり、例えば初期状態でiPhoneを横持ちしている場合には不正な挙動が発生する
        if SemiStaticStates.shared.screenWidth == 0 {
            SemiStaticStates.shared.setScreenWidth(UIScreen.main.bounds.width)
        }

        debug("KeyboardViewController.viewDidLoad, loadedInstanceCount:", KeyboardViewController.loadedInstanceCount)
        KeyboardViewController.loadedInstanceCount += 1

        // 初期化の順序としてこの位置に置くこと
        KeyboardViewController.variableStates.initialize()

        // 高さの設定を反映する
        @KeyboardSetting(.keyboardHeightScale) var keyboardHeightScale: Double
        SemiStaticStates.shared.setKeyboardHeightScale(keyboardHeightScale)
        self.setupKeyboardView()
    }

    private func setupKeyboardView() {
        let host = KeyboardViewController.keyboardViewHost ?? KeyboardHostingController(rootView: Keyboard(theme: getCurrentTheme()))
        // コントロールセンターを出しにくくする。
        host.setNeedsUpdateOfScreenEdgesDeferringSystemGestures()

        host.view.translatesAutoresizingMaskIntoConstraints = false
        // 背景をOSネイティブにするのに必要
        host.view.backgroundColor = .clear

        self.addChild(host)
        self.view.addSubview(host.view)
        host.didMove(toParent: self)

        self.view.leftAnchor.constraint(equalTo: host.view.leftAnchor).isActive = true
        self.view.rightAnchor.constraint(equalTo: host.view.rightAnchor).isActive = true
        self.view.bottomAnchor.constraint(equalTo: host.view.bottomAnchor).isActive = true
        self.view.heightAnchor.constraint(equalTo: host.view.heightAnchor).isActive = true

        KeyboardViewController.keyboardViewHost = host
        KeyboardViewController.action.setDelegateViewController(self)
        KeyboardViewController.action.setResultViewUpdateCallback(Self.variableStates)
    }

    private func getCurrentTheme() -> AzooKeyTheme {
        let indexManager = ThemeIndexManager.load()
        let defaultTheme = AzooKeySpecificTheme.default(layout: KeyboardViewController.variableStates.tabManager.existentialTab().layout)
        switch traitCollection.userInterfaceStyle {
        case .unspecified, .light:
            return (try? indexManager.theme(at: indexManager.selectedIndex)) ?? defaultTheme
        case .dark:
            return (try? indexManager.theme(at: indexManager.selectedIndexInDarkMode)) ?? defaultTheme
        @unknown default:
            return (try? indexManager.theme(at: indexManager.selectedIndex)) ?? defaultTheme
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        debug("KeyboardViewController.viewDidAppear")
        super.viewDidAppear(animated)
        self.updateStates()
        self.registerScreenActualSize()

        let window = self.view.window!
        let gr0 = window.gestureRecognizers![0] as UIGestureRecognizer
        let gr1 = window.gestureRecognizers![1] as UIGestureRecognizer
        gr0.delaysTouchesBegan = false
        gr1.delaysTouchesBegan = false

        self.view.becomeFirstResponder()
        self.updateViewConstraints()
    }

    func updateStates() {
        // キーボードタイプはviewDidAppearのタイミングで取得できる
        KeyboardViewController.variableStates.setKeyboardType(self.textDocumentProxy.keyboardType)

        // クリップボード履歴を更新する
        KeyboardViewController.variableStates.clipboardHistoryManager.reload()
        KeyboardViewController.variableStates.clipboardHistoryManager.checkUpdate()
        // ロード済みのインスタンスの数が増えすぎるとパフォーマンスに悪影響があるので、適当なところで強制終了する
        // viewDidAppearで強制終了すると再ロードが自然な形で実行される
        if KeyboardViewController.loadedInstanceCount > 15 {
            fatalError("Too many instance of KeyboardViewController was created")
        }

        KeyboardViewController.action.setDelegateViewController(self)
        KeyboardViewController.action.setResultViewUpdateCallback(Self.variableStates)
        SemiStaticStates.shared.setNeedsInputModeSwitchKey(self.needsInputModeSwitchKey)
        SemiStaticStates.shared.setHapticsAvailable()
        SemiStaticStates.shared.setHasFullAccess(self.hasFullAccess)

        Task {
            @KeyboardSetting(.useOSUserDict) var useOSUserDict
            var dict: [DicdataElement] = []
            if useOSUserDict {
                let lexicon = await self.requestSupplementaryLexicon()
                dict = lexicon.entries.map {entry in DicdataElement(word: entry.documentText, ruby: entry.userInput.toKatakana(), cid: CIDData.固有名詞.cid, mid: MIDData.一般.mid, value: -6)}
            }
            @KeyboardSetting(.enableContactImport) var enableContactImport
            if enableContactImport && self.hasFullAccess && CNContactStore.authorizationStatus(for: .contacts) == .authorized {
                let contactStore: CNContactStore = CNContactStore()
                let keys = [
                    CNContactFamilyNameKey,
                    CNContactPhoneticFamilyNameKey,
                    CNContactMiddleNameKey,
                    CNContactPhoneticMiddleNameKey,
                    CNContactGivenNameKey,
                    CNContactPhoneticGivenNameKey,
                    CNContactOrganizationNameKey,
                    CNContactPhoneticOrganizationNameKey
                ] as [NSString]

                struct NamePair: Hashable {
                    var name: String
                    var phoneticName: String
                    var isValid: Bool {
                        !name.isEmpty && !phoneticName.isEmpty
                    }
                }

                var familyNames: Set<NamePair> = []
                var middleNames: Set<NamePair> = []
                var givenNames: Set<NamePair> = []
                var orgNames: Set<NamePair> = []
                var fullNames: Set<NamePair> = []

                try contactStore.enumerateContacts(with: CNContactFetchRequest(keysToFetch: keys)) { contact, _ in
                    familyNames.update(with: NamePair(name: contact.familyName, phoneticName: contact.phoneticFamilyName))
                    middleNames.update(with: NamePair(name: contact.middleName, phoneticName: contact.phoneticMiddleName))
                    givenNames.update(with: NamePair(name: contact.givenName, phoneticName: contact.phoneticGivenName))
                    orgNames.update(with: NamePair(name: contact.organizationName, phoneticName: contact.phoneticOrganizationName))
                    fullNames.update(with: NamePair(
                        name: contact.familyName + contact.middleName + contact.givenName,
                        phoneticName: contact.phoneticFamilyName + contact.phoneticMiddleName + contact.phoneticGivenName
                    ))
                }
                for item in familyNames where item.isValid {
                    dict.append(DicdataElement(word: item.name, ruby: item.phoneticName, cid: CIDData.人名姓.cid, mid: MIDData.人名姓.mid, value: -6))
                }
                for item in middleNames where item.isValid {
                    dict.append(DicdataElement(word: item.name, ruby: item.phoneticName, cid: CIDData.人名一般.cid, mid: MIDData.一般.mid, value: -6))
                }
                for item in givenNames where item.isValid {
                    dict.append(DicdataElement(word: item.name, ruby: item.phoneticName, cid: CIDData.人名名.cid, mid: MIDData.人名名.mid, value: -6))
                }
                for item in fullNames where item.isValid {
                    dict.append(DicdataElement(word: item.name, ruby: item.phoneticName, cid: CIDData.人名一般.cid, mid: MIDData.一般.mid, value: -10))
                }
                for item in orgNames where item.isValid {
                    dict.append(DicdataElement(word: item.name, ruby: item.phoneticName, cid: CIDData.固有名詞組織.cid, mid: MIDData.組織.mid, value: -7))
                }
            }
            KeyboardViewController.action.sendToDicdataStore(.importOSUserDict(dict))
        }
    }

    func registerScreenActualSize() {
        if let bounds = KeyboardViewController.keyboardViewHost?.view.safeAreaLayoutGuide.owningView?.bounds {
            debug("KeyboardViewController.registerScreenActualSize bounds", bounds)
            SemiStaticStates.shared.setScreenWidth(bounds.width)
            KeyboardViewController.variableStates.setInterfaceSize(orientation: UIScreen.main.bounds.size.width < UIScreen.main.bounds.size.height ? .vertical : .horizontal, screenWidth: bounds.width)
        }
    }

    func updateResultView(_ candidates: [any ResultViewItemData]) {
        KeyboardViewController.variableStates.resultModel.setResults(candidates)
    }

    func makeChangeKeyboardButtonView<Extension: ApplicationSpecificKeyboardViewExtension>(size: CGFloat) -> ChangeKeyboardButtonView<Extension> {
        let selector = #selector(self.handleInputModeList(from:with:))
        return ChangeKeyboardButtonView(selector: selector, size: size)
    }

    override func viewWillDisappear(_ animated: Bool) {
        debug("KeyboardViewController.viewWillDisappear: キーボードが閉じられます")
        KeyboardViewController.action.closeKeyboard()
        KeyboardViewController.variableStates.closeKeyboard()
        KeyboardViewController.keyboardViewHost = nil
        KeyboardViewController.loadedInstanceCount -= 1
        super.viewWillDisappear(animated)
        self.view.clearAllView()
        self.removeFromParent()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        // この関数は「これから」向きが変わる場合に呼ばれるので、デバイスの向きによってwidthとheightが逆転するUIScreen.main.bounds.sizeを用いて向きを確かめることができる。
        // ただしこの時点でのUIScreen.mainの値はOSバージョンで変わる
        debug("KeyboardViewController.viewWillTransition", size, UIScreen.main.bounds.size)
        SemiStaticStates.shared.setScreenWidth(size.width)
        if #available(iOS 18, *) {
            KeyboardViewController.variableStates.setInterfaceSize(orientation: UIScreen.main.bounds.width < UIScreen.main.bounds.height ? .vertical : .horizontal, screenWidth: size.width)
        } else {
            KeyboardViewController.variableStates.setInterfaceSize(orientation: UIScreen.main.bounds.width < UIScreen.main.bounds.height ? .horizontal : .vertical, screenWidth: size.width)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        debug("KeyboardViewController.viewDidLayoutSubviews", SemiStaticStates.shared.screenWidth)
        self.view.frame.size.height = Design.keyboardScreenHeight(upsideComponent: KeyboardViewController.variableStates.upsideComponent, orientation: KeyboardViewController.variableStates.keyboardOrientation)
    }

    func reloadAllView() {
        debug("KeyboardViewController.reloadAllView")
        // subviewsを一度完全に削除する
        self.view.subviews.forEach {$0.clearAllView()}
        self.children.forEach {$0.removeFromParent()}
        KeyboardViewController.keyboardViewHost = nil
        self.setupKeyboardView()
    }

    /*
     override func selectionWillChange(_ textInput: UITextInput?) {
     super.selectionWillChange(textInput)
     debug("selectionWillChange")
     }

     override func selectionDidChange(_ textInput: UITextInput?) {
     super.selectionDidChange(textInput)
     debug("selectionDidChange")
     }
     */
    /// 引数の`textInput`は常に`nil`
    override func textWillChange(_ textInput: (any UITextInput)?) {
        super.textWillChange(textInput)

        let left = self.textDocumentProxy.documentContextBeforeInput ?? ""
        let center = self.textDocumentProxy.selectedText ?? ""
        let right = self.textDocumentProxy.documentContextAfterInput ?? ""
        debug("KeyboardViewController.textWillChange", left, center, right)

        Self.action.notifySomethingWillChange(left: left, center: center, right: right)
    }

    /// 引数の`textInput`は常に`nil`
    override func textDidChange(_ textInput: (any UITextInput)?) {
        super.textDidChange(textInput)

        let left = self.textDocumentProxy.documentContextBeforeInput ?? ""
        let center = self.textDocumentProxy.selectedText ?? ""
        let right = self.textDocumentProxy.documentContextAfterInput ?? ""
        debug("KeyboardViewController.textDidChange", left, center, right)

        Self.action.notifySomethingDidChange(a_left: left, a_center: center, a_right: right, variableStates: KeyboardViewController.variableStates)
        Self.action.setTextDocumentProxy(.preference(.main))
        // このタイミングでクリップボードを確認する
        KeyboardViewController.variableStates.clipboardHistoryManager.checkUpdate()
        KeyboardViewController.variableStates.setUIReturnKeyType(type: self.textDocumentProxy.returnKeyType ?? .default)
    }

    @objc func openURL(_ url: URL) {}
    // https://stackoverflow.com/questions/40019521/open-my-application-from-my-keyboard-extension-in-swift-3-0より
    func openUrl(url: URL?) {
        let selector = #selector(openURL(_:))
        var responder = (self as UIResponder).next
        while let r = responder, !r.responds(to: selector) {
            responder = r.next
        }
        _ = responder?.perform(selector, with: url)
    }

    func openApp(scheme: String) {
        // 日本語のURLは使えないので、パーセントエンコーディングを適用する
        guard let encoded = scheme.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encoded) else {
            debug("無効なschemeです", scheme, scheme.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? scheme)
            return
        }
        self.openUrl(url: url)
    }
}
