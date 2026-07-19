import CustardKit
import KeyboardViews
import SwiftUI
import SwiftUIUtils

struct CodableActionDataEditor: View {
    @StateObject private var state: CodableActionEditorState
    @Binding private var data: [CodableActionData]
    private let availableCustards: [String]

    init(_ actions: Binding<[CodableActionData]>, availableCustards: [String]) {
        self._data = actions
        self._state = StateObject(wrappedValue: CodableActionEditorState(actions: actions.wrappedValue))
        self.availableCustards = availableCustards
    }

    var body: some View {
        Form {
            Section(header: Text("アクション"), footer: Text("上から順に実行されます")) {
                if state.actions.isEmpty {
                    QuickActionPicker(perform: state.add)
                } else {
                    DisclosuringList($state.actions) { $action in
                        CodableActionEditor(action: $action, availableCustards: availableCustards)
                    } label: { $action in
                        EditableActionListLabel(action: $action) {
                            state.remove(id: $action.wrappedValue.id)
                        }
                    }
                    .onDelete(perform: state.delete)
                    .onMove(perform: state.move)
                    .disclosed { item in item.data.hasAssociatedValue }
                    Button {
                        state.isActionPickerPresented = true
                    } label: {
                        HStack {
                            Image(systemName: "plus")
                            Text("アクションを追加")
                        }
                    }
                }
            }
        }
        .onChange(of: state.actions) { _, actions in
            data = CodableActionEditingService.serialize(actions)
        }
        .sheet(isPresented: $state.isActionPickerPresented) {
            Form {
                ActionPicker { action in
                    state.add(action)
                    state.isActionPickerPresented = false
                }
            }
            .presentationDetents([.fraction(0.4), .fraction(0.7)])
            .presentationBackgroundInteraction(.enabled)
        }
        .navigationBarTitle(Text("動作の編集"), displayMode: .inline)
        .navigationBarItems(trailing: editButton)
        .environment(\.editMode, $state.editMode)
    }

    @ViewBuilder
    private var editButton: some View {
        switch state.editMode {
        case .inactive:
            Button("削除と順番") {
                state.editMode = .active
            }
        case .active, .transient:
            EditConfirmButton(.done) {
                state.editMode = .inactive
            }
        @unknown default:
            EditConfirmButton(.done) {
                state.editMode = .inactive
            }
        }
    }
}

struct CodableLongpressActionDataEditor: View {
    @StateObject private var state: CodableLongpressActionEditorState
    @Binding private var data: CodableLongpressActionData
    private let availableCustards: [String]

    init(_ actions: Binding<CodableLongpressActionData>, availableCustards: [String]) {
        self._data = actions
        self._state = StateObject(wrappedValue: CodableLongpressActionEditorState(actions: actions.wrappedValue))
        self.availableCustards = availableCustards
    }

    var body: some View {
        Form {
            Section {
                Picker("長押しの長さ", selection: $data.duration) {
                    Text("標準").tag(CodableLongpressActionData.LongpressDuration.normal)
                    Text("軽く").tag(CodableLongpressActionData.LongpressDuration.light)
                }
            }
            actionSection(
                title: "押し始めのアクション",
                footer: "上から順に実行されます",
                target: .start,
                actions: $state.startActions,
                recommendation: QuickActionPicker.defaultRecommendation
            )
            actionSection(
                title: "押している間のアクション",
                footer: "繰り返し実行されます",
                target: .repeat,
                actions: $state.repeatActions,
                recommendation: QuickActionPicker.repeatRecommendation
            )
        }
        .onChange(of: state.startActions) { _, actions in
            data.start = CodableActionEditingService.serialize(actions)
        }
        .onChange(of: state.repeatActions) { _, actions in
            data.repeat = CodableActionEditingService.serialize(actions)
        }
        .sheet(isPresented: $state.isActionPickerPresented) {
            Form {
                ActionPicker { action in
                    state.add(action)
                    state.isActionPickerPresented = false
                }
            }
            .presentationDetents([.fraction(0.4), .fraction(0.7)])
            .presentationBackgroundInteraction(.enabled)
        }
        .navigationBarTitle(Text("動作の編集"), displayMode: .inline)
        .navigationBarItems(trailing: editButton)
        .environment(\.editMode, $state.editMode)
    }

    private func actionSection(
        title: LocalizedStringKey,
        footer: LocalizedStringKey,
        target: CodableLongpressActionEditorState.AddTarget,
        actions: Binding<[EditingCodableActionData]>,
        recommendation: [QuickActionPicker.Item]
    ) -> some View {
        Section(header: Text(title), footer: Text(footer)) {
            if actions.wrappedValue.isEmpty {
                QuickActionPicker(recommendation: recommendation) { action in
                    state.add(action, to: target)
                }
            } else {
                DisclosuringList(actions) { $action in
                    CodableActionEditor(action: $action, availableCustards: availableCustards)
                } label: { $action in
                    EditableActionListLabel(action: $action) {
                        state.remove(id: $action.wrappedValue.id, from: target)
                    }
                }
                .onDelete { state.delete(at: $0, from: target) }
                .onMove { state.move(from: $0, to: $1, in: target) }
                .disclosed { item in item.data.hasAssociatedValue }
                Button {
                    state.prepareToAdd(to: target)
                } label: {
                    HStack {
                        Image(systemName: "plus")
                        Text("アクションを追加")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var editButton: some View {
        switch state.editMode {
        case .inactive:
            Button("編集") {
                state.editMode = .active
            }
        case .active, .transient:
            EditConfirmButton(.done) {
                state.editMode = .inactive
            }
        @unknown default:
            EditConfirmButton(.done) {
                state.editMode = .inactive
            }
        }
    }
}
