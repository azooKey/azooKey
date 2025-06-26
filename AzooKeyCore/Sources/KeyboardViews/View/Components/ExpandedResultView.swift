//
//  ExpandedResultView.swift
//  Keyboard
//
//  Created by ensan on 2020/09/05.
//  Copyright © 2020 ensan. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
struct ExpandedResultView<Extension: ApplicationSpecificKeyboardViewExtension>: View {
    @EnvironmentObject private var variableStates: VariableStates
    @Binding private var isResultViewExpanded: Bool

    private var splitedResults: [SplitedResultData] {
        Self.registerResults(results: variableStates.resultModel.results, interfaceWidth: variableStates.interfaceSize.width)
    }
    private var buttonWidth: CGFloat {
        Design.keyboardBarHeight(interfaceHeight: variableStates.interfaceSize.height, orientation: variableStates.keyboardOrientation) * 0.5
    }
    private var buttonHeight: CGFloat {
        Design.keyboardBarHeight(interfaceHeight: variableStates.interfaceSize.height, orientation: variableStates.keyboardOrientation) * 0.6
    }

    @Environment(Extension.Theme.self) private var theme
    @Environment(\.userActionManager) private var action

    init(isResultViewExpanded: Binding<Bool>) {
        self._isResultViewExpanded = isResultViewExpanded
    }

    var body: some View {
        VStack {
            HStack(alignment: .center) {
                Spacer()
                    .frame(height: 18)
                // 候補をしまうボタン
                Button {
                    self.collapse()
                } label: {
                    ZStack {
                        Color(white: 1, opacity: 0.001)
                            .frame(width: buttonWidth)
                        Image(systemName: "chevron.up")
                            .font(Design.fonts.iconImageFont(keyViewFontSizePreference: Extension.SettingProvider.keyViewFontSize, theme: theme))
                            .frame(height: 18)
                    }
                }
                .buttonStyle(ResultButtonStyle<Extension>(height: buttonHeight))
                .padding(.trailing, 10)
            }
            .padding(.top, 10)
            ScrollView {
                LazyVStack(alignment: .leading) {
                    ForEach(splitedResults, id: \.id) {results in
                        Divider()
                        HStack {
                            ForEach(results.results, id: \.id) {datum in
                                Button {
                                    self.pressed(data: datum)
                                } label: {
                                    Text(
                                        Design.fonts.forceJapaneseFont(text: datum.candidate.text)
                                    )
                                }
                                .buttonStyle(ResultButtonStyle<Extension>(height: 18))
                                .contextMenu {
                                    ResultContextMenuView(candidate: datum.candidate, displayResetLearningButton: Extension.SettingProvider.canResetLearningForCandidate)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 3)
                .padding(.leading, 15)
            }
        }
        .frame(height: variableStates.interfaceSize.height, alignment: .bottom)
    }

    private func pressed(data: ResultData) {
        self.action.notifyComplete(data.candidate, variableStates: variableStates)
        self.collapse()
    }

    private func collapse() {
        isResultViewExpanded = false
    }

    private static func registerResults(results: [ResultData], interfaceWidth: CGFloat) -> [SplitedResultData] {
        var curSum: CGFloat = .zero
        var splited: [SplitedResultData] = []
        var curResult: [ResultData] = []
        let font = UIFont.systemFont(ofSize: Design.fonts.resultViewFontSize(userPrefrerence: Extension.SettingProvider.resultViewFontSize) + 1)
        results.forEach {[unowned font] datum in
            let width = datum.candidate.text.size(withAttributes: [.font: font]).width + 20
            if (curSum + width) < interfaceWidth {
                curResult.append(datum)
                curSum += width
            } else {
                splited.append(SplitedResultData(id: splited.count, results: curResult))
                curSum = width
                curResult = [datum]
            }
        }
        splited.append(SplitedResultData(id: splited.count, results: curResult))
        return splited
    }

}

private struct SplitedResultData: Identifiable {
    let id: Int
    let results: [ResultData]
}
