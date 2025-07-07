//
//  KeyboardViewController.swift
//  Keyboard
//
//  Created by ensan on 2020/04/06.
//  Copyright © 2020 ensan. All rights reserved.
//

import AzooKeyUtils
import Combine
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

final class KeyboardViewController: UIInputViewController {
    private static var keyboardViewHost: KeyboardHostingController<Keyboard>?
    private static var loadedInstanceCount: Int = 0
    private static let action = KeyboardActionManager()
    private static let variableStates = VariableStates(
        clipboardHistoryManagerConfig: ClipboardHistoryManagerConfig(),
        tabManagerConfig: TabManagerConfig(),
        userDefaults: UserDefaults.standard
    )

    struct Keyboard: View {
        var theme: AzooKeyTheme
        var body: some View {
            KeyboardView<AzooKeyKeyboardViewExtension>()
                .themeEnvironment(theme)
                .environment(\.userActionManager, KeyboardViewController.action)
                .environmentObject(KeyboardViewController.variableStates)
        }
    }

    private var keyboardHeightConstraint: NSLayoutConstraint?
    private var hostViewWidthConstraint: NSLayoutConstraint?
    private var hostViewHeightConstraint: NSLayoutConstraint?
    private var hostViewBottomConstraint: NSLayoutConstraint?
    private var cancellables = Set<AnyCancellable>()

    override func loadView() {
        super.loadView()
        // これをやることで背景が透け透けになり、OSネイティブに近い表示になる
        self.view.backgroundColor = .clear
    }

    override func viewDidLoad() {
        debug(#function, "loadedInstanceCount:", KeyboardViewController.loadedInstanceCount)
        super.viewDidLoad()
        SemiStaticStates.shared.setup()
        KeyboardViewController.loadedInstanceCount += 1
        // 初期化の順序としてこの位置に置くこと
        KeyboardViewController.variableStates.initialize()

        self.setupInitialKeyboardHeight()

        let layout = KeyboardViewController.variableStates.keyboardLayout
        let orientation = KeyboardViewController.variableStates.keyboardOrientation
        let savedItem = KeyboardViewController
            .variableStates
            .keyboardInternalSettingManager
            .oneHandedModeSetting
            .item(layout: layout, orientation: orientation)

        if savedItem.maxHeight > 0 {
            KeyboardViewController.variableStates.maximumHeight = savedItem.maxHeight
        }

        KeyboardViewController.variableStates
            .$interfaceSize
            .combineLatest(
                KeyboardViewController.variableStates.$resizingState,
                KeyboardViewController.variableStates.$maximumHeight,
                KeyboardViewController.variableStates.$upsideComponent
            )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] interfaceSize, state, maxH, upsideComponent in
                guard let self = self else { return }
                // In resizing mode use the dynamic maxH; otherwise default to interfaceSize.height
                // 1. upsideComponentの高さを計算する（存在しない場合は0）
                let upsideComponentHeight = upsideComponent.map { component in
                    Design.upsideComponentHeight(component, orientation: KeyboardViewController.variableStates.keyboardOrientation)
                } ?? 0

                let bodyHeight = (state == .resizing) ? maxH : interfaceSize.height

                // 3. 全体の高さを「本体の高さ + upsideComponentの高さ」として計算する
                let totalHeight = bodyHeight + upsideComponentHeight

                // 4. 計算した全体の高さを制約に設定する
                self.keyboardHeightConstraint?.constant = totalHeight
                self.keyboardHeightConstraint?.isActive = true
                self.view.setNeedsLayout()
                self.view.superview?.layoutIfNeeded()
            }
            .store(in: &cancellables)
    }

    private func setupKeyboardView() {
        let theme = self.getCurrentTheme()
        let host = KeyboardViewController.keyboardViewHost ?? KeyboardHostingController(rootView: Keyboard(theme: theme))
        host.rootView.theme = theme

        // コントロールセンターを出しにくくする。
        host.setNeedsUpdateOfScreenEdgesDeferringSystemGestures()

        host.view.translatesAutoresizingMaskIntoConstraints = false
        self.view.translatesAutoresizingMaskIntoConstraints = true
        // 背景をOSネイティブにするのに必要
        host.view.backgroundColor = .clear

        self.addChild(host)
        self.view.addSubview(host.view)
        host.didMove(toParent: self)

        // 初期値に対してはゼロを指定しておく
        self.keyboardHeightConstraint = self.keyboardHeightConstraint ?? self.view.heightAnchor.constraint(equalToConstant: 0)
        self.keyboardHeightConstraint?.isActive = false

        self.hostViewWidthConstraint = self.hostViewWidthConstraint ?? host.view.widthAnchor.constraint(equalTo: self.view.widthAnchor)
        self.hostViewHeightConstraint = self.hostViewHeightConstraint ?? host.view.heightAnchor.constraint(equalTo: self.view.heightAnchor)
        self.hostViewBottomConstraint = self.hostViewBottomConstraint ?? host.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        NSLayoutConstraint.activate([
            self.hostViewWidthConstraint!, self.hostViewHeightConstraint!, self.hostViewBottomConstraint!
        ])
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

    private func setupInitialKeyboardHeight() {
        @KeyboardSetting(.keyboardHeightScale) var keyboardHeightScale: Double

        guard keyboardHeightScale != 1 else { return }

        let hasOverwritten = Self.variableStates.keyboardInternalSettingManager.oneHandedModeSetting.item(layout: Self.variableStates.keyboardLayout, orientation: Self.variableStates.keyboardOrientation).userHasOverwrittenKeyboardHeightSetting

        let heightScaleToApply = hasOverwritten ? 1.0 : keyboardHeightScale
        KeyboardViewController.variableStates.heightScaleFromKeyboardHeightSetting = heightScaleToApply
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // サイズに関する情報はこのタイミングで設定する
        let size = self.rootParentViewController.view.bounds.size
        SemiStaticStates.shared.setScreenWidth(size.width)
        KeyboardViewController.variableStates.setInterfaceSize(orientation: UIScreen.main.bounds.width < UIScreen.main.bounds.height ? .vertical : .horizontal, screenWidth: size.width)
        // キーボードのセットアップはこの段階で行う
        self.setupKeyboardView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.updateStates()

        // Floating Keyboardなどの一部の処理に限り、このタイミングにならないとウィンドウ幅が不明なケースが存在する
        let size = self.rootParentViewController.view.bounds.size
        if size.width < SemiStaticStates.shared.screenWidth {
            SemiStaticStates.shared.setScreenWidth(size.width)
            KeyboardViewController.variableStates.setInterfaceSize(orientation: UIScreen.main.bounds.size.width < UIScreen.main.bounds.size.height ? .vertical : .horizontal, screenWidth: size.width)
            self.updateScreenHeight()
            debug(#function, size)
        }

        // viewDidAppearで実施する
        let window = self.view.window!
        let gr0 = window.gestureRecognizers![0] as UIGestureRecognizer
        let gr1 = window.gestureRecognizers![1] as UIGestureRecognizer
        gr0.delaysTouchesBegan = false
        gr1.delaysTouchesBegan = false
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

        SemiStaticStates.shared.setNeedsInputModeSwitchKey(self.needsInputModeSwitchKey)
        SemiStaticStates.shared.setHapticsAvailable()
        SemiStaticStates.shared.setHasFullAccess(self.hasFullAccess)

        Task { [weak self] in
            guard let self else { return }
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
                    CNContactPhoneticOrganizationNameKey,
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
            KeyboardViewController.action.sendToDicdataStore(.importDynamicUserDict(dict))
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
        KeyboardViewController.loadedInstanceCount -= 1
        super.viewWillDisappear(animated)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        // この関数は「これから」向きが変わる場合に呼ばれるので、デバイスの向きによってwidthとheightが逆転するUIScreen.main.bounds.sizeを用いて向きを確かめることができる。
        // ただしこの時点でのUIScreen.mainの値はOSバージョンや端末によって変わる
        debug(#function, size, UIScreen.main.bounds.size)
        SemiStaticStates.shared.setScreenWidth(size.width)
        if #available(iOS 18, *), UIDevice.current.userInterfaceIdiom == .phone {
            KeyboardViewController.variableStates.setInterfaceSize(orientation: UIScreen.main.bounds.width < UIScreen.main.bounds.height ? .vertical : .horizontal, screenWidth: size.width)
        } else {
            KeyboardViewController.variableStates.setInterfaceSize(orientation: UIScreen.main.bounds.width < UIScreen.main.bounds.height ? .horizontal : .vertical, screenWidth: size.width)
        }
        self.updateScreenHeight()
    }

    var rootParentViewController: UIViewController {
        var viewController: UIViewController = self
        while let p = viewController.parent {
            viewController = p
        }
        return viewController
    }

    func updateScreenHeight() {
        self.keyboardHeightConstraint?.isActive = true
        self.view.setNeedsLayout()
        self.view.superview?.layoutIfNeeded()
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

    /// Reference: https://stackoverflow.com/questions/79077018/unable-to-open-main-app-from-action-extension-in-ios-18-previously-working-met
    @objc @discardableResult func openURL(_ url: URL) -> Bool {
        var responder: UIResponder? = self
        while let r = responder {
            if let application = r as? UIApplication {
                if #available(iOS 18.0, *) {
                    application.open(url, options: [:], completionHandler: nil)
                    return true
                } else {
                    return application.perform(#selector(openURL(_:)), with: url) != nil
                }
            }
            responder = r.next
        }
        return false
    }

    func openApp(scheme: String) {
        // 日本語のURLは使えないので、パーセントエンコーディングを適用する
        guard let encoded = scheme.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encoded) else {
            debug("無効なschemeです", scheme, scheme.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? scheme)
            return
        }
        self.openURL(url)
    }
}
