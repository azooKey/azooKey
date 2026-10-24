import CustardKit
import SwiftUI
import SwiftUIUtils

/// Independent gestures and shared composition, even as the display folds.
@MainActor
struct DuoFlickKeyboardView<Extension: ApplicationSpecificKeyboardViewExtension>: View {
    let custard: Custard
    let layout: DuoFlickLayout
    @EnvironmentObject private var variableStates: VariableStates

    var body: some View {
        let keyAreaHeight = variableStates.interfaceSize.height - Design.keyboardBarHeight(
            interfaceHeight: variableStates.interfaceSize.height, context: variableStates.layoutContext
        ) - 12
        GeometryReader { geometry in
            let frames = layout.panelFrames(
                keyAreaHeight: geometry.size.height,
                avoiding: AvailableLayoutRegion.obstacles(in: geometry)
            )
            ForEach(frames.indices, id: \.self) { index in
                let frame = frames[index]
                CustomKeyboardView<Extension>(
                    custard: custard,
                    interfaceSize: CGSize(width: frame.width, height: variableStates.interfaceSize.height),
                    keySpacing: DuoFlickLayout.keySpacing,
                    keyAreaHeight: frame.height
                )
                // Cancel an in-flight flick when its physical target moves.
                // Composition and candidates live outside this view identity.
                .id([frame.minX, frame.minY, frame.width, frame.height])
                .frame(width: frame.width, height: frame.height)
                .position(x: frame.midX, y: frame.midY)
                .accessibilityElement(children: .contain)
                .accessibilityLabel(frames.count == 1 ? "フリックキーボード" : index == 0 ? "左手のフリックキーボード" : "右手のフリックキーボード")
                .accessibilityIdentifier(index == 0 ? "duo-flick-left" : "duo-flick-right")
            }
        }
        .frame(width: variableStates.interfaceSize.width, height: max(0, keyAreaHeight))
    }
}
