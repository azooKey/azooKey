//
//  EnableAzooKeyViewComponent.swift
//  MainApp
//
//  Created by ensan on 2020/11/18.
//  Copyright © 2020 ensan. All rights reserved.
//

import SwiftUI
import SwiftUIUtils
import struct KeyboardViews.AzooKeyIcon

struct EnableAzooKeyViewHeader: View {
    private let text: LocalizedStringKey
    init(_ text: LocalizedStringKey) {
        self.text = text
    }

    var body: some View {
        CenterAlignedView {
            HStack {
                AzooKeyIcon(fontSize: 30, relativeTo: .title)
                Text(text)
                    .font(.title.bold())
            }
            .multilineTextAlignment(.leading)
            .padding(.vertical)
        }
    }
}

struct EnableAzooKeyViewText: View {
    private let text: LocalizedStringKey
    private let systemName: String
    init(_ text: LocalizedStringKey, with systemName: String) {
        self.text = text
        self.systemName = systemName
    }

    var body: some View {
        HStack {
            Image(systemName: systemName)
            Text(text)
        }
        .lineLimit(nil)
        .fixedSize(horizontal: false, vertical: true)
        .multilineTextAlignment(.leading)
    }
}

struct EnableAzooKeyViewButton: View {
    enum Style {
        case emphasized, destructive
    }
    private let text: LocalizedStringKey
    private let systemName: String?
    private let style: Style
    private let action: () -> Void

    init(_ text: LocalizedStringKey, systemName: String? = nil, style: Style = .emphasized, action: @escaping () -> Void) {
        self.text = text
        self.systemName = systemName
        self.style = style
        self.action = action
    }

    var body: some View {
        switch style {
        case .emphasized:
            Button(action: action) {
                if let systemName {
                    Label(text, systemImage: systemName)
                } else {
                    Text(text)
                }
            }
            .buttonStyle(LargeButtonStyle(backgroundColor: .blue))
            .foregroundStyle(.white)
        case .destructive:
            Button(action: action) {
                if let systemName {
                    Label(text, systemImage: systemName)
                } else {
                    Text(text)
                }
            }
            .foregroundStyle(.red)
        }
    }
}

struct EnableAzooKeyViewImage: View {
    private let resource: ImageResource
    init(_ resource: ImageResource) {
        self.resource = resource
    }

    var body: some View {
        Image(resource)
            .resizable()
            .scaledToFit()
            .cornerRadius(2)
            .frame(maxWidth: MainAppDesign.imageMaximumWidth)
    }
}
