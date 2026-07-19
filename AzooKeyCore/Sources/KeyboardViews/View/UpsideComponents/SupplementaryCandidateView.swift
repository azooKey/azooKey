import SwiftUI

@MainActor
struct SupplementaryCandidateView<Extension: ApplicationSpecificKeyboardViewExtension>: View {
    @Environment(Extension.Theme.self) private var theme
    @Environment(\.userActionManager) private var action
    @EnvironmentObject private var variableStates: VariableStates

    private var candidates: [ResultData] {
        Array(variableStates.resultModel.supplementaryCandidates)
    }

    private var buttonHeight: CGFloat {
        Design.keyboardBarHeight(
            interfaceHeight: variableStates.interfaceSize.height,
            context: variableStates.layoutContext
        ) * 0.6
    }

    private var horizontalSpacing: CGFloat { 12 }

    var body: some View {
        Group {
            if candidates.isEmpty {
                EmptyView()
            } else if candidates.count == 1, let candidate = candidates.first {
                HStack {
                    Spacer(minLength: 0)
                    candidateContent(for: candidate)
                    Spacer(minLength: 0)
                }
            } else {
                HStack(spacing: horizontalSpacing) {
                    ForEach(candidates) { candidate in
                        HStack {
                            Spacer(minLength: 0)
                            candidateContent(for: candidate)
                            Spacer(minLength: 0)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    @ViewBuilder
    private func candidateContent(for data: ResultData) -> some View {
        switch data.candidate.label {
        case .text(let value):
            if data.candidate.inputable {
                Button {
                    KeyboardFeedback<Extension>.click()
                    pressed(candidate: data.candidate)
                } label: {
                    Text(
                        Design.fonts.forceJapaneseFont(
                            text: value,
                            theme: theme,
                            userSizePrefrerence: Extension.SettingProvider.resultViewFontSize
                        )
                    )
                }
                .buttonStyle(ResultButtonStyle<Extension>(height: buttonHeight))
                .contextMenu {
                    ResultContextMenuView(
                        candidate: data.candidate,
                        displayResetLearningButton: Extension.SettingProvider.canResetLearningForCandidate,
                        index: data.id
                    )
                }
            } else {
                Text(
                    Design.fonts.forceJapaneseFont(
                        text: value,
                        theme: theme,
                        userSizePrefrerence: Extension.SettingProvider.resultViewFontSize
                    )
                )
                .underline(true, color: .accentColor)
            }
        case .systemImage(let name, let accessibilityLabel):
            Button {
                KeyboardFeedback<Extension>.click()
                pressed(candidate: data.candidate)
            } label: {
                Image(systemName: name)
                    .font(Design.fonts.resultViewFont(theme: theme, userSizePrefrerence: Extension.SettingProvider.resultViewFontSize))
                    .accessibilityLabel(accessibilityLabel ?? name)
            }
            .buttonStyle(ResultButtonStyle<Extension>(height: buttonHeight))
        }
    }

    private func pressed(candidate: any ResultViewItemData) {
        self.action.notifyComplete(candidate, variableStates: variableStates)
    }
}
