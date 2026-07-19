//
//  LargeButtonStyle.swift
//  LargeButtonStyle
//
//  Created by ensan on 2021/07/23.
//  Copyright © 2021 ensan. All rights reserved.
//

import SwiftUI

struct LargeButtonStyle<S: ShapeStyle>: ButtonStyle {
    private let backgroundStyle: S

    init(backgroundStyle: S) {
        self.backgroundStyle = backgroundStyle
    }

    init(backgroundColor: Color) where S == Color {
        self.backgroundStyle = backgroundColor
    }

    @ViewBuilder func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .font(.body.bold())
            .padding()
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundStyle)
            }
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}
