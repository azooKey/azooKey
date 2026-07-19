import AzooKeyUtils
import CustardKit
import KeyboardViews
import SwiftUI
import SwiftUIUtils

struct CustardKeyLongpressItem: Identifiable, Hashable {
    let id: UUID
    let index: Int
}

struct CustardKeyLabelEditorSection: View {
    @Binding var selection: CustardKeyLabelSelection
    @Binding var labelText: String
    @Binding var labelImageName: String
    @Binding var labelMain: String
    @Binding var labelSub: String
    @Binding var labelDirections: CustardKeyDirectionalLabel
    @Binding var pressActions: [CodableActionData]
    let supportsAuto: Bool
    let showHelp: Bool

    var body: some View {
        Section {
            Picker("ラベルの種類", selection: $selection) {
                if supportsAuto {
                    Text("自動").tag(CustardKeyLabelSelection.auto)
                }
                Text("テキスト").tag(CustardKeyLabelSelection.text)
                Text("システムアイコン").tag(CustardKeyLabelSelection.systemImage)
                Text("メインとサブ").tag(CustardKeyLabelSelection.mainAndSub)
                Text("メインと4方向").tag(CustardKeyLabelSelection.mainAndDirections)
            }
            .onChange(of: pressActions) { _, actions in
                if supportsAuto, selection == .auto {
                    labelText = CustardInterfaceKeyEditingService.inputText(in: actions) ?? ""
                }
            }
            switch selection {
            case .auto:
                EmptyView()
            case .text:
                labelField(title: "ラベル", help: "キーに表示される文字を設定します。", text: $labelText)
            case .systemImage:
                SystemIconPicker(icon: $labelImageName)
            case .mainAndSub:
                labelField(title: "メイン", help: "大きく表示される文字を設定します。", text: $labelMain)
                labelField(title: "サブ", help: "小さく表示される文字を設定します。", text: $labelSub)
            case .mainAndDirections:
                labelField(title: "メイン", help: "中心に表示される文字を設定します。", text: $labelMain)
                labelField(title: "左", help: "左に表示される文字を設定します。", text: $labelDirections.left.wrapped())
                labelField(title: "上", help: "上に表示される文字を設定します。", text: $labelDirections.top.wrapped())
                labelField(title: "右", help: "右に表示される文字を設定します。", text: $labelDirections.right.wrapped())
                labelField(title: "下", help: "下に表示される文字を設定します。", text: $labelDirections.bottom.wrapped())
            }
        }
    }

    private func labelField(
        title: LocalizedStringKey,
        help: LocalizedStringKey,
        text: Binding<String>
    ) -> some View {
        HStack {
            Text(title)
            if showHelp {
                HelpAlertButton(title: title, explanation: help)
            }
            TextField(title, text: text)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.done)
        }
    }
}

struct CustardKeyPressActionSection: View {
    @Binding var actions: [CodableActionData]

    var body: some View {
        Section(footer: Text("キーを押したときの動作をより詳しく設定します。")) {
            NavigationLink("アクションを編集する") {
                CodableActionDataEditor(
                    $actions,
                    availableCustards: CustardManager.load().availableCustards
                )
            }
            .foregroundStyle(.accentColor)
        }
    }
}

struct CustardKeyLongpressActionSection: View {
    @Binding var action: CodableLongpressActionData
    let warning: LocalizedStringKey?

    var body: some View {
        Section(footer: Text("キーを長押ししたときの動作をより詳しく設定します。")) {
            NavigationLink("長押しアクションを編集する") {
                CodableLongpressActionDataEditor(
                    $action,
                    availableCustards: CustardManager.load().availableCustards
                )
            }
            .foregroundStyle(.accentColor)
            if let warning {
                Text(warning)
                    .font(.footnote)
                    .foregroundStyle(.orange)
            }
        }
    }
}

struct CustardKeyDropDelegate: DropDelegate {
    let onMove: () -> Void

    func performDrop(info: DropInfo) -> Bool {
        true
    }

    func dropEntered(info: DropInfo) {
        withAnimation(.default) {
            onMove()
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}
