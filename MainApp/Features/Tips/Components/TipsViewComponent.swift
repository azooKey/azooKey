//
//  TipsViewComponent.swift
//  MainApp
//
//  Created by ensan on 2020/11/19.
//  Copyright © 2020 ensan. All rights reserved.
//

import SwiftUI
import SwiftUIUtils

struct TipsContentView<Content: View>: View {
    private let content: () -> Content
    private let title: LocalizedStringKey

    init(_ title: LocalizedStringKey, @ViewBuilder _ content: @escaping () -> Content) {
        self.content = content
        self.title = title
    }

    var body: some View {
        VStack {
            Form {
                self.content()
            }.navigationBarTitle(Text(self.title), displayMode: .inline)
        }
    }
}

struct TipsContentParagraph<Content: View>: View {
    private let content: () -> Content
    private let style: Font.TextStyle

    init(style: Font.TextStyle = .body, @ViewBuilder _ content: @escaping () -> Content) {
        self.style = style
        self.content = content
    }

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                self.content()
            }
            .font(.system(style))
            .multilineTextAlignment(.leading)
        }
    }
}

struct TipsImage: View {
    private let resource: ImageResource

    init(_ resource: ImageResource) {
        self.resource = resource
    }

    var body: some View {
        CenterAlignedView {
            Image(self.resource)
                .resizable()
                .scaledToFit()
                .cornerRadius(2)
                .frame(maxWidth: MainAppDesign.imageMaximumWidth)
        }
    }
}
