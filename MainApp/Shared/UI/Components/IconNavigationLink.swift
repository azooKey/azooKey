//
//  IconNavigationLink.swift
//  azooKey
//
//  Created by miwa on 2023/11/11.
//  Copyright © 2023 DevEn3. All rights reserved.
//

import SwiftUI

struct IconNavigationLink<Destination: View, Style: ShapeStyle>: View {
    init(_ titleKey: LocalizedStringKey, systemImage: String, imageColor: Color? = nil, destination: @escaping () -> Destination) where Color == Style {
        self.titleKey = titleKey
        self.systemImage = systemImage
        self.style = imageColor ?? .primary
        self.destination = destination
    }
    init(_ titleKey: LocalizedStringKey, systemImage: String, style: Style, destination: @escaping () -> Destination) {
        self.titleKey = titleKey
        self.systemImage = systemImage
        self.style = style
        self.destination = destination
    }

    var titleKey: LocalizedStringKey
    var systemImage: String
    var style: Style
    var destination: () -> Destination

    var body: some View {
        NavigationLink(destination: destination) {
            Label(
                title: {
                    Text(titleKey)
                },
                icon: {
                    Image(systemName: systemImage)
                        .foregroundStyle(style)
                        .font(.caption)
                }
            )
        }
    }
}
