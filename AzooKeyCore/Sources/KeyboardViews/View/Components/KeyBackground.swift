import KeyboardThemes
import SwiftUI

private struct FacetedKeyShape: Shape {
    let cut: CGFloat

    func path(in rect: CGRect) -> Path {
        let value = min(cut, min(rect.width, rect.height) / 3)
        return Path { path in
            path.move(to: CGPoint(x: rect.minX + value, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - value, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + value))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - value))
            path.addLine(to: CGPoint(x: rect.maxX - value, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX + value, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - value))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + value))
            path.closeSubpath()
        }
    }
}

struct KeyBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var backgroundColor: Color
    var borderColor: Color
    var borderWidth: CGFloat
    var size: CGSize
    var shadow: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat)
    var blendMode: BlendMode
    var appearance: ThemeStyle

    private var surfaceInset: CGFloat {
        switch appearance {
        case .standard: 0
        case .minimal: 5
        case .faceted: 3
        }
    }

    private func surfaceSize(inset: CGFloat) -> CGSize {
        CGSize(
            width: max(0, size.width - inset * 2),
            height: max(0, size.height - inset * 2)
        )
    }

    @ViewBuilder
    private var surface: some View {
        switch appearance {
        case .standard:
            let shape = RoundedRectangle(cornerRadius: 6, style: .continuous)
            shape
                .fill(backgroundColor)
                .overlay {
                    shape.stroke(borderColor, lineWidth: borderWidth)
                }
        case .minimal:
            let surfaceSize = surfaceSize(inset: 5)
            Capsule(style: .continuous)
                .fill(backgroundColor)
                .frame(
                    width: max(12, surfaceSize.width * 0.3),
                    height: max(1.25, borderWidth)
                )
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 2)
        case .faceted:
            let shape = FacetedKeyShape(cut: 7)
            shape
                .fill(backgroundColor)
                .overlay {
                    if colorScheme == .dark {
                        shape.fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.09),
                                    Color.clear,
                                    Color.black.opacity(0.14),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                }
                .overlay {
                    shape.stroke(borderColor, lineWidth: borderWidth)
                }
                .overlay {
                    shape
                        .stroke(borderColor.opacity(0.22), lineWidth: 0.5)
                        .padding(2)
                }
                .overlay(alignment: .topLeading) {
                    Capsule(style: .continuous)
                        .fill(borderColor.opacity(0.9))
                        .frame(width: 18, height: 1)
                        .padding(.leading, 11)
                        .padding(.top, 3)
                }
        }
    }

    var body: some View {
        let surfaceSize = surfaceSize(inset: surfaceInset)
        surface
            .frame(width: surfaceSize.width, height: surfaceSize.height)
            .compositingGroup()
            .shadow(
                color: self.shadow.color,
                radius: self.shadow.radius,
                x: self.shadow.x,
                y: self.shadow.y
            )
            .blendMode(self.blendMode)
            .frame(width: size.width, height: size.height)
            .contentShape(Rectangle())
    }
}
