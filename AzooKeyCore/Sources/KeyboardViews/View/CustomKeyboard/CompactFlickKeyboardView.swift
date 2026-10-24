import CustardKit
import SwiftUI
import SwiftUIUtils

@MainActor
struct CompactFlickKeyboardView<Extension: ApplicationSpecificKeyboardViewExtension>: View {
    let custard: Custard
    @EnvironmentObject private var variableStates: VariableStates

    var body: some View {
        let height = variableStates.interfaceSize.height - Design.keyboardBarHeight(
            interfaceHeight: variableStates.interfaceSize.height, context: variableStates.layoutContext
        ) - 12
        GeometryReader { geometry in
            let frame = AvailableLayoutRegion.largest(
                in: CGRect(origin: .zero, size: geometry.size),
                avoiding: AvailableLayoutRegion.obstacles(in: geometry)
            )
            if !frame.isEmpty {
                CustomKeyboardView<Extension>(
                    custard: custard,
                    interfaceSize: CGSize(width: frame.width, height: variableStates.interfaceSize.height),
                    keySpacing: CompactFlickLayout.keySpacing(orientation: variableStates.keyboardOrientation),
                    keyAreaHeight: frame.height
                )
                .id([frame.minX, frame.minY, frame.width, frame.height])
                .frame(width: frame.width, height: frame.height)
                .position(x: frame.midX, y: frame.midY)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("フリックキーボード")
                .accessibilityIdentifier("compact-flick")
            }
        }
        .frame(width: variableStates.interfaceSize.width, height: max(0, height))
    }
}
