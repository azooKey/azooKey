import CustardKit
import KeyboardViews
import SwiftUI

struct EditingCodableActionData: Identifiable, Equatable {
    typealias ID = UUID

    let id = UUID()
    var data: CodableActionData
}

@MainActor
final class CodableActionEditorState: ObservableObject {
    @Published var editMode = EditMode.inactive
    @Published var isActionPickerPresented = false
    @Published var actions: [EditingCodableActionData]

    init(actions: [CodableActionData]) {
        self.actions = CodableActionEditingService.makeEditingActions(from: actions)
    }

    func add(_ action: CodableActionData) {
        withAnimation(.interactiveSpring()) {
            actions.append(EditingCodableActionData(data: action))
        }
    }

    func remove(id: EditingCodableActionData.ID) {
        actions.removeAll { $0.id == id }
    }

    func delete(at offsets: IndexSet) {
        actions.remove(atOffsets: offsets)
    }

    func move(from source: IndexSet, to destination: Int) {
        actions.move(fromOffsets: source, toOffset: destination)
    }
}

@MainActor
final class CodableLongpressActionEditorState: ObservableObject {
    enum AddTarget {
        case start
        case `repeat`
    }

    @Published var editMode = EditMode.inactive
    @Published var isActionPickerPresented = false
    @Published var startActions: [EditingCodableActionData]
    @Published var repeatActions: [EditingCodableActionData]
    private var addTarget: AddTarget = .start

    init(actions: CodableLongpressActionData) {
        self.startActions = CodableActionEditingService.makeEditingActions(from: actions.start)
        self.repeatActions = CodableActionEditingService.makeEditingActions(from: actions.repeat)
    }

    func prepareToAdd(to target: AddTarget) {
        addTarget = target
        isActionPickerPresented = true
    }

    func add(_ action: CodableActionData) {
        add(action, to: addTarget)
    }

    func add(_ action: CodableActionData, to target: AddTarget) {
        withAnimation(.interactiveSpring()) {
            switch target {
            case .start:
                startActions.append(EditingCodableActionData(data: action))
            case .repeat:
                repeatActions.append(EditingCodableActionData(data: action))
            }
        }
    }

    func remove(id: EditingCodableActionData.ID, from target: AddTarget) {
        switch target {
        case .start:
            startActions.removeAll { $0.id == id }
        case .repeat:
            repeatActions.removeAll { $0.id == id }
        }
    }

    func delete(at offsets: IndexSet, from target: AddTarget) {
        switch target {
        case .start:
            startActions.remove(atOffsets: offsets)
        case .repeat:
            repeatActions.remove(atOffsets: offsets)
        }
    }

    func move(from source: IndexSet, to destination: Int, in target: AddTarget) {
        switch target {
        case .start:
            startActions.move(fromOffsets: source, toOffset: destination)
        case .repeat:
            repeatActions.move(fromOffsets: source, toOffset: destination)
        }
    }
}
