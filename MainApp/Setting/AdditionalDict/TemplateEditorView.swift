import Foundation
import KanaKanjiConverterModule
import SwiftUI
import SwiftUIUtils
import SwiftUtils

struct TemplateEditorView: View {
    private let saveProcess: (TemplateData) -> Void
    @State private var editingTemplate: TemplateData

    init(_ template: Binding<TemplateData>, saveProcess: @escaping (TemplateData) -> Void) {
        debug("TemplateEditingView.init", template.wrappedValue)
        self._editingTemplate = State(initialValue: template.wrappedValue)
        self.saveProcess = saveProcess
    }

    @MainActor
    @ViewBuilder
    private var editorCore: some View {
        Picker(selection: $editingTemplate.type, label: Text("")) {
            Text("時刻").tag(TemplateLiteralType.date)
            Text("ランダム").tag(TemplateLiteralType.random)
        }
        .labelsHidden()
        .pickerStyle(.segmented)
        switch editingTemplate.type {
        case .date:
            DateTemplateLiteralSettingView($editingTemplate, onUpdate: saveProcess)
        case .random:
            RandomTemplateLiteralSettingView($editingTemplate, onUpdate: saveProcess)
        }
    }

    var body: some View {
        editorCore
            .onDisappear {
                saveProcess(editingTemplate)
            }
    }
}

struct RandomTemplateLiteralSettingView: View {
    private static let templateLiteralType = TemplateLiteralType.random
    private enum Error {
        case nan
        case stringIsNil
    }
    // リテラル
    @Binding private var template: TemplateData
    private let onUpdate: ((TemplateData) -> Void)?

    @State private var literal = RandomTemplateLiteral(value: .int(from: 1, to: 6))
    @State private var type: RandomTemplateLiteral.ValueType = .int

    @State private var intStringRange = (left: "1", right: "6")
    @State private var doubleStringRange = (left: "0", right: "1")
    @State private var stringsString: String = "グー,チョキ,パー"

    fileprivate init(_ template: Binding<TemplateData>, onUpdate: ((TemplateData) -> Void)? = nil) {
        self._template = template
        self.onUpdate = onUpdate
        if let template = template.wrappedValue.literal as? RandomTemplateLiteral {
            self._literal = State(initialValue: template)
            self._type = State(initialValue: template.value.type)
            switch template.value {
            case let .int(from: left, to: right):
                self._intStringRange = State(initialValue: ("\(left)", "\(right)"))
            case let .double(from: left, to: right):
                self._doubleStringRange = State(initialValue: ("\(left)", "\(right)"))
            case let .string(strings):
                self._stringsString = State(initialValue: strings.joined(separator: ","))
            }
        }
    }

    private func update() {
        if template.type != Self.templateLiteralType {
            return
        }
        switch self.type {
        case .int:
            guard let left = Int(intStringRange.left),
                  let right = Int(intStringRange.right) else {
                return
            }
            self.literal.value = .int(from: min(left, right), to: max(left, right))
        case .double:
            guard let left = Double(doubleStringRange.left),
                  let right = Double(doubleStringRange.right) else {
                return
            }
            self.literal.value = .double(from: min(left, right), to: max(left, right))
        case .string:
            let strings = stringsString.components(separatedBy: ",")
            self.literal.value = .string(strings)
        }
        self.template.literal = self.literal
        self.onUpdate?(self.template)
    }

    @ViewBuilder private func warning(_ type: Error) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
            switch type {
            case .nan:
                Text("値が無効です。有効な数値を入力してください")
            case .stringIsNil:
                Text("文字列が入っていません。最低一つは必要です")
            }
        }
    }

    var body: some View {
        Group {
            Section(header: Text("値の種類")) {
                Picker("値の種類", selection: $type) {
                    Text("整数").tag(RandomTemplateLiteral.ValueType.int)
                    Text("小数").tag(RandomTemplateLiteral.ValueType.double)
                    Text("文字列").tag(RandomTemplateLiteral.ValueType.string)
                }
                .onChange(of: type) { _, _ in
                    update()
                }
            }
            switch type {
            case .int:
                VStack {
                    HStack {
                        IntegerTextField("左端の値", text: $intStringRange.left)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                            .submitLabel(.done)
                            .onSubmit(update)
                        Text("から")
                    }
                    .onChange(of: intStringRange.left) { _, _ in
                        update()
                    }
                    if Int(intStringRange.left) == nil {
                        warning(.nan)
                    }
                }
                VStack {
                    HStack {
                        IntegerTextField("右端の値", text: $intStringRange.right)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                            .submitLabel(.done)
                            .onSubmit(update)
                        Text("まで")
                    }
                    .onChange(of: intStringRange.right) { _, _ in
                        update()
                    }
                    if Int(intStringRange.right) == nil {
                        warning(.nan)
                    }
                }
            case .double:
                VStack {
                    HStack {
                        TextField("左端の値", text: $doubleStringRange.left)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)
                            .submitLabel(.done)
                            .onSubmit(update)
                        Text("から")
                    }
                    .onChange(of: doubleStringRange.left) { _, _ in
                        update()
                    }
                    if Double(doubleStringRange.left) == nil {
                        warning(.nan)
                    }
                }
                VStack {
                    HStack {
                        TextField("右端の値", text: $doubleStringRange.right)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)
                            .submitLabel(.done)
                            .onSubmit(update)
                        Text("まで")
                    }
                    .onChange(of: doubleStringRange.right) { _, _ in
                        update()
                    }
                    if Double(doubleStringRange.right) == nil {
                        warning(.nan)
                    }
                }
            case .string:
                VStack {
                    HStack {
                        TextField("表示する値(カンマ区切り)", text: $stringsString)
                            .textFieldStyle(.roundedBorder)
                            .submitLabel(.done)
                            .onSubmit(update)
                    }
                    .onChange(of: stringsString) { _, _ in
                        update()
                    }
                    if stringsString.isEmpty {
                        warning(.stringIsNil)
                    }
                }
            }
        }
    }
}

struct DateTemplateLiteralSettingView: View {
    private static let templateLiteralType = TemplateLiteralType.date
    // リテラル
    @Binding private var template: TemplateData
    private let onUpdate: ((TemplateData) -> Void)?

    @State private var literal = DateTemplateLiteral.example
    // 選択されているテンプレート
    @State private var formatSelection = "yyyy年MM月dd日"
    // 表示用
    @State private var date: Date = Date()
    @State private var dateString: String = ""
    @State private var formatter: DateFormatter = DateFormatter()

    @MainActor
    fileprivate init(_ template: Binding<TemplateData>, onUpdate: ((TemplateData) -> Void)? = nil) {
        self._template = template
        self.onUpdate = onUpdate
        if let template = template.wrappedValue.literal as? DateTemplateLiteral {
            if template.language == DateTemplateLiteral.example.language,
               template.type == DateTemplateLiteral.example.type,
               template.delta == DateTemplateLiteral.example.delta,
               template.deltaUnit == DateTemplateLiteral.example.deltaUnit,
               ["yyyy年MM月dd日", "HH:mm", "yyyy/MM/dd"].contains(template.format) {
                var literal = DateTemplateLiteral.example
                literal.format = template.format
                self._literal = State(initialValue: literal)
                self._formatSelection = State(initialValue: template.format)
            } else {
                self._literal = State(initialValue: template)
                self._formatSelection = State(initialValue: "カスタム")
            }
        }

        if formatSelection == "カスタム" {
            self.formatter.dateFormat = literal.format
            self.formatter.locale = Locale(identifier: literal.language.identifier)
            self.formatter.calendar = Calendar(identifier: literal.type.identifier)
        } else {
            self.formatter.dateFormat = formatSelection
            self.formatter.locale = Locale(identifier: "ja_JP")
            self.formatter.calendar = Calendar(identifier: .gregorian)
        }
        self.update()
    }

    private static let yyyy年MM月dd日: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy年MM月dd日"
        f.locale = Locale(identifier: "ja_JP")
        f.calendar = Calendar(identifier: .gregorian)
        return f
    }()

    private static let HH_mm: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.locale = Locale(identifier: "ja_JP")
        f.calendar = Calendar(identifier: .gregorian)
        return f
    }()

    private static let yyyy_MM_dd: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy/MM/dd"
        f.locale = Locale(identifier: "ja_JP")
        f.calendar = Calendar(identifier: .gregorian)
        return f
    }()

    @MainActor
    private func update() {
        DispatchQueue.main.async {
            if formatSelection == "カスタム" {
                self.date = Date().advanced(by: (Double(literal.delta) ?? 0) * Double(literal.deltaUnit))
                self.template.literal = self.literal
            } else {
                self.date = Date()
                self.template.literal = DateTemplateLiteral(format: formatSelection, type: .western, language: .japanese, delta: "0", deltaUnit: 1)
            }
            self.onUpdate?(self.template)
        }
    }

    var body: some View {
        Group {
            Section(header: Text("書式の設定")) {
                VStack {
                    Picker("書式", selection: $formatSelection) {
                        Text(Self.yyyy年MM月dd日.string(from: date)).tag("yyyy年MM月dd日")
                        Text(Self.HH_mm.string(from: date)).tag("HH:mm")
                        Text(Self.yyyy_MM_dd.string(from: date)).tag("yyyy/MM/dd")
                        Text("カスタム").tag("カスタム")
                    }.onChange(of: formatSelection) { (_, value) in
                        if value != "カスタム" {
                            formatter.dateFormat = value
                            formatter.locale = Locale(identifier: "ja_JP")
                            formatter.calendar = Calendar(identifier: .gregorian)
                        } else {
                            formatter.dateFormat = literal.format
                            formatter.locale = Locale(identifier: literal.language.identifier)
                            formatter.calendar = Calendar(identifier: literal.type.identifier)
                        }
                        update()
                    }
                }
            }
            if formatSelection == "カスタム" {
                Section(header: Text("カスタム書式")) {
                    LabeledContent("書式") {
                        TextField("書式を入力", text: $literal.format)
                            .textFieldStyle(.roundedBorder)
                            .submitLabel(.done)
                    }
                    VStack {
                        LabeledContent("ズレ") {
                            HStack {
                                IntegerTextField("ズレ", text: $literal.delta, range: .min ... .max)
                                    .multilineTextAlignment(.trailing)
                                    .textFieldStyle(.roundedBorder)
                                    .submitLabel(.done)
                                Picker(selection: $literal.deltaUnit, label: Text("")) {
                                    Text("日").tag(60 * 60 * 24)
                                    Text("時間").tag(60 * 60)
                                    Text("分").tag(60)
                                    Text("秒").tag(1)
                                }
                            }
                        }
                        if Double(literal.delta) == nil {
                            Text("\(systemImage: "exclamationmark.triangle")値が無効です。有効な数値を入力してください")
                        }
                    }
                    Picker("暦の種類", selection: $literal.type) {
                        Text("西暦").tag(DateTemplateLiteral.CalendarType.western)
                        Text("和暦").tag(DateTemplateLiteral.CalendarType.japanese)
                    }
                    Picker("言語", selection: $literal.language) {
                        Text("日本語").tag(DateTemplateLiteral.Language.japanese)
                        Text("英語").tag(DateTemplateLiteral.Language.english)
                    }
                }
                .onChange(of: literal) { (_, value) in
                    formatter.dateFormat = value.format
                    formatter.locale = Locale(identifier: value.language.identifier)
                    formatter.calendar = Calendar(identifier: value.type.identifier)
                    update()
                }
                Section(header: Text("書式はyyyyMMddhhmmssフォーマットで記述します。詳しい記法はインターネット等で確認できます。")) {
                    FallbackLink("Web検索", destination: "https://www.google.com/search?q=yyyymmddhhmm")
                }
            }
        }
    }
}
