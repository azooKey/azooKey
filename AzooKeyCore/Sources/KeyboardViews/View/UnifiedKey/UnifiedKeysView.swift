import CustardKit
import Foundation
import SwiftUI

public struct UnifiedKeysView<Extension: ApplicationSpecificKeyboardViewExtension, Content: View>: View {
    private let contentGenerator: (UnifiedGenericKeyView<Extension>, UnifiedPositionSpecifier) -> (Content)
    private let models: [(position: UnifiedPositionSpecifier, model: any UnifiedKeyModelProtocol<Extension>)]
    private let tabDesign: TabDependentDesign
    @State private var activeSuggestKeys: Set<String> = []

    private static func isVisible(_ position: UnifiedPositionSpecifier, tabDesign: TabDependentDesign) -> Bool {
        GridFitPositionSpecifier(
            x: Double(position.x),
            y: Double(position.y),
            width: Double(position.width),
            height: Double(position.height)
        ).intersects(
            .init(
                x: 0,
                y: 0,
                width: Double(tabDesign.horizontalKeyCount),
                height: Double(tabDesign.verticalKeyCount)
            )
        )
    }

    public init(models: [(position: UnifiedPositionSpecifier, model: any UnifiedKeyModelProtocol<Extension>)], tabDesign: TabDependentDesign, @ViewBuilder generator: @escaping (UnifiedGenericKeyView<Extension>, UnifiedPositionSpecifier) -> (Content)) {
        self.models = models.filter { Self.isVisible($0.position, tabDesign: tabDesign) }
        self.tabDesign = tabDesign
        self.contentGenerator = generator
    }

    @MainActor private func keyData(position: UnifiedPositionSpecifier) -> (position: CGPoint, size: CGSize, contentSize: CGSize, hitRect: CGRect) {
        let width = tabDesign.keyViewWidth(widthCount: position.width)
        let height = tabDesign.keyViewHeight(heightCount: position.height)
        let dx = width * 0.5 + tabDesign.keyViewWidth * position.x + tabDesign.horizontalSpacing * position.x
        let dy = height * 0.5 + tabDesign.keyViewHeight * position.y + tabDesign.verticalSpacing * position.y
        let contentWidth = width + tabDesign.horizontalSpacing
        let contentHeight = height + tabDesign.verticalSpacing
        let keyFrame = CGRect(x: dx - width / 2, y: dy - height / 2, width: width, height: height)
        let gridBounds = CGRect(x: 0, y: 0, width: tabDesign.keysWidth, height: tabDesign.keysHeight)
        // キーのタップ範囲が候補バーへはみ出さないよう、キー領域内に収める。
        let hitFrame = keyFrame
            .insetBy(dx: -tabDesign.horizontalSpacing / 2, dy: -tabDesign.verticalSpacing / 2)
            .intersection(gridBounds)
        let hitRect = hitFrame.isNull ? .zero : hitFrame.offsetBy(dx: -keyFrame.minX, dy: -keyFrame.minY)
        return (CGPoint(x: dx, y: dy), CGSize(width: width, height: height), CGSize(width: contentWidth, height: contentHeight), hitRect)
    }

    public var body: some View {
        ZStack {
            ForEach(models, id: \.position) { item in
                let info = keyData(position: item.position)
                let keyID = "\(item.position.x)-\(item.position.y)"
                let keyView = UnifiedGenericKeyView<Extension>(model: item.model, tabDesign: tabDesign, size: info.size, isSuggesting: Binding(
                    get: { activeSuggestKeys.contains(keyID) },
                    set: { newValue in if newValue { activeSuggestKeys.insert(keyID) } else { activeSuggestKeys.remove(keyID) } }
                ), hitRect: info.hitRect)
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
