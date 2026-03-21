import SwiftUI

@MainActor
struct MoteRuntimeView<Extension: ApplicationSpecificKeyboardViewExtension>: View {
    @Environment(Extension.Theme.self) private var theme
    @Environment(\.userActionManager) private var action
    @EnvironmentObject private var variableStates: VariableStates

    private var runtime: MoteRuntimeState {
        variableStates.moteRuntime
    }

    private var screen: MoteRuntimeScreen {
        runtime.screen
    }

    private var currentQuestion: MoteAskUserQuestion? {
        runtime.currentQuestion
    }

    private var chatContext: MoteChatContextInput {
        .init(
            leftText: variableStates.surroundingText.leftSideText,
            centerText: variableStates.surroundingText.centerText,
            rightText: variableStates.surroundingText.rightSideText
        )
    }

    var body: some View {
        VStack(spacing: 8) {
            content
            Divider()
            bottomBar
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(theme.backgroundColor.color.opacity(0.98))
    }

    @ViewBuilder
    private var content: some View {
        switch screen {
        case .keyboard:
            Text("mote+AI を押して質問フローを開始")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        case .loading:
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text("AIが候補を準備中です")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case .askUser:
            askUserPanel
        case .stage:
            stagePanel
        case .fullText:
            fullTextPanel
        case .fallback:
            fallbackPanel
        }
    }

    private var askUserPanel: some View {
        VStack(spacing: 8) {
            if let question = currentQuestion {
                Text("Step \(runtime.currentQuestionIndex + 1)/3")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(question.text)
                    .font(.callout)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 6) {
                    ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                        Button {
                            runtime.selectAskUserOption(option.value)
                        } label: {
                            Text("\(index + 1). \(option.label)")
                                .font(.footnote)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                        .background(theme.resultBackgroundColor.color)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            } else {
                Text("質問を準備中...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var stagePanel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(runtime.generatedChips.enumerated()), id: \.offset) { _, chip in
                    Button {
                        action.registerAction(.insertMainDisplay(chip), variableStates: variableStates)
                        runtime.recordChipTap(chip)
                    } label: {
                        Text(chip)
                            .font(.footnote)
                            .lineLimit(1)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    .background(theme.resultBackgroundColor.color)
                    .clipShape(Capsule())
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var fullTextPanel: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(Array(runtime.generatedChips.enumerated()), id: \.offset) { index, chip in
                    Button {
                        action.registerAction(.insertMainDisplay(chip), variableStates: variableStates)
                        runtime.recordChipTap(chip)
                        runtime.returnToStageFromFullTextSelection()
                    } label: {
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(chip)
                                .font(.footnote)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    .background(theme.resultBackgroundColor.color)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var fallbackPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("AI提案の取得に失敗しました")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(runtime.fallbackMessage ?? "通信状態を確認して再試行してください。")
                .font(.footnote)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button("再試行") {
                runtime.retryFromFallback(chatContext: chatContext)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(theme.resultBackgroundColor.color)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 8) {
            tabButton(title: "mote+AI", tab: .moteAI)
            tabButton(title: "キーボード", tab: .keyboard)
            tabButton(title: "全文表示", tab: .fullText, disabled: !runtime.canOpenFullText)
        }
    }

    private func tabButton(title: String, tab: MoteBottomTab, disabled: Bool = false) -> some View {
        let isSelected = runtime.selectedBottomTab == tab
        return Button {
            let result = runtime.handleBottomTabTap(tab, chatContext: chatContext)
            if result == .closeUpside {
                action.registerAction(.setUpsideComponent(nil), variableStates: variableStates)
            }
        } label: {
            Text(title)
                .font(.caption2)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .foregroundStyle(isSelected ? theme.resultTextColor.color : .secondary)
                .background(isSelected ? theme.resultBackgroundColor.color : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.4 : 1)
    }
}
