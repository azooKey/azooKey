//
//  QwertySuggestView.swift
//  Keyboard
//
//  Created by ensan on 2020/09/18.
//  Copyright © 2020 ensan. All rights reserved.
//

import Foundation
import SwiftUI
import SwiftUIUtils

enum VariationsViewDirection {
    case center, right, left

    var alignment: Alignment {
        switch self {
        case .center: return .center
        case .right: return .leading
        case .left: return .trailing
        }
    }

    var edge: Edge.Set {
        switch self {
        case .center: return []
        case .right: return .leading
        case .left: return .trailing
        }
    }

}

struct QwertySuggestView {
    @MainActor static func expandedPath(rdw: CGFloat, ldw: CGFloat, width: CGFloat, tabDesign: TabDependentDesign) -> some Shape {
        Path { path in
            path.move(to: CGPoint(x: 122, y: 281))
            path.addLine(to: CGPoint(x: 53, y: 281))
            path.addCurve(
                to: CGPoint(x: 33, y: 261),
                control1: CGPoint(x: 40, y: 281),
                control2: CGPoint(x: 33, y: 274)
            )
            path.addLine(to: CGPoint(x: 33, y: 173))
            path.addCurve(
                to: CGPoint(x: 26, y: 148),
                control1: CGPoint(x: 33, y: 164),
                control2: CGPoint(x: 32, y: 157)
            )
            path.addLine(to: CGPoint(x: 7 - ldw, y: 121))
            path.addCurve(
                to: CGPoint(x: 0 - ldw, y: 96),
                control1: CGPoint(x: 1 - ldw, y: 113),
                control2: CGPoint(x: 0 - ldw, y: 106)
            )
            path.addLine(to: CGPoint(x: 0 - ldw, y: 20))
            path.addCurve(
                to: CGPoint(x: 20 - ldw, y: 0),
                control1: CGPoint(x: 0 - ldw, y: 7),
                control2: CGPoint(x: 7 - ldw, y: 0)
            )
            path.addLine(to: CGPoint(x: 155 + rdw, y: 0))
            path.addCurve(
                to: CGPoint(x: 175 + rdw, y: 20),
                control1: CGPoint(x: 168 + rdw, y: 0),
                control2: CGPoint(x: 175 + rdw, y: 7)
            )
            path.addLine(to: CGPoint(x: 175 + rdw, y: 96))
            path.addCurve(
                to: CGPoint(x: 168 + rdw, y: 121),
                control1: CGPoint(x: 175 + rdw, y: 106),
                control2: CGPoint(x: 174 + rdw, y: 113)
            )
            path.addLine(to: CGPoint(x: 149, y: 148))
            path.addCurve(
                to: CGPoint(x: 142, y: 173),
                control1: CGPoint(x: 143, y: 156),
                control2: CGPoint(x: 142, y: 164)
            )
            path.addLine(to: CGPoint(x: 142, y: 261))
            path.addCurve(
                to: CGPoint(x: 122, y: 281),
                control1: CGPoint(x: 142, y: 274),
                control2: CGPoint(x: 135, y: 281)
            )
        }
        .offsetBy(dx: -175 / 2 + width / 2, dy: 0 )
        .scale(x: width / 109, y: (tabDesign.keyViewHeight * 2 + tabDesign.verticalSpacing) / 281, anchor: .top)
    }

    @MainActor static func scaleToFrameSize(keyWidth: CGFloat, scale_y: CGFloat, color: some ShapeStyle, borderColor: some ShapeStyle, borderWidth: CGFloat, tabDesign: TabDependentDesign) -> some View {
        let height = (tabDesign.keyViewHeight * 2 + tabDesign.verticalSpacing) * scale_y
        return expandedPath(rdw: 0, ldw: 0, width: keyWidth, tabDesign: tabDesign)
            .strokeAndFill(fillContent: color, strokeContent: borderColor, lineWidth: borderWidth)
            .frame(width: keyWidth, height: height)
    }

    @MainActor static func scaleToVariationsSize(keyWidth: CGFloat, scale_y: CGFloat, variationsCount: Int, color: some ShapeStyle, borderColor: some ShapeStyle, borderWidth: CGFloat, direction: VariationsViewDirection, tabDesign: TabDependentDesign) -> some View {
        let keyViewSize = tabDesign.keyViewSize
        let height = (keyViewSize.height * 2 + tabDesign.verticalSpacing) * scale_y
        let dw = (keyViewSize.width * CGFloat(variationsCount - 1) + tabDesign.horizontalSpacing * CGFloat(variationsCount - 1)) * 109 / keyViewSize.width
        switch direction {
        case .center:
            return expandedPath(rdw: dw / 2, ldw: dw / 2, width: keyWidth, tabDesign: tabDesign)
                .strokeAndFill(fillContent: color, strokeContent: borderColor, lineWidth: borderWidth)
                .frame(width: keyWidth, height: height)
        case .right:
            return expandedPath(rdw: dw, ldw: 0, width: keyWidth, tabDesign: tabDesign)
                .strokeAndFill(fillContent: color, strokeContent: borderColor, lineWidth: borderWidth)
                .frame(width: keyWidth, height: height)
        case .left:
            return expandedPath(rdw: 0, ldw: dw, width: keyWidth, tabDesign: tabDesign)
                .strokeAndFill(fillContent: color, strokeContent: borderColor, lineWidth: borderWidth)
                .frame(width: keyWidth, height: height)
        }
    }
}
