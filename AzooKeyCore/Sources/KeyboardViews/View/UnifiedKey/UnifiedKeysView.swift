import Foundation
import SwiftUI

public struct UnifiedKeysView<Extension: ApplicationSpecificKeyboardViewExtension, Content: View>: View {
    private let contentGenerator: (UnifiedGenericKeyView<Extension>, UnifiedPositionSpecifier) -> (Content)
    private let models: [(position: UnifiedPositionSpecifier, model: any UnifiedKeyModelProtocol<Extension>, gesture: UnifiedGenericKeyView<Extension>.GestureSet)]
    private let tabDesign: TabDependentDesign
    @State private var activeSuggestKeys: Set<String> = []

    public init(models: [(position: UnifiedPositionSpecifier, model: any UnifiedKeyModelProtocol<Extension>, gesture: UnifiedGenericKeyView<Extension>.GestureSet)], tabDesign: TabDependentDesign, @ViewBuilder generator: @escaping (UnifiedGenericKeyView<Extension>, UnifiedPositionSpecifier) -> (Content)) {
        self.models = models
        self.tabDesign = tabDesign
        self.contentGenerator = generator
    }

    @MainActor private func keyData(position: UnifiedPositionSpecifier) -> (position: CGPoint, size: CGSize, contentSize: CGSize) {
        let width = tabDesign.keyViewWidth(widthCount: position.width)
        let height = tabDesign.keyViewHeight(heightCount: position.height)
        let dx = width * 0.5 + tabDesign.keyViewWidth * position.x + tabDesign.horizontalSpacing * position.x
        let dy = height * 0.5 + tabDesign.keyViewHeight * position.y + tabDesign.verticalSpacing * position.y
        let contentWidth = width + tabDesign.horizontalSpacing
        let contentHeight = height + tabDesign.verticalSpacing
        return (CGPoint(x: dx, y: dy), CGSize(width: width, height: height), CGSize(width: contentWidth, height: contentHeight))
    }

    public var body: some View {
        ZStack {
            ForEach(models, id: \.position) { item in
                let info = keyData(position: item.position)
                let keyID = "\(item.position.x)-\(item.position.y)"
                let keyView = UnifiedGenericKeyView<Extension>(model: item.model, tabDesign: tabDesign, size: info.size, gestureSet: item.gesture, isSuggesting: Binding(
                    get: { activeSuggestKeys.contains(keyID) },
                    set: { newValue in if newValue { activeSuggestKeys.insert(keyID) } else { activeSuggestKeys.remove(keyID) } }
                ))
                contentGenerator(keyView, item.position)
                    .zIndex(activeSuggestKeys.contains(keyID) ? 1 : 0)
                    .frame(width: info.contentSize.width, height: info.contentSize.height)
                    .contentShape(Rectangle())
                    .position(x: info.position.x, y: info.position.y)
            }
        }
        .frame(width: tabDesign.keysWidth, height: tabDesign.keysHeight)
    }
}
