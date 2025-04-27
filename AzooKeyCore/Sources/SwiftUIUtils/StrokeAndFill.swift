//
//  StrokeAndFill.swift
//  azooKey
//
//  Created by ensan on 2021/02/26.
//  Copyright © 2021 ensan. All rights reserved.
//

import Foundation
import SwiftUI

public extension Shape {
    @ViewBuilder
    func strokeAndFill(fillContent: some ShapeStyle, strokeContent: some ShapeStyle, lineWidth: CGFloat) -> some View {
        if #available(iOS 17, *) {
            self
                .fill(fillContent)
                .stroke(strokeContent, lineWidth: lineWidth)
        } else {
            ZStack {
                self.fill(fillContent)
                self.stroke(strokeContent, lineWidth: lineWidth)
            }
        }
    }
}
