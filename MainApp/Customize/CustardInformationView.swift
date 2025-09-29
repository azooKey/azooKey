//
//  CustardInformationView.swift
//  MainApp
//
//  Created by ensan on 2021/02/23.
//  Copyright © 2021 ensan. All rights reserved.
//

import AzooKeyUtils
import CustardKit
import Foundation
import KeyboardViews
import SwiftUI
import SwiftUIUtils
import SwiftUtils

extension Custard {
    var userMadeTenKeyCustard: UserMadeGridFitCustard? {
        guard self.interface.keyStyle == .tenkeyStyle else {
            return nil
        }
        guard case let .gridFit(layout) = self.interface.keyLayout else {
            return nil
        }
        var keys: [KeyPosition: UserMadeKeyData] = [:]
        // empty keysは「キー情報のない位置」とする
        var emptyKeys = Set<KeyPosition>()
        for (position, key) in self.interface.keys {
            guard case let .gridFit(value) = position else {
                // エラーでもいいかもしれない
                continue
            }
            guard value.width > 0 && value.height > 0 else {
                continue
            }
            keys[.gridFit(x: value.x, y: value.y)] = .init(model: key, width: value.width, height: value.height)
            // 削除を反映する
            // empty keysには消えるやつだけ残っていて欲しい
            for px in value.x ..< value.x + value.width {
                for py in value.y ..< value.y + value.height {
                    if px == value.x && py == value.y {
                        continue
                    }
                    emptyKeys.update(with: .gridFit(x: px, y: py))
                }
            }
        }
        return UserMadeGridFitCustard(
            tabName: self.identifier,
            rowCount: layout.rowCount.description,
            columnCount: layout.columnCount.description,
            inputStyle: self.input_style,
            language: self.language,
            keys: keys,
            emptyKeys: emptyKeys,
            addTabBarAutomatically: true
        )
    }
}

fileprivate extension CustardLanguage {
    var label: LocalizedStringKey {
        switch self {
        case .en_US:
            return "英語"
        case .ja_JP:
            return "日本語"
        case .el_GR:
            return "ギリシャ語"
        case .undefined:
            return "指定なし"
        case .none:
            return "変換なし"
        }
    }
}

fileprivate extension CustardInputStyle {
    var label: LocalizedStringKey {
        switch self {
        case .direct:
            return "ダイレクト"
        case .roman2kana:
            return "ローマ字かな入力"
        }
    }
}

fileprivate extension CustardInternalMetaData.Origin {
    var description: LocalizedStringKey {
        switch self {
        case .userMade:
            return "このアプリで作成"
        case .imported:
            return "読み込んだデータ"
        }
    }
}

private struct ExportedCustardData {
    let data: Data
    let fileIdentifier: String
}

private final class ShareURL {
    private(set) var url: URL?

    func setURL(_ url: URL?) {
        if let url {
            self.url = url
        }
    }
}

struct CustardInformationView: View {
    private let initialCustard: Custard
    @Binding private var path: [CustomizeTabView.Path]
    @State private var showActivityView = false
    @State private var exportedData = ShareURL()
    @State private var added = false
    @State private var copied = false
    @EnvironmentObject private var appStates: MainAppStates

    @AppStorage("is_first_time_use_custard_share_link_v2.4.2") private var isFirstTimeUseCustardShareLink: Bool = true
    @State private var uploadTargetCustard: IdentifiableWrapper<Custard, String>?

    struct CustardShareLinkState {
        var processing = false
        var result: Result<URL, CustardShareHelper.ShareError>?
    }

    @State private var shareLinkState = CustardShareLinkState()

    struct CustardShareImage: Identifiable {
        var id = UUID()
        var image: UIImage
        var url: URL
    }

    @State private var shareImage: CustardShareImage?

    init(custard: Custard, path: Binding<[CustomizeTabView.Path]> = .constant([])) {
        self.initialCustard = custard
        self._path = path
    }

    private var custard: Custard {
        (try? appStates.custardManager.custard(identifier: initialCustard.identifier)) ?? initialCustard
    }

    private var keyboardPreview: some View {
        KeyboardPreview(scale: 0.7, defaultTab: .custard(custard))
    }

    var body: some View {
        Form {
            let custard = custard
            CenterAlignedView {
                keyboardPreview
            }
            LabeledContent("タブ名", value: custard.metadata.display_name)
            LabeledContent("識別子") {
                Text(verbatim: custard.identifier).monospaced()
            }
            LabeledContent("言語") {
                Text(custard.language.label)
            }
            switch custard.language {
            case .en_US:
                if appStates.englishLayout == .custard(custard.identifier) {
                    Text("英語のデフォルトタブに設定されています")
                } else {
                    Button("このタブを英語のデフォルトに設定") {
                        EnglishKeyboardLayout.set(newValue: .custard(custard.identifier))
                        appStates.englishLayout = .custard(custard.identifier)
                    }
                }
            case .ja_JP:
                if appStates.japaneseLayout == .custard(custard.identifier) {
                    Text("日本語のデフォルトタブに設定されています")
                } else {
                    Button("このタブを日本語のデフォルトに設定") {
                        JapaneseKeyboardLayout.set(newValue: .custard(custard.identifier))
                        appStates.japaneseLayout = .custard(custard.identifier)
                    }
                }
            case .el_GR, .undefined, .none:
                EmptyView()
            }
            LabeledContent("入力方式") {
                Text(custard.input_style.label)
            }
            if let metadata = appStates.custardManager.metadata[custard.identifier] {
                LabeledContent("由来") {
                    Text(metadata.origin.description)
                }

                if metadata.origin == .userMade,
                   let userdata = try? appStates.custardManager.userMadeCustardData(identifier: custard.identifier) {
                    switch userdata {
                    case let .gridScroll(value):
                        NavigationLink("編集する") {
                            EditingScrollCustardView(manager: $appStates.custardManager, editingItem: value, path: $path)
                        }
                        .foregroundStyle(.accentColor)
                    case let .tenkey(value):
                        NavigationLink("編集する") {
                            EditingGridFitCustardView(manager: $appStates.custardManager, editingItem: value, path: $path)
                        }
                        .foregroundStyle(.accentColor)
                    }
                } else if let editingItem = custard.userMadeTenKeyCustard {
                    NavigationLink("編集する") {
                        EditingGridFitCustardView(manager: $appStates.custardManager, editingItem: editingItem, path: $path)
                    }
                    .foregroundStyle(.accentColor)
                }
            }
            if added || appStates.custardManager.checkTabExistInTabBar(tab: .custom(custard.identifier)) {
                Text("タブバーに追加済み")
            } else {
                Button("タブバーに追加") {
                    do {
                        try appStates.custardManager.addTabBar(item: TabBarItem(label: .text(custard.metadata.display_name), pinned: false, actions: [.moveTab(.custom(custard.identifier))]))
                        added = true
                    } catch {
                        debug(error)
                    }
                }
            }
            Button("ファイルを共有") {
                guard let encoded = try? JSONEncoder().encode(custard) else {
                    debug("書き出しに失敗")
                    return
                }
                // tmpディレクトリを取得
                let directory = FileManager.default.temporaryDirectory
                let path = directory.appendingPathComponent("\(custard.identifier).json")
                do {
                    // 書き出してpathをセット
                    try encoded.write(to: path, options: .atomicWrite)
                    exportedData.setURL(path)
                    showActivityView = true
                } catch {
                    debug(error.localizedDescription)
                    return
                }
            }
            Section(footer: Text("共有用リンクは30日間アクセスがない場合に失効します")) {
                if let result = shareLinkState.result {
                    switch result {
                    case .success(let url):
                        Button("リンクをコピー", systemImage: copied ? "checkmark" : "doc.on.doc") {
                            UIPasteboard.general.string = url.absoluteString
                            MainAppFeedback.success()
                            self.copied = true
                            Task {
                                try await Task.sleep(nanoseconds: 3_000_000_000)
                                self.copied = false
                            }
                        }
                        .disabled(copied)
                        Text(verbatim: url.absoluteString)
                            .monospaced()
                        Button("リンクをシェア", systemImage: "square.and.arrow.up") {
                            let renderer = ImageRenderer(content: keyboardPreview)
                            renderer.scale = 3.0
                            if let image = renderer.uiImage {
                                self.shareImage = .init(image: image, url: url)
                            }
                        }
                    case .failure(let failure):
                        Label(failure.errorDescription ?? "共有に失敗しました", systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                    }
                } else {
                    HStack {
                        Button("共有用リンクを発行") {
                            if self.isFirstTimeUseCustardShareLink {
                                // 初回のみ、確認画面を表示する
                                self.uploadTargetCustard = IdentifiableWrapper(custard, id: \.identifier)
                            } else {
                                self.uploadCustard(custard)
                            }
                        }
                        .disabled(self.shareLinkState.processing)
                        if shareLinkState.processing {
                            ProgressView()
                        }
                    }
                    .sheet(item: $uploadTargetCustard) { custard in
                        UploadConfirmationView {
                            self.uploadCustard(custard.value)
                            self.isFirstTimeUseCustardShareLink = false
                        } dismiss: {
                            self.uploadTargetCustard = nil
                        }
                        .presentationDetents([.medium])
                    }
                }
            }
        }
        .navigationBarTitle(Text("カスタムタブの情報"), displayMode: .inline)
        .task {
            self.shareLinkState.processing = true
            let link = self.appStates.custardManager.loadCustardShareLink(custardId: custard.identifier)
            // linkの有効性をチェックする
            if let link, let url = URL(string: link), await CustardShareHelper.verifyShareLink(url) {
                self.shareLinkState = .init(result: .success(url))
            }
            self.shareLinkState.processing = false
        }
        .sheet(isPresented: self.$showActivityView, content: {
            ActivityView(
                activityItems: [exportedData.url].compactMap {$0},
                applicationActivities: nil
            )
        })
        .sheet(
            item: $shareImage,
            content: { item in
                ActivityView(
                    activityItems: [
                        TextActivityItem(
                            "azooKeyでカスタムタブを作りました！",
                            hashtags: ["#azooKey"],
                            links: [item.url.absoluteString]
                        ),
                        ImageActivityItem(item.image),
                    ],
                    applicationActivities: nil
                )
            }
        )
    }

    private func uploadCustard(_ custard: Custard) {
        self.shareLinkState.processing = true
        Task {
            do {
                let (url, deleteToken) = try await CustardShareHelper.upload(custard)
                self.shareLinkState.result = .success(url)
                self.appStates.custardManager.saveCustardShareLink(custardId: custard.identifier, shareLink: url.absoluteString)
                // Save deletion token securely in Keychain
                KeychainHelper.saveDeleteToken(deleteToken, for: custard.identifier)
            } catch let error as CustardShareHelper.ShareError {
                self.shareLinkState.result = .failure(error)
            }
            self.shareLinkState.processing = false
        }
    }
}

private struct UploadConfirmationView: View {
    var onConfirmation: () -> Void
    var dismiss: () -> Void

    @State private var acceptTermsOfService = false

    var body: some View {
        Form {
            Section {
                Text("共有リンクを発行すると、不特定の第三者があなたのカスタムタブを使えるようになります。")
                Text("共有リンクは、最後のダウンロードから30日程度で失効します。")
            }
            Section(footer: Text("[\(systemImage: "arrow.up.forward.square")利用規約](https://azookey.com/TermsOfService)を確認してください")) {
                Toggle("利用規約に同意します", isOn: $acceptTermsOfService)
                    .toggleStyle(CheckboxToggleStyle())
            }
            Section {
                Button("キャンセル", systemImage: "xmark", role: .cancel) {
                    self.dismiss()
                }
                Button("共有用リンクを発行", systemImage: "square.and.arrow.up") {
                    self.onConfirmation()
                    self.dismiss()
                }
                .bold(self.acceptTermsOfService)
                .disabled(!self.acceptTermsOfService)
            }
        }
    }
}

private struct CheckboxToggleStyle: ToggleStyle {
    private func makeBodyCore(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            Label {
                configuration.label
            } icon: {
                Image(systemName: configuration.isOn ? "checkmark.square" : "square")
            }
        }
    }
    func makeBody(configuration: Configuration) -> some View {
        if #available(iOS 17, *) {
            self.makeBodyCore(configuration: configuration)
                .symbolEffect(.bounce, value: configuration.isOn)
        } else {
            self.makeBodyCore(configuration: configuration)
        }
    }
}

// MARK: - Keychain helper (simple wrapper)
private enum KeychainHelper {
    private static let service = "azooKey.CustardInformationView.CustardShare"

    /// Save or update the delete token in Keychain (Generic Password).
    static func saveDeleteToken(_ token: String, for id: String) {
        let account = "deleteToken_\(id)"
        guard let data = token.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]

        // Delete existing item if any, then add new one
        SecItemDelete(query as CFDictionary)

        var attrs = query
        attrs[kSecValueData as String] = data
        attrs[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(attrs as CFDictionary, nil)
    }

    /// Retrieve the delete token (if any) for a given custard ID.
    static func loadDeleteToken(for id: String) -> String? {
        let account = "deleteToken_\(id)"
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else { return nil }
        return token
    }
}

private struct IdentifiableWrapper<T, ID: Hashable>: Identifiable {
    init(_ value: T, id: @escaping (T) -> ID) {
        self.value = value
        self.getId = id
    }
    var value: T
    var getId: (T) -> ID
    var id: ID {
        getId(value)
    }
}
