//
//  LiveConversionSettingView.swift
//  MainApp
//
//  Created by ensan on 2022/09/15.
//  Copyright © 2022 ensan. All rights reserved.
//

import AzooKeyUtils
import SwiftUI

struct LiveConversionSettingView: View {
    private static let strength: [AutomaticCompletionStrengthKey.Value] = [.disabled, .weak, .normal, .strong, .ultrastrong]
    @State private var setting: SettingUpdater<AutomaticCompletionStrengthKey>

    @MainActor init() {
        self._setting = .init(initialValue: .init())
    }

    var body: some View {
        Form {
            Section {
                BoolSettingView(.liveConversion)
            }
            Section(header: Text("自動確定")) {
                Text("自動確定を使うと長い文章を打っているときに候補の選択がしやすくなります。")
                Picker("自動確定の速さ", selection: $setting.value) {
                    Text("しない").tag(Self.strength[0])
                    Text("ゆっくり").tag(Self.strength[1])
                    Text("普通").tag(Self.strength[2])
                    Text("少し速い").tag(Self.strength[3])
                    Text("速い").tag(Self.strength[4])
                }
            }
            .onAppear {
                setting.reload()
            }
        }.navigationBarTitle(Text("ライブ変換の設定"), displayMode: .inline)
    }
}
