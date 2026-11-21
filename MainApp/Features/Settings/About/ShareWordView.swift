//
//  ShareWordView.swift
//  azooKey
//
//  Created by ensan on 2023/04/15.
//  Copyright © 2023 ensan. All rights reserved.
//

import AzooKeyUtils
import SwiftUI

struct ShareWordView: View {
    @State private var word = ""
    @State private var ruby = ""
    @State private var note = ""
    @State private var sending = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            if sending {
                Section {
                    HStack {
                        Text("申請中です")
                        ProgressView()
                    }
                }
            }
            Section(footer: Text("\(systemImage: "doc.on.clipboard")を長押しでペースト")) {
                HStack {
                    TextField("単語", text: $word)
                    Divider()
                    PasteLongPressButton($word)
                        .padding(.horizontal, 5)
                }
                HStack {
                    TextField("読み", text: $ruby)
                    Divider()
                    PasteLongPressButton($ruby)
                        .padding(.horizontal, 5)
                }
            }

            HStack {
                TextField("備考", text: $note, prompt: Text("補足情報があれば記入してください"), axis: .vertical)
                Divider()
                PasteLongPressButton($note)
                    .padding(.horizontal, 5)
            }

            Section(footer: Text("azooKeyの開発チームに単語を提案します。採用されると、他のユーザも変換候補として使えるようになります。\n個人情報を含む単語は送信しないでください。")) {
                Button("申請する") {
                    Task {
                        self.sending = true
                        _ = await SharedStore.sendSharedWord(word: word, ruby: ruby.toKatakana(), note: note, options: [])
                        self.sending = false
                        await MainActor.run {
                            dismiss()
                        }
                    }
                }
                .disabled(word.isEmpty && ruby.isEmpty)
            }
        }
        .multilineTextAlignment(.leading)
        .navigationBarTitle(Text("azooKeyに単語の追加を提案"), displayMode: .inline)

    }
}
