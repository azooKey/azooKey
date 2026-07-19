//
//  MemoryResetSetting.swift
//  MainApp
//
//  Created by ensan on 2020/11/24.
//  Copyright © 2020 ensan. All rights reserved.
//

import AzooKeyUtils
import SwiftUI

struct MemoryResetSettingItemView: View {
    @State private var showAlert = false

    var body: some View {
        Button("学習のリセット") {
            self.showAlert = true
        }
        .foregroundStyle(.red)
        .alert("学習履歴をリセットします。よろしいですか？", isPresented: $showAlert) {
            Button("キャンセル", role: .cancel) {
                self.showAlert = false
            }
            Button("リセットする", role: .destructive) {
                MemoryResetCondition.set(value: .need)
                self.showAlert = false
            }
        } message: {
            Text("この操作は取り消せません。")
        }
    }
}
