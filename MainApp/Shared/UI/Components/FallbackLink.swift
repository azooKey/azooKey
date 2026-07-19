//
//  FallbackLink.swift
//  MainApp
//
//  Created by ensan on 2020/11/19.
//  Copyright © 2020 ensan. All rights reserved.
//

import SwiftUI

struct FallbackLink: View {
    @State private var showAlert = false
    private let title: LocalizedStringKey
    private let url: URL
    private let icon: Icon
    enum Icon {
        case link
        case mail
        var systemImage: String {
            switch self {
            case .link: return "arrow.up.forward.square"
            case .mail: return "envelope"
            }
        }
    }

    init(_ title: LocalizedStringKey, destination: String, icon: Icon = .link) {
        self.title = title
        self.url = URL(string: destination)!
        self.icon = icon
    }

    init(_ title: LocalizedStringKey, destination: URL, icon: Icon = .link) {
        self.title = title
        self.url = destination
        self.icon = icon
    }

    init(verbatim title: String, destination: String, icon: Icon = .link) {
        self.title = LocalizedStringKey("\(title)")
        self.url = URL(string: destination)!
        self.icon = icon
    }

    var body: some View {
        Button {
            // 外部ブラウザでURLを開く
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                self.showAlert = true
            }
        } label: {
            Label(title, systemImage: icon.systemImage)
        }
        .alert("ブラウザを開けませんでした", isPresented: $showAlert) {
            Button("OK") {
                UIPasteboard.general.string = url.absoluteString
                self.showAlert = false
            }
        } message: {
            Text("URLをコピーします。")
        }
    }
}
