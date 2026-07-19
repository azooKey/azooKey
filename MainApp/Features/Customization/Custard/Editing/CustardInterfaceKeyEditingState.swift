import CustardKit
import KeyboardViews
import SwiftUI

enum CustardKeyLabelType: Equatable {
    case text
    case systemImage
    case mainAndSub
    case mainAndDirections
}

enum CustardKeyLabelSelection: Equatable {
    case auto
    case text
    case systemImage
    case mainAndSub
    case mainAndDirections
}

enum CustardKeyEditSegment: Sendable, Hashable {
    case flick
    case longpress
}

struct CustardKeyLabelTypeMap {
    var center: CustardKeyLabelType?
    var left: CustardKeyLabelType?
    var top: CustardKeyLabelType?
    var right: CustardKeyLabelType?
    var bottom: CustardKeyLabelType?

    subscript(position: FlickKeyPosition) -> CustardKeyLabelType? {
        get {
            switch position {
            case .center: center
            case .left: left
            case .top: top
            case .right: right
            case .bottom: bottom
            }
        }
        set {
            switch position {
            case .center: center = newValue
            case .left: left = newValue
            case .top: top = newValue
            case .right: right = newValue
            case .bottom: bottom = newValue
            }
        }
    }
}

@MainActor
final class CustardInterfaceKeyEditingState: ObservableObject {
    @Published var selectedPosition: FlickKeyPosition = .center
    @Published var selectedLongpressIndex = -1
    @Published var draggedLongpressIndex: Int?
    @Published var longpressIDs: [UUID] = []
    @Published var longpressLabelSelections: [UUID: CustardKeyLabelSelection] = [:]
    @Published var labelTypes = CustardKeyLabelTypeMap()
    @Published var editSegment: CustardKeyEditSegment = .flick

    init(model: CustardInterfaceKey) {
        guard case let .custom(key) = model else {
            return
        }
        self.labelTypes = CustardKeyLabelTypeMap(
            center: CustardInterfaceKeyEditingService.initialLabelType(for: key, position: .center),
            left: CustardInterfaceKeyEditingService.initialLabelType(for: key, position: .left),
            top: CustardInterfaceKeyEditingService.initialLabelType(for: key, position: .top),
            right: CustardInterfaceKeyEditingService.initialLabelType(for: key, position: .right),
            bottom: CustardInterfaceKeyEditingService.initialLabelType(for: key, position: .bottom)
        )
    }

    func synchronizeLongpressIDs(count: Int) {
        if longpressIDs.count < count {
            longpressIDs.append(contentsOf: (longpressIDs.count..<count).map { _ in UUID() })
        } else if longpressIDs.count > count {
            longpressIDs.removeLast(longpressIDs.count - count)
        }
    }

    func didAddLongpressVariation(at index: Int) {
        let id = UUID()
        longpressIDs.append(id)
        longpressLabelSelections[id] = .auto
        selectedLongpressIndex = index
    }

    func didRemoveLongpressVariation(at index: Int, remainingCount: Int) {
        if longpressIDs.indices.contains(index) {
            let removedID = longpressIDs.remove(at: index)
            longpressLabelSelections.removeValue(forKey: removedID)
        }
        selectedLongpressIndex = remainingCount == 0 ? -1 : min(index, remainingCount - 1)
    }
}
