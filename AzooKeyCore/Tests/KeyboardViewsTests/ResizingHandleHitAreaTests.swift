import CoreGraphics
@testable import KeyboardViews
import XCTest

final class ResizingHandleHitAreaTests: XCTestCase {
    private let size = CGSize(width: 390, height: 260)
    private let edgeRatio: CGFloat = 1 / 5

    private func rect(_ edge: ResizingHandleHitArea.Edge, size: CGSize? = nil) -> CGRect {
        ResizingHandleHitArea.rect(for: edge, in: size ?? self.size, edgeRatio: edgeRatio)
    }

    func test_hitAreaIsAtLeastMinimumThickness() {
        // 小さく縮めたキーボードでも、指で掴める厚みを保つ
        let small = CGSize(width: 120, height: 120)
        XCTAssertGreaterThanOrEqual(rect(.left, size: small).width, ResizingHandleHitArea.minimumThickness)
        XCTAssertGreaterThanOrEqual(rect(.right, size: small).width, ResizingHandleHitArea.minimumThickness)
        XCTAssertGreaterThanOrEqual(rect(.top, size: small).height, ResizingHandleHitArea.minimumThickness)
        XCTAssertGreaterThanOrEqual(rect(.bottom, size: small).height, ResizingHandleHitArea.minimumThickness)
    }

    func test_hitAreaCoversDrawnLines() {
        // 描いている線の帯（端から 1/8・中央の ±edgeRatio*0.8）を含む
        let left = rect(.left)
        XCTAssertLessThanOrEqual(left.minX, 0)
        XCTAssertGreaterThanOrEqual(left.maxX, size.width / 8)
        XCTAssertLessThanOrEqual(left.minY, size.height / 2 - size.height * edgeRatio * 0.8)
        XCTAssertGreaterThanOrEqual(left.maxY, size.height / 2 + size.height * edgeRatio * 0.8)

        let top = rect(.top)
        XCTAssertLessThanOrEqual(top.minY, 0)
        XCTAssertGreaterThanOrEqual(top.maxY, size.height / 8)
        XCTAssertLessThanOrEqual(top.minX, size.width / 2 - size.width * edgeRatio * 0.8)
        XCTAssertGreaterThanOrEqual(top.maxX, size.width / 2 + size.width * edgeRatio * 0.8)
    }

    func test_hitAreasStayInsideAndMirror() {
        let bounds = CGRect(origin: .zero, size: size)
        for edge in ResizingHandleHitArea.Edge.allCases {
            XCTAssertTrue(bounds.contains(rect(edge)), "\(edge)")
        }
        XCTAssertEqual(rect(.right).maxX, size.width)
        XCTAssertEqual(rect(.right).width, rect(.left).width)
        XCTAssertEqual(rect(.bottom).maxY, size.height)
        XCTAssertEqual(rect(.bottom).height, rect(.top).height)
    }

    func test_horizontalAndVerticalHandlesDoNotOverlap() {
        // 角で左右のハンドルと上下のハンドルが重なると、どちらのドラッグになるかが曖昧になる
        for side in [ResizingHandleHitArea.Edge.left, .right] {
            for vertical in [ResizingHandleHitArea.Edge.top, .bottom] {
                XCTAssertFalse(rect(side).intersects(rect(vertical)), "\(side) / \(vertical)")
            }
        }
    }
}
