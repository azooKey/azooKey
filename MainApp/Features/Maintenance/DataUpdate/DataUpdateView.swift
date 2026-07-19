//
//  DataUpdateView.swift
//  MainApp
//
//  Created by ensan on 2021/01/29.
//  Copyright © 2021 ensan. All rights reserved.
//

import AzooKeyUtils
import KeyboardViews
import SwiftUI
import func SwiftUtils.debug

struct DataUpdateView: View {

    private let id: MessageIdentifier
    @Binding private var manager: MessageManager<MessageIdentifier>
    private let process: () -> Void

    init(id: MessageIdentifier, manager: Binding<MessageManager<MessageIdentifier>>, process: @escaping () -> Void) {
        self.id = id
        self._manager = manager
        self.process = process
    }

    @State private var done = false

    var body: some View {
        ZStack {
            Color.white
            if done {
                VStack {
                    Text("\(systemImage: "checkmark.seal")完了しました")
                        .font(.title)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                manager.done(id)
                            }
                        }
                        .padding()
                    Button("閉じる") {
                        manager.done(id)
                    }
                    .padding()
                }
            } else {
                ProgressView("データの更新処理中です")
                    .task {
                        do {
                            process()
                            // 更新処理が短くても何が起こったかわかりやすいよう、1秒間余分に待つ
                            try await Task.sleep(nanoseconds: 1_000_000_000)
                            self.done = true
                        } catch {
                            debug(error)
                        }
                    }
            }
        }
    }
}
