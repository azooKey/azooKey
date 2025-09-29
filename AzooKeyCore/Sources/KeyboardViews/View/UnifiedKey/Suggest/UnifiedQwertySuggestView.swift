import Foundation
import SwiftUI
import SwiftUIUtils

struct UnifiedQwertySuggestView<Extension: ApplicationSpecificKeyboardViewExtension>: View {
    @EnvironmentObject private var variableStates: VariableStates
    @Environment(Extension.Theme.self) private var theme
    @Environment(\.colorScheme) private var colorScheme

    private let baseLabel: KeyLabel<Extension>
    private let variationsModel: QwertyVariationsModel
    private let suggestType: QwertySuggestType
    private let tabDesign: TabDependentDesign
    private let size: CGSize

    init(baseLabel: KeyLabel<Extension>, variationsModel: QwertyVariationsModel, tabDesign: TabDependentDesign, size: CGSize, suggestType: QwertySuggestType) {
        self.baseLabel = baseLabel
        self.variationsModel = variationsModel
        self.tabDesign = tabDesign
        self.size = size
        self.suggestType = suggestType
    }

    private var keyBorderColor: Color { theme.borderColor.color }
    private var keyBorderWidth: CGFloat { theme.borderWidth }

    private var suggestColor: Color {
        let def = Extension.ThemeExtension.default
        let nat = Extension.ThemeExtension.native
        return switch (colorScheme, theme) {
        case (_, def): Design.colors.suggestKeyColor
        case (.dark, nat): .systemGray3
        default: .white
        }
    }
    private var suggestTextColor: Color? {
        let def = Extension.ThemeExtension.default
        let nat = Extension.ThemeExtension.native
        return switch (colorScheme, theme) {
        case (_, def): .black
        case (.dark, nat): .white
        default: .black
        }
    }
    private var shadowColor: Color { (suggestTextColor ?? .black).opacity(0.5) }

    // MARK: Shapes (ported from QwertySuggestView)
    @MainActor private static func expandedPath(rdw: CGFloat, ldw: CGFloat, keyWidth: CGFloat, tabDesign: TabDependentDesign) -> some Shape {
        let height = tabDesign.keyViewHeight * 2 + tabDesign.verticalSpacing
        let BC: CGFloat = tabDesign.keyViewHeight
        let _CD: CGSize = .init(width: tabDesign.verticalSpacing, height: tabDesign.verticalSpacing)
        let G_H = _CD
        let EF = keyWidth
        let width = ldw + _CD.width + keyWidth + G_H.width + rdw
        return Path { path in
            var points = [CGPoint]()
            points.append(contentsOf: [CGPoint(x: 0, y: 0), CGPoint(x: 0, y: BC)])
            if ldw > 0 {
                points.append(CGPoint(x: ldw + _CD.width, y: BC))
            } else {
                points.append(CGPoint(x: ldw + _CD.width, y: BC + _CD.height))
            }
            points.append(contentsOf: [CGPoint(x: ldw + _CD.width, y: height), CGPoint(x: ldw + _CD.width + EF, y: height)])
            if rdw > 0 {
                points.append(CGPoint(x: ldw + _CD.width + EF, y: BC))
            } else {
                points.append(CGPoint(x: ldw + _CD.width + EF, y: BC + _CD.height))
            }
            points.append(contentsOf: [CGPoint(x: width, y: BC), CGPoint(x: width, y: 0)])
            path.addPoints(points, cornerRadius: 4)
        }.offsetBy(dx: -(ldw + _CD.width), dy: 0)
    }
    @MainActor private static func scaleToFrameSize(keyWidth: CGFloat, scale_y: CGFloat, color: some ShapeStyle, borderColor: some ShapeStyle, borderWidth: CGFloat, tabDesign: TabDependentDesign) -> some View {
        let height = (tabDesign.keyViewHeight * 2 + tabDesign.verticalSpacing) * scale_y
        return expandedPath(rdw: 0, ldw: 0, keyWidth: keyWidth, tabDesign: tabDesign)
            .strokeAndFill(fillContent: color, strokeContent: borderColor, lineWidth: borderWidth)
            .frame(width: keyWidth, height: height)
    }
    @MainActor private static func scaleToVariationsSize(keyWidth: CGFloat, scale_y: CGFloat, variationsCount: Int, color: some ShapeStyle, borderColor: some ShapeStyle, borderWidth: CGFloat, direction: VariationsViewDirection, tabDesign: TabDependentDesign) -> some View {
        let keyViewSize = tabDesign.keyViewSize
        let height = (keyViewSize.height * 2 + tabDesign.verticalSpacing) * scale_y
        let dw = keyViewSize.width * CGFloat(variationsCount - 1) + tabDesign.horizontalSpacing * CGFloat(variationsCount - 1)
        switch direction {
        case .center:
            return expandedPath(rdw: dw / 2, ldw: dw / 2, keyWidth: keyWidth, tabDesign: tabDesign)
                .strokeAndFill(fillContent: color, strokeContent: borderColor, lineWidth: borderWidth)
                .frame(width: keyWidth, height: height)
        case .right:
            return expandedPath(rdw: dw, ldw: 0, keyWidth: keyWidth, tabDesign: tabDesign)
                .strokeAndFill(fillContent: color, strokeContent: borderColor, lineWidth: borderWidth)
                .frame(width: keyWidth, height: height)
        case .left:
            return expandedPath(rdw: 0, ldw: dw, keyWidth: keyWidth, tabDesign: tabDesign)
                .strokeAndFill(fillContent: color, strokeContent: borderColor, lineWidth: borderWidth)
                .frame(width: keyWidth, height: height)
        }
    }

    var body: some View {
        let height = tabDesign.verticalSpacing + size.height
        switch self.suggestType {
        case .normal:
            Self.scaleToFrameSize(keyWidth: size.width, scale_y: 1, color: suggestColor, borderColor: keyBorderColor, borderWidth: keyBorderWidth, tabDesign: tabDesign)
                .overlay { baseLabel.padding(.bottom, height) }
                .compositingGroup()
                .shadow(color: shadowColor, radius: 1, x: 0, y: 0)
                .allowsHitTesting(false)
        case .variation(let selection):
            Self.scaleToVariationsSize(keyWidth: size.width, scale_y: 1, variationsCount: variationsModel.variations.count, color: suggestColor, borderColor: keyBorderColor, borderWidth: keyBorderWidth, direction: variationsModel.direction, tabDesign: tabDesign)
                .overlay(alignment: variationsModel.direction.alignment) {
                    QwertyVariationsView<Extension>(model: variationsModel, selection: selection, tabDesign: tabDesign).padding(.bottom, height)
                }
                .compositingGroup()
                .shadow(color: shadowColor, radius: 1, x: 0, y: 0)
                .allowsHitTesting(false)
        }
    }
}

// MARK: - Rounded Polyline helper
private extension Path {
    mutating func addPoints(_ points: [CGPoint], cornerRadius: CGFloat) {
        let count = points.count
        guard count > 1 else { return }

        func unit(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
            let dx = b.x - a.x
            let dy = b.y - a.y
            let len = hypot(dx, dy)
            guard len > 0 else { return .zero }
            return CGPoint(x: dx / len, y: dy / len)
        }

        var effR = Array(repeating: cornerRadius, count: count)
        if cornerRadius > 0 {
            for i in 0 ..< count {
                let prev = points[(i - 1 + count) % count]
                let curr = points[i]
                let next = points[(i + 1) % count]

                let maxR = 0.5 * min(
                    hypot(prev.x - curr.x, prev.y - curr.y),
                    hypot(next.x - curr.x, next.y - curr.y)
                )
                effR[i] = min(cornerRadius, maxR)
            }
        }

        if cornerRadius > 0 {
            self.move(to: points[count - 1])
        } else {
            self.move(to: points[0])
        }
        for i in 0 ..< count {
            let curr = points[i]
            let next = points[(i + 1) % count]
            let r = effR[i]

            if r > 0 {
                self.addArc(tangent1End: curr, tangent2End: next, radius: r)
            } else {
                self.addLine(to: curr)
            }
        }
        self.closeSubpath()
    }
}
