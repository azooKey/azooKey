//
//  ContactView.swift
//  MainApp
//
//  Created by ensan on 2020/11/19.
//  Copyright © 2020 ensan. All rights reserved.
//

import SwiftUI

struct ContactView: View {
    var body: some View {
        Form {
            Section(footer: Text("お問い合わせ内容を選んでください。ブラウザでGoogle Formが開きます。")) {
                FallbackLink("不具合報告", destination: URL(string: "https://forms.gle/kkpBLbBySwGNDLzH9")!)
                FallbackLink("機能の改善・追加", destination: URL(string: "https://forms.gle/4PrdgaC2mZEaYed76")!)
            }
            Section {
                NavigationLink("変換候補の追加") {
                    ShareWordView()
                }
            }
            Section(footer: Text("その他の質問・連絡などはメールでお寄せください")) {
                FallbackLink("その他の質問・連絡など", destination: URL(string: "mailto:azooKey.dev@gmail.com")!, icon: .mail)
            }
        }
        .multilineTextAlignment(.leading)
        .navigationBarTitle(Text("お問い合わせ"), displayMode: .inline)

    }
}
