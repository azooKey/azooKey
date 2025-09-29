//
//  ManageCustardView.swift
//  MainApp
//
//  Created by ensan on 2021/02/22.
//  Copyright © 2021 ensan. All rights reserved.
//

import AzooKeyUtils
import CustardKit
import Foundation
import SwiftUI
import SwiftUIUtils
import SwiftUtils
import UniformTypeIdentifiers

private enum AlertType: Equatable {
    case overlapCustard(custard: Custard)
}

private struct CustardDownloaderState: Sendable {
    enum ImportError: Error {
        case invalidURL
        case invalidData
        case invalidFile

        var description: LocalizedStringKey {
            switch self {
            case .invalidURL:
                return "URLが間違っている可能性があります"
            case .invalidData:
                return "データが取得できませんでした"
            case .invalidFile:
                return "正しくない形式のファイルです"
            }
        }
    }

    enum ProcessState: Error {
        case none
        case getURL
        case getFile
        case processFile

        var description: LocalizedStringKey? {
            switch self {
            case .none: return nil
            case .getFile: return "ファイルを取得中"
            case .getURL: return "URLを取得中"
            case .processFile: return "ファイルを処理中"
            }
        }
    }

    var processState: ProcessState = .none
    var failureData: ImportError?
    var custards: [Custard]?

    mutating func reset() {
        self.processState = .none
        self.failureData = nil
        self.custards = nil
    }

    var isFinished: Bool {
        if let custards = self.custards {
            return custards.isEmpty
        }
        return true
    }

    mutating func finish(custard: Custard) {
        self.custards?.removeAll(where: {$0.identifier == custard.identifier})
    }

    mutating func process(data: Data) -> [Custard]? {
        self.processState = .processFile
        do {
            let custard = try JSONDecoder().decode(Custard.self, from: data)
            self.processState = .none
            return [custard]
        } catch {
            debug("ImportedCustardData process", error)
        }
        do {
            let custards = try JSONDecoder().decode([Custard].self, from: data)
            self.processState = .none
            return custards
        } catch {
            debug("ImportedCustardData process", error)
        }
        self.failureData = .invalidFile
        self.processState = .none
        return nil
    }

    func resolveURL(_ url: URL) -> URL {
        if url.host == "custard.azookey.com" {
            // 以下の形式にマッチする場合、/tab/<UUID>を/api/tab/<UUID>に置換
            // 例: https://custard.azookey.com/tab/XXXX → https://custard.azookey.com/api/tab/XXXX
            // /tab/<UUID>は将来的にhtml形式で描画される可能性があるため
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            if let path = components?.path, path.hasPrefix("/tab/") {
                components?.path = path.replacingOccurrences(of: "/tab/", with: "/api/tab/")
                if let newURL = components?.url {
                    return newURL
                }
            }
        }
        return url
    }

    mutating func validateURL(_ url: URL) -> Bool {
        self.processState = .getFile
        guard !url.absoluteString.hasPrefix("file:///") || url.startAccessingSecurityScopedResource() else {
            self.processState = .none
            self.failureData = .invalidURL
            return false
        }
        return true
    }

    mutating func failGetData(error: any Error) {
        debug("downloadAsync error", error)
        self.failureData = .invalidData
        self.processState = .none
    }
}

private struct WebCustardList: Codable {
    struct Item: Codable {
        var name: String
        var file: String
    }
    var last_update: String
    var custards: [Item]
}

@MainActor
struct ManageCustardView: View {
    @State private var downloaderState = CustardDownloaderState()
    @State private var urlString: String = ""
    @State private var showAlert = false
    @State private var alertType: AlertType?
    @State private var showDeleteAlert = false
    @State private var deletingCustardIdentifier: String = ""
    @State private var showRenameAlert = false
    @State private var renamingIdentifier: String = ""
    @State private var renamingName: String = ""
    @State private var showDuplicateNameAlert = false
    @Binding private var manager: CustardManager
    @Binding private var path: [CustomizeTabView.Path]
    @State private var webCustards: WebCustardList = .init(last_update: "", custards: [])
    @State private var showDocumentPicker = false
    @State private var selectedDocument: Data = Data()
    @State private var addTabBar = true
    init(manager: Binding<CustardManager>, path: Binding<[CustomizeTabView.Path]>) {
        self._manager = manager
        self._path = path
    }

    var body: some View {
        Form {
            Section(header: Text("一覧")) {
                if manager.availableCustards.isEmpty {
                    Text("カスタムタブがまだありません")
                } else {
                    List {
                        ForEach(manager.availableCustards, id: \.self) {identifier in
                            if let custard = self.getCustard(identifier: identifier) {
                                NavigationLink(identifier) {
                                    CustardInformationView(custard: custard, path: $path)
                                }
                                .contextMenu {
                                    if let metadata = manager.metadata[custard.identifier],
                                       metadata.origin == .userMade,
                                       let userdata = try? manager.userMadeCustardData(identifier: custard.identifier) {
                                        switch userdata {
                                        case let .gridScroll(value):
                                            NavigationLink("編集") {
                                                EditingScrollCustardView(manager: $manager, editingItem: value, path: $path)
                                            }
                                        case let .tenkey(value):
                                            NavigationLink("編集") {
                                                EditingGridFitCustardView(manager: $manager, editingItem: value, path: $path)
                                            }
                                        }
                                        Divider()
                                    } else if let editingItem = custard.userMadeTenKeyCustard {
                                        NavigationLink("編集") {
                                            EditingGridFitCustardView(manager: $manager, editingItem: editingItem, path: $path)
                                        }
                                        Divider()
                                    }
                                    Button("複製", systemImage: "square.on.square") {
                                        do {
                                            try manager.duplicateCustard(identifier: custard.identifier)
                                        } catch {
                                            debug(error.localizedDescription)
                                        }
                                    }
                                    Button("名前を変更", systemImage: "pencil") {
                                        renamingIdentifier = custard.identifier
                                        renamingName = custard.metadata.display_name
                                        showRenameAlert = true
                                    }
                                    Divider()
                                    Button("削除", systemImage: "trash", role: .destructive) {
                                        self.deletingCustardIdentifier = identifier
                                        self.showDeleteAlert = true
                                        manager.removeCustard(identifier: identifier)
                                    }
                                }
                            } else if let custardFileURL = self.getCustardFile(identifier: identifier) {
                                ShareLink(item: custardFileURL) {
                                    Label("読み込みに失敗したカスタムタブ「\(identifier)」を書き出す", systemImage: "square.and.arrow.up")
                                }
                            }
                        }
                        .onDelete(perform: {self.delete(at: $0)})
                    }
                }
            }
            .onAppear(perform: {self.loadWebCustard()})

            Section(header: Text("作る")) {
                Text("登録したい文字や単語を順番に書いていくだけで定型文入力に便利なタブを作成できます。")
                NavigationLink("定型文タブを作る") {
                    EditingScrollCustardView(manager: $manager, path: $path)
                }
                .foregroundStyle(.accentColor)
                Text("日本語/英語入力用のタブをフルカスタマイズできます。")
                NavigationLink("カスタムタブを作る") {
                    EditingGridFitCustardView(manager: $manager, path: $path)
                }
                .foregroundStyle(.accentColor)
            }
            if let custards = self.downloaderState.custards {
                ForEach(custards, id: \.identifier) {custard in
                    Section(header: Text("読み込んだタブ")) {
                        Text("「\(custard.metadata.display_name)(\(custard.identifier))」の読み込みに成功しました")
                        CenterAlignedView {
                            KeyboardPreview(scale: 0.7, defaultTab: .custard(custard))
                        }
                        Toggle("タブバーに追加", isOn: $addTabBar)
                        Button("保存") {
                            if manager.availableCustards.contains(custard.identifier) {
                                self.showAlert = true
                                self.alertType = .overlapCustard(custard: custard)
                            } else {
                                self.saveCustard(custard: custard)
                            }
                        }
                    }
                }
                Button("キャンセル") {
                    urlString = ""
                    selectedDocument = Data()
                    self.downloaderState.reset()
                }
                .foregroundStyle(.red)

            } else {
                Section(header: Text("おすすめ")) {
                    ForEach(webCustards.custards, id: \.file) {item in
                        HStack {
                            Button {
                                Task {
                                    await self.downloadAsync(from: "https://azookey.netlify.app/static/custard/\(item.file)")
                                }
                            } label: {
                                Image(systemName: "square.and.arrow.down")
                                    .foregroundStyle(.accentColor)
                                    .padding(.horizontal, 5)
                            }
                            Text(verbatim: item.name)
                        }
                    }
                }

                Section(header: Text("読み込む")) {
                    Button("iCloudから読み込む") {
                        showDocumentPicker = true
                    }
                }
                Section(header: Text("URLから読み込む"), footer: Text("\(systemImage: "doc.on.clipboard")を長押しでペースト")) {
                    HStack {
                        TextField("URLを入力", text: $urlString)
                            .submitLabel(.go)
                            .onSubmit {
                                Task {
                                    await self.downloadAsync(from: urlString)
                                }
                            }
                        Divider()
                        PasteLongPressButton($urlString)
                            .padding(.horizontal, 5)
                    }
                    Button("読み込む") {
                        Task {
                            await self.downloadAsync(from: urlString)
                        }
                    }
                }
                if let text = self.downloaderState.processState.description {
                    ProgressView(text)
                }
                if let failure = self.downloaderState.failureData {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                        Text(failure.description).foregroundStyle(.red)
                    }
                }
                Section {
                    Text("カスタムタブをファイルとして外部で作成し、azooKeyに読み込むことができます。より高機能なタブの作成が可能です。詳しくは以下をご覧ください。")
                    FallbackLink("カスタムタブファイルの作り方", destination: "https://github.com/azooKey/CustardKit")
                }
            }
        }
        .navigationBarTitle(Text("カスタムタブの管理"), displayMode: .inline)
        .alert("注意", isPresented: $showAlert, presenting: alertType) { alertType in
            switch alertType {
            case let .overlapCustard(custard: custard):
                Button("上書き", role: .destructive) {
                    self.saveCustard(custard: custard)
                }
                Button("キャンセル", role: .cancel) {
                    self.showAlert = false
                }
            }
        } message: { alertType in
            switch alertType {
            case let .overlapCustard(custard: custard):
                Text("識別子\(custard.identifier)を持つカスタムタブが既に登録されています。上書きしますか？")
            }
        }
        .alert("このタブを開くタブバーアイテムも削除しますか？", isPresented: $showDeleteAlert) {
            Button("削除する", role: .destructive) {
                manager.availableTabBars.forEach { tabBarIdentifier in
                    do {
                        let tabBar = try manager.tabbar(identifier: tabBarIdentifier)
                        let filteredItems = tabBar.items.filter { tabItem in
                            tabItem.actions.contains { action in
                                if case .moveTab(.custom(let value)) = action, value == deletingCustardIdentifier {
                                    return false
                                }
                                return true
                            }
                        }
                        if filteredItems.count != tabBar.items.count {
                            var newTabBar = tabBar
                            newTabBar.items = filteredItems
                            try manager.saveTabBarData(tabBarData: newTabBar)
                        }
                    } catch {
                        debug("Failed to get tabbar for identifier: \(tabBarIdentifier)", error)
                    }
                }
            }
            Button("削除しない", role: .cancel) {
                self.showDeleteAlert = false
            }
        } message: {
            Text("\(deletingCustardIdentifier)を開くアクションを含むアイテム全てが削除されます。")
        }
        .alert("名前を変更", isPresented: $showRenameAlert) {
            TextField("新しい名前", text: $renamingName)
            Button("保存") {
                do {
                    try manager.renameCustard(from: renamingIdentifier, to: renamingName)
                } catch CustardManagerError.duplicateIdentifier {
                    showDuplicateNameAlert = true
                } catch {
                    debug(error)
                }
            }
            Button("キャンセル", role: .cancel) {}
        }
        .alert("名前が重複しています", isPresented: $showDuplicateNameAlert) {
            Button("OK", role: .cancel) {}
        }
        .fileImporter(isPresented: $showDocumentPicker, allowedContentTypes: ["txt", "custard", "json"].compactMap {UTType(filenameExtension: $0, conformingTo: .text)}) {result in
            switch result {
            case let .success(url):
                if url.startAccessingSecurityScopedResource() {
                    Task {
                        await self.downloadAsync(from: url)
                    }
                } else {
                    debug("error: 不正なURL)")
                }
            case let .failure(error):
                debug(error)
            }
        }
    }

    func downloadAsync(from urlString: String) async {
        self.downloaderState.processState = .getURL
        guard let url = URL(string: urlString) else {
            self.downloaderState.failureData = .invalidURL
            self.downloaderState.processState = .none
            return
        }
        await self.downloadAsync(from: url)
    }

    func downloadAsync(from url: URL) async {
        let url = self.downloaderState.resolveURL(url)
        guard self.downloaderState.validateURL(url) else {
            return
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            self.downloaderState.custards = self.downloaderState.process(data: data)
        } catch {
            self.downloaderState.failGetData(error: error)
        }
    }

    private func saveCustard(custard: Custard) {
        do {
            try manager.saveCustard(custard: custard, metadata: .init(origin: .imported), updateTabBar: addTabBar)
            self.downloaderState.finish(custard: custard)
            MainAppFeedback.success()
            if self.downloaderState.isFinished {
                self.downloaderState.reset()
                urlString = ""
                selectedDocument = Data()
            }
        } catch {
            debug("saveCustard", error)
        }
    }

    private func getCustard(identifier: String) -> Custard? {
        do {
            let custard = try manager.custard(identifier: identifier)
            return custard
        } catch {
            debug(error)
            return nil
        }
    }

    private func getCustardFile(identifier: String) -> URL? {
        do {
            let url = try manager.custardFileIfExist(identifier: identifier)
            return url
        } catch {
            debug(error)
            return nil
        }
    }

    private func delete(at offsets: IndexSet) {
        let identifiers = offsets.map {manager.availableCustards[$0]}
        identifiers.forEach {
            manager.removeCustard(identifier: $0)
            self.deletingCustardIdentifier = $0
            self.showDeleteAlert = true
        }
    }

    private func loadWebCustard() {
        guard let url = URL(string: "https://azooKey.netlify.app/static/custard/all") else {
            return
        }
        Task {
            let result = try await URLSession.shared.data(from: url).0
            let decoder = JSONDecoder()
            guard let decodedResponse = try? decoder.decode(WebCustardList.self, from: result) else {
                debug("Failed to load https://azooKey.netlify.app/static/custard/all")
                return
            }
            self.webCustards = decodedResponse
        }
    }
}

// FIXME: ファイルを保存もキャンセルもしない状態で2つ目のファイルを読み込むとエラーになる
@MainActor
struct URLImportCustardView: View {
    @State private var downloaderState = CustardDownloaderState()
    @State private var showAlert = false
    @State private var alertType: AlertType?
    @Binding private var manager: CustardManager
    @Binding private var url: URL?
    @State private var addTabBar = true

    init(manager: Binding<CustardManager>, url: Binding<URL?>) {
        self._manager = manager
        self._url = url
    }

    var body: some View {
        Form {
            if let custards = self.downloaderState.custards {
                ForEach(custards, id: \.identifier) {custard in
                    Section(header: Text("読み込んだタブ")) {
                        Text("「\(custard.metadata.display_name)(\(custard.identifier))」の読み込みに成功しました")
                        CenterAlignedView {
                            KeyboardPreview(scale: 0.7, defaultTab: .custard(custard))
                        }
                        Toggle("タブバーに追加", isOn: $addTabBar)
                        Button("保存") {
                            if manager.availableCustards.contains(custard.identifier) {
                                self.showAlert = true
                                self.alertType = .overlapCustard(custard: custard)
                            } else {
                                self.saveCustard(custard: custard)
                            }
                        }
                    }
                }
                Button("キャンセル") {
                    self.downloaderState.reset()
                    url = nil
                }
                .foregroundStyle(.red)
            } else if let text = self.downloaderState.processState.description {
                Section(header: Text("読み込み中")) {
                    ProgressView(text)
                    Button("閉じる") {
                        self.downloaderState.reset()
                        url = nil
                    }
                    .foregroundStyle(.accentColor)
                }
            } else {
                Section(header: Text("読み込み失敗")) {
                    if let failure = self.downloaderState.failureData {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                            Text(failure.description).foregroundStyle(.red)
                        }
                    }
                    Button("閉じる") {
                        self.downloaderState.reset()
                        url = nil
                    }
                    .foregroundStyle(.accentColor)
                }
            }
        }
        .task {
            if let url {
                debug("URLImportCustardView", url)
                self.downloaderState.reset()
                await self.downloadAsync(from: url)
            }
        }
        .alert("注意", isPresented: $showAlert, presenting: alertType) { alertType in
            switch alertType {
            case let .overlapCustard(custard: custard):
                Button("上書き", role: .destructive) {
                    self.saveCustard(custard: custard)
                }
                Button("キャンセル", role: .cancel) {
                    self.showAlert = false
                }
            }
        } message: { alertType in
            switch alertType {
            case let .overlapCustard(custard: custard):
                Text("識別子\(custard.identifier)を持つカスタムタブが既に登録されています。上書きしますか？")
            }
        }
    }

    private func saveCustard(custard: Custard) {
        do {
            try manager.saveCustard(custard: custard, metadata: .init(origin: .imported), updateTabBar: addTabBar)
            self.downloaderState.finish(custard: custard)
            MainAppFeedback.success()
            if self.downloaderState.isFinished {
                self.downloaderState.reset()
                url = nil
            }
        } catch {
            debug("saveCustard", error)
        }
    }

    private func downloadAsync(from url: URL) async {
        let url = self.downloaderState.resolveURL(url)
        guard self.downloaderState.validateURL(url) else {
            return
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            self.downloaderState.custards = self.downloaderState.process(data: data)
        } catch {
            self.downloaderState.failGetData(error: error)
        }
    }
}
