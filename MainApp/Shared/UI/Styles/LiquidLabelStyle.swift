import SwiftUI

struct LiquidLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        if #available(iOS 26, *) {
            Label(title: { configuration.title }, icon: { configuration.icon })
                .font(.caption)
                .bold()
                .font(.caption)
                .padding(8)
                .glassEffect(.regular)
                .padding(.bottom, 4)
        } else {
            Label(title: { configuration.title }, icon: { configuration.icon })
                .font(.caption)
                .foregroundColor(.secondary)
                .bold()
                .font(.caption)
                .padding(8)
                .background {
                    Capsule()
                        .foregroundStyle(.regularMaterial)
                        .shadow(radius: 1.5)
                }
                .padding(.bottom, 4)
        }
    }
}
