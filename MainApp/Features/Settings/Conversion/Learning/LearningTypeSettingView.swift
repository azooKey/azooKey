//
//  LearningTypeSettingItemView.swift
//  MainApp
//
//  Created by ensan on 2020/11/09.
//  Copyright © 2020 ensan. All rights reserved.
//

import AzooKeyUtils
import SwiftUI
import enum KanaKanjiConverterModule.LearningType

struct LearningTypeSettingView: View {
    @State private var setting: SettingUpdater<LearningTypeSetting>

    @MainActor init() {
        self._setting = .init(initialValue: .init())
    }

    var body: some View {
        LabeledContent(LearningTypeSetting.title) {
            Picker(selection: $setting.value, label: Text("")) {
                ForEach(0 ..< LearningType.allCases.count, id: \.self) { i in
                    Text(LearningType.allCases[i].string).tag(LearningType.allCases[i])
                }
            }
            .onAppear {
                setting.reload()
            }
            .frame(maxWidth: .infinity)
        }
    }
}
