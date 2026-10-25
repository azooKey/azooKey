import AzooKeyUtils
import KeyboardViews
import SwiftUI
import SwiftUIUtils

struct ContributionSettingsSection: View {
    var body: some View {
        Section(header: Text("フィードバック")) {
            NavigationLink("azooKeyの開発に協力") {
                ContributionDetailView()
            }
            NavigationLink("変換候補の追加") {
                ShareWordView()
            }
        }
    }
}

struct ContributionDetailView: View {
    @State private var reportEnabled = SettingUpdater<EnableWrongConversionReport>()
    @State private var frequency = SettingUpdater<WrongConversionReportFrequencySettingKey>()
    @State private var nickname = SettingUpdater<WrongConversionReportUserNicknameKey>()
    @State private var showConsentSheet = false
    @FocusState private var nicknameFocused: Bool

    private var requiresFullAccess: Bool {
        EnableWrongConversionReport.requireFullAccess && !SemiStaticStates.shared.hasFullAccess
    }

    private var reportToggleBinding: Binding<Bool> {
        Binding(
            get: { reportEnabled.value },
            set: { newValue in
                if newValue {
                    reportEnabled.value = true
                    showConsentSheet = true
                } else {
                    reportEnabled.value = false
                }
            }
        )
    }

    var body: some View {
        Form {
            Section {
                Toggle(isOn: reportToggleBinding.animation(.easeInOut)) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(EnableWrongConversionReport.title)
                            HelpAlertButton(title: EnableWrongConversionReport.title, explanation: EnableWrongConversionReport.explanation)
                            if EnableWrongConversionReport.requireFullAccess {
                                Image(systemName: "f.circle.fill")
                                    .foregroundStyle(.purple)
                            }
                        }
                        Text("誤変換レポートは第一候補ではない変換候補を選んだ場合にユーザの確認の上で送信することができます。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(.switch)
                .disabled(requiresFullAccess)

                if requiresFullAccess {
                    Text("この機能を利用するにはフルアクセスを有効にしてください。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section("設定") {
                Picker(WrongConversionReportFrequencySettingKey.title, selection: $frequency.value) {
                    ForEach(WrongConversionReportFrequencySettingKey.Value.allCases, id: \.self) { value in
                        Text(value.description).tag(value)
                    }
                }

                BoolSettingView(.wrongConversionIncludeContext)

                HStack {
                    Text("ニックネーム")
                    HelpAlertButton(title: "ニックネーム", explanation: "報告にニックネームを含めます。ユーザの識別のために用いられることがあります。")
                    TextField("ニックネーム", text: $nickname.value)
                        .textInputAutocapitalization(.none)
                        .textContentType(.nickname)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .focused($nicknameFocused)
                        .submitLabel(.done)
                }
            }
            .disabled(!reportEnabled.value)

            Section("注意事項") {
                Text("送信前に内容を確認するポップアップが表示されます。不要な情報は右スワイプで除外できます。")
                    .font(.footnote)
                Text("送信されたデータはかな漢字変換システムの改善等の目的で利用されます。")
                    .font(.footnote)
            }
        }
        .navigationTitle("azooKeyの開発に協力")
        .onAppear {
            frequency.reload()
            nickname.reload()
            reportEnabled.reload()
        }
        .sheet(isPresented: $showConsentSheet) {
            WrongConversionReportConsentSheet(
                onAgree: {
                    reportEnabled.value = true
                    showConsentSheet = false
                },
                onCancel: {
                    reportEnabled.value = false
                    showConsentSheet = false
                }
            )
        }
    }
}

private struct MockReportSuggestionView: View {
    @StateObject private var variableStates = VariableStates(
        interfaceWidth: UIScreen.main.bounds.width,
        orientation: MainAppDesign.keyboardOrientation,
        clipboardHistoryManagerConfig: ClipboardHistoryManagerConfig(),
        tabManagerConfig: TabManagerConfig(),
        userDefaults: UserDefaults.standard,
        sharedUserDefaults: UserDefaults.standard
    )
    var body: some View {
        ReportSuggestionView<AzooKeyKeyboardViewExtension>(content: .candidateRankingMismatch(top: .init(displayText: "間違い候補", rank: 0), selected: .init(displayText: "候補", rank: 2)))
            .environmentObject(variableStates)
            .disabled(true)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct WrongConversionReportConsentSheet: View {
    let onAgree: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("選択した候補や周辺文脈などの情報をサーバに送信し、azooKeyの変換精度改善に貢献することができます。")
                    Text("この機能をONにすると、キーボードの利用中に以下のような送信の提案が表示されるようになります。")
                    MockReportSuggestionView()
                    Text("勝手に情報が送信されることはありません。「報告」ボタンを押した際にのみ実際の送信が行われます。")
                    Text("設定からいつでも送信の提案を停止できます。")
                }
                .padding()
                Button("確認した", systemImage: "checkmark", action: onAgree)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.extraLarge)
                    .padding()
            }
            .navigationTitle("誤変換レポートについて")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("戻る", role: .cancel, action: onCancel)
                }
            }
        }
    }
}
