import AzooKeyUtils
import KeyboardViews
import SwiftUI

struct DuoFlickSettingView: View {
    @State private var enabled = SettingUpdater<EnableDuoFlick>()
    @State private var panelWidth = SettingUpdater<DuoFlickPanelWidth>()
    @State private var centerGap = SettingUpdater<DuoFlickCenterGap>()
    @State private var testText = ""

    var body: some View {
        Form {
            Section {
                Toggle("Duoフリックを使う", isOn: $enabled.value)
                    .accessibilityIdentifier("duo-flick-enabled")
            } footer: {
                Text("見開き画面の左右に、同じ日本語12キーを配置します。幅600pt未満では通常の配列に戻ります。")
            }

            Section("見開きプレビュー") {
                GeometryReader { geometry in
                    KeyboardPreview(
                        sizing: .render(
                            resolvedSize: CGSize(width: 760, height: DuoFlickLayout.keyboardHeight + Design.keyboardScreenBottomPadding),
                            scale: geometry.size.width / 760
                        ),
                        defaultTab: .flick_hira
                    )
                    .id("\(enabled.value)-\(panelWidth.value)-\(centerGap.value)")
                    .allowsHitTesting(false)
                    .accessibilityLabel("左右に同じ12キーを配置した見開きプレビュー")
                }
                .aspectRatio(760 / (DuoFlickLayout.keyboardHeight + Design.keyboardScreenBottomPadding), contentMode: .fit)
                .listRowInsets(EdgeInsets(top: 12, leading: 6, bottom: 12, trailing: 6))
            }

            Section {
                Toggle("画面幅いっぱいに広げる", isOn: Binding(
                    get: { panelWidth.value == 0 },
                    set: { panelWidth.value = $0 ? 0 : 400 }
                ))
                if panelWidth.value > 0 {
                    LabeledContent("片側の最大幅", value: "\(Int(panelWidth.value)) pt")
                    Slider(value: $panelWidth.value, in: 250...700, step: 5)
                        .accessibilityLabel("片側の最大幅")
                }
                LabeledContent("中央の最小間隔", value: "\(Int(centerGap.value)) pt")
                Slider(value: $centerGap.value, in: 0...240, step: 10)
                    .accessibilityLabel("中央の最小間隔")
                Button("標準の幅と間隔に戻す") {
                    panelWidth.value = DuoFlickPanelWidth.defaultValue
                    centerGap.value = DuoFlickCenterGap.defaultValue
                }
            } footer: {
                Text("標準では左右のパネルを画面幅いっぱいに広げ、中央に16ptの間隔を確保します。手動の幅指定もできます。")
            }
            .disabled(!enabled.value)

            Section("試し入力") {
                TextField("ここをタップして入力", text: $testText, axis: .vertical)
                    .lineLimit(2...4)
                    .accessibilityIdentifier("duo-flick-test-input")
                Text("地球儀キーでazooKeyを選び、画面を見開きにしてお試しください。かな・英字・数字の切り替えと変換候補は左右で共通です。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Duoフリック")
        .onAppear {
            DuoFlickLayoutDefaults.migrateIfNeeded()
            enabled.reload()
            panelWidth.reload()
            centerGap.reload()
        }
    }
}
