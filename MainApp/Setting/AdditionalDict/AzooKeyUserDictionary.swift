//
//  AzooKeyUserDictionary.swift
//  MainApp
//
//  Created by ensan on 2020/12/05.
//  Copyright © 2020 ensan. All rights reserved.
//

import AzooKeyUtils
import Foundation
import KeyboardViews
import SwiftUI
import struct KanaKanjiConverterModule.Candidate
import struct KanaKanjiConverterModule.TemplateData
import struct KanaKanjiConverterModule.DateTemplateLiteral

import SwiftUIUtils
import SwiftUtils

private final class UserDictManagerVariables: ObservableObject {
    @Published var items: [UserDictionaryData] = [
        UserDictionaryData(ruby: "あずーきー", word: "azooKey", isVerb: false, isPersonName: true, isPlaceName: false, id: 0)
    ]
    @Published var mode: Mode = .list
    @Published var selectedItem: EditableUserDictionaryData?
    @Published var templates = TemplateData.load()

    enum Mode {
        case list, details
    }

    init() {
        if let userDictionary = UserDictionary.get() {
            self.items = userDictionary.items
        }
    }

    @MainActor func save() {
        TemplateData.save(templates)

        let userDictionary = UserDictionary(items: self.items)
        userDictionary.save()

        AdditionalDictManager().userDictUpdate()
    }
}

struct AzooKeyUserDictionaryView: View {
    @ObservedObject private var variables: UserDictManagerVariables = UserDictManagerVariables()
    @EnvironmentObject private var appStates: MainAppStates

    var body: some View {
        UserDictionaryDataListView(variables: variables)
            .onDisappear {
                appStates.requestReviewManager.shouldTryRequestReview = true
            }
    }
}

@MainActor
private struct UserDictionaryDataListView: View {
    private let exceptionKey = "その他"

    @ObservedObject private var variables: UserDictManagerVariables
    @State private var editMode = EditMode.inactive

    init(variables: UserDictManagerVariables) {
        self.variables = variables
    }

    var body: some View {
        Form {
            Section {
                Text("変換候補に単語を追加することができます。iOSの標準のユーザ辞書とは異なります。")
            }
            let currentGroupedItems: [String: [UserDictionaryData]] = Dictionary(grouping: variables.items, by: {$0.ruby.first.map {String($0)} ?? exceptionKey}).mapValues {$0.sorted {$0.id < $1.id}}
            let keys = currentGroupedItems.keys
            let currentKeys: [String] = keys.contains(exceptionKey) ? [exceptionKey] + keys.filter {$0 != exceptionKey}.sorted() : keys.sorted()
            List {
                ForEach(currentKeys, id: \.self) {key in
                    Section(header: Text(key)) {
                        ForEach(currentGroupedItems[key]!) {data in
                            NavigationLink {
                                UserDictionaryDataEditor(data.makeEditableData(), variables: variables)
                            } label: {
                                LabeledContent {
                                    Text(data.ruby)
                                } label: {
                                    if data.isTemplateMode, let lit = data.formatLiteral, !lit.isEmpty {
                                        Text(Candidate.parseTemplate(lit))
                                            .monospacedDigit()
                                    } else {
                                        Text(data.word)
                                    }
                                }
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    variables.items.removeAll(where: {$0.id == data.id})
                                } label: {
                                    Label("削除", systemImage: "trash")
                                }
                            }
                        }
                        .onDelete(perform: self.delete(section: key))
                    }.environment(\.editMode, $editMode)
                }
            }
            #if DEBUG
            Section("デバッグ") {
                Button("マイグレーション状態をリセット") {
                    UserDictionaryMigrationRunner.resetFlagForDebug()
                }
                .foregroundStyle(.red)
            }
            #endif
        }
        .onAppear {
            variables.templates = TemplateData.load()
        }
        .navigationBarTitle(Text("ユーザ辞書"), displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    let id = variables.items.map { $0.id }.max()
                    UserDictionaryDataEditor(
                        UserDictionaryData.emptyData(id: (id ?? -1) + 1).makeEditableData(),
                        variables: variables
                    )
                } label: {
                    Text("追加する")
                }
            }
        }
    }

    private func delete(section: String) -> (IndexSet) -> Void {
        {(offsets: IndexSet) in
            let indices: [Int]
            if section == exceptionKey {
                indices = variables.items.indices.filter {variables.items[$0].ruby.first == nil}
            } else {
                indices = variables.items.indices.filter {variables.items[$0].ruby.hasPrefix(section)}
            }
            let sortedIndices = indices.sorted {
                variables.items[$0].id < variables.items[$1].id
            }
            variables.items.remove(atOffsets: IndexSet(offsets.map {sortedIndices[$0]}))
            variables.save()
        }
    }
}

@MainActor
private struct UserDictionaryDataEditor: CancelableEditor {
    @ObservedObject private var item: EditableUserDictionaryData
    @ObservedObject private var variables: UserDictManagerVariables
    @Environment(\.dismiss) private var dismiss
    // 日付・時刻変換用のテンプレート編集一時領域
    @State private var templateLiteralData: TemplateData = TemplateData(template: DateTemplateLiteral.example.export(), name: "")

    // CancelableEditor Conformance
    typealias EditTarget = (EditableUserDictionaryData, [TemplateData])
    fileprivate let base: EditTarget

    init(_ item: EditableUserDictionaryData, variables: UserDictManagerVariables) {
        self.item = item
        self.variables = variables
        self.base = (item.copy(), variables.templates)
        if let literal = item.data.formatLiteral {
            self._templateLiteralData = State(initialValue: TemplateData(template: literal, name: ""))
        } else {
            self._templateLiteralData = State(initialValue: TemplateData(template: DateTemplateLiteral.example.export(), name: ""))
        }
    }

    @State private var shareThisWord = false
    @State private var showConfirmationDialogue = false
    @State private var sending = false
    @FocusState private var focusOnWordField: Bool?

    @ViewBuilder
    private var wordField: some View {
        if item.data.isTemplateMode {
            TimelineView(.periodic(from: Date(), by: 0.5)) { _ in
                Text(self.previewString())
                    .monospacedDigit()
            }
        } else {
            TextField("単語", text: $item.data.word)
                .padding(.vertical, 2)
                .focused($focusOnWordField, equals: true)
                .submitLabel(.done)
        }
    }

    var body: some View {
        Form {
            if sending {
                HStack {
                    Text("申請中です")
                    ProgressView()
                }
            }
            Section(header: Text("読みと単語"), footer: Text("\(systemImage: "doc.on.clipboard")を長押しでペースト")) {
                HStack {
                    wordField
                    if !item.data.isTemplateMode {
                        Divider()
                        PasteLongPressButton($item.data.word)
                            .padding(.horizontal, 5)
                    }
                }
                HStack {
                    TextField("読み", text: $item.data.ruby)
                        .padding(.vertical, 2)
                        .submitLabel(.done)
                    Divider()
                    PasteLongPressButton($item.data.ruby)
                        .padding(.horizontal, 5)
                }
                if let error = item.error {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                        Text(error.message)
                            .font(.caption)
                    }
                }
                if !item.data.isTemplateMode && (UserDictionaryMigrator.isUnsupportedLegacy(word: item.data.word) || UserDictionaryMigrator.isUnsupportedRandomWithAffixes(word: item.data.word, templates: variables.templates)) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                        Text("このテンプレートのサポートは廃止されました。エントリを削除してください。")
                            .font(.caption)
                    }
                }
            }
            Section(header: Text("詳細な設定")) {
                if item.neadVerbCheck() {
                    Toggle("「\(item.mizenkeiWord)(\(item.mizenkeiRuby))」と言える", isOn: $item.data.isVerb)
                        .disabled(item.data.isTemplateMode)
                }
                if !item.data.isTemplateMode {
                    Toggle("人・動物・会社などの名前である", isOn: $item.data.isPersonName)
                    Toggle("場所・建物などの名前である", isOn: $item.data.isPlaceName)
                }
                Toggle("時刻・ランダム変換", isOn: $item.data.isTemplateMode)
                    .onChange(of: item.data.isTemplateMode) { (_, value) in
                        if value, item.data.formatLiteral == nil {
                            item.data.formatLiteral = DateTemplateLiteral.example.export()
                            templateLiteralData = TemplateData(template: item.data.formatLiteral!, name: "")
                        }
                    }
            }
            if item.data.isTemplateMode {
                TemplateEditorView($templateLiteralData) { template in
                    item.data.formatLiteral = template.literal.export()
                    templateLiteralData = template
                }
            }
            if !item.data.isTemplateMode,
               self.base.0.data.shared != true || (self.base.0.data != self.item.data) {
                Toggle(isOn: $shareThisWord) {
                    HStack {
                        Text("この単語をシェアする")
                        HelpAlertButton("この単語を他のユーザにも共有することを申請します。\n個人情報を含む単語は申請しないでください。")
                    }
                }
                .toggleStyle(.switch)
            }
        }
        .sheet(isPresented: $showConfirmationDialogue) {
            UserDictionaryShareConfirmationView(
                saveWithShareAction: { note in
                    Task {
                        // わずかな時間待機する
                        self.sending = true
                        let data = self.item.makeStableData()
                        let success = await self.sendSharedWord(data: data, note: note)
                        self.item.data.shared = success
                        try await Task.sleep(nanoseconds: 1_000_000)
                        self.saveAndDismiss()
                        self.sending = false
                    }
                },
                saveWithoutShareAction: self.saveAndDismiss
            )
            .padding()
            .padding(.horizontal)
            .interactiveDismissDisabled()
            .presentationDetents([.medium, .large])
            .disabled(self.sending)
            .presentationBackground(.thinMaterial)
        }
        .navigationTitle(Text("ユーザ辞書を編集"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
            leading: Button("キャンセル", action: cancel),
            trailing: Button("完了") {
                if item.error == nil {
                    if self.shareThisWord {
                        self.showConfirmationDialogue = true
                    } else {
                        self.saveAndDismiss()
                    }
                }
            }
        )
        .onDisappear(perform: self.save)
        .onEnterBackground { _ in
            self.save()
        }
    }

    private func previewString() -> String {
        if let literal = item.data.formatLiteral, !literal.isEmpty {
            return Candidate.parseTemplate(literal)
        }
        return item.data.word
    }

    private func saveAndDismiss() {
        self.save()
        dismiss()
        MainAppFeedback.success()
    }

    fileprivate func cancel() {
        item.reset(from: base.0)
        variables.templates = base.1
        dismiss()
    }

    @MainActor
    private func save() {
        if item.error == nil {
            if let itemIndex = variables.items.firstIndex(where: {$0.id == self.item.id}) {
                variables.items[itemIndex] = item.makeStableData()
            } else {
                variables.items.append(item.makeStableData())
            }
            variables.save()
        }
    }

    private func sendSharedWord(data: UserDictionaryData, note: String) async -> Bool {
        var options: [SharedStore.ShareThisWordOptions] = []
        if data.isPersonName {
            options.append(.人・動物・会社などの名前)
        }
        if data.isPlaceName {
            options.append(.場所・建物などの名前)
        }
        if data.isVerb {
            options.append(.五段活用)
        }

        return await SharedStore.sendSharedWord(word: data.word, ruby: data.ruby, note: note, options: options)
    }
}

private struct UserDictionaryShareConfirmationView: View {
    var saveWithShareAction: (String) -> Void
    var saveWithoutShareAction: () -> Void

    @State private var note: String = ""
    var body: some View {
        VStack {
            Label("単語をシェアします", systemImage: "exclamationmark.triangle")
                .font(.title2)
                .bold()
                .padding(.bottom)
            Text("シェアすると、不特定多数のユーザがこの単語を閲覧できます。個人情報を含む単語を絶対にシェアしないでください。")
                .font(.callout)
                .lineLimit(nil)
            TextField("備考", text: $note, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .padding(.vertical)

            var secondaryColor: AnyShapeStyle {
                if #available(iOS 17, *) {
                    AnyShapeStyle(.blue.secondary)
                } else {
                    AnyShapeStyle(.blue)
                }
            }
            Button("シェアせずに保存", role: .cancel) {
                self.saveWithoutShareAction()
            }
            .foregroundStyle(.white)
            .font(.headline)
            .fontWeight(.regular)
            .buttonStyle(LargeButtonStyle(backgroundStyle: secondaryColor))
            Button("シェアして保存") {
                self.saveWithShareAction(note)
            }
            .foregroundStyle(.white)
            .font(.headline)
            .buttonStyle(LargeButtonStyle(backgroundColor: .blue))
        }
    }
}
