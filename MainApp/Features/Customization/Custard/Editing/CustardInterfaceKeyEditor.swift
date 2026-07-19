import AzooKeyUtils
import CustardKit
import KeyboardViews
import SwiftUI
import SwiftUIUtils
import UniformTypeIdentifiers

@MainActor
struct CustardInterfaceKeyEditor: View {
    enum Target: Equatable {
        case flick
        case simple
    }

    @Binding private var keyData: UserMadeKeyData
    @StateObject private var state: CustardInterfaceKeyEditingState
    private let target: Target

    init(data: Binding<UserMadeKeyData>, target: Target = .flick) {
        self._keyData = data
        self._state = StateObject(
            wrappedValue: CustardInterfaceKeyEditingState(model: data.wrappedValue.model)
        )
        self.target = target
    }

    private var screenWidth: CGFloat {
        UIScreen.main.bounds.width
    }

    private var keySize: CGSize {
        CGSize(width: min(100, screenWidth / 5.6), height: min(70, screenWidth / 8))
    }

    var body: some View {
        VStack {
            switch keyData.model {
            case let .custom(key):
                switch target {
                case .flick:
                    Picker("編集モード", selection: $state.editSegment) {
                        Text("フリック").tag(CustardKeyEditSegment.flick)
                        Text("長押しバリエーション").tag(CustardKeyEditSegment.longpress)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    switch state.editSegment {
                    case .flick:
                        flickKeysView(key: key)
                        customKeyEditor(position: state.selectedPosition)
                    case .longpress:
                        longpressListEditor
                        let count = keyData.model[.custom].longpressKeys().count
                        if (0..<count).contains(state.selectedLongpressIndex) {
                            longpressKeyEditor(index: state.selectedLongpressIndex)
                        } else {
                            Spacer()
                        }
                    }
                case .simple:
                    keyView(key: key, position: .center)
                    customKeyEditor(position: .center)
                }
            case .system:
                systemKeyEditor
            }
        }
        .background(Color.secondarySystemBackground)
        .navigationTitle(Text("キーの編集"))
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var longpressListEditor: some View {
        let customKey = Binding<CustardInterfaceCustomKey>(
            get: { keyData.model[.custom] },
            set: { keyData.model[.custom] = $0 }
        )
        let variations = Binding<[CustardInterfaceVariationKey]>(
            get: { customKey.wrappedValue.longpressKeys() },
            set: { newValue in
                var key = customKey.wrappedValue
                key.setLongpressKeys(newValue)
                customKey.wrappedValue = key
            }
        )
        let chipWidth: CGFloat = min(120, screenWidth / 4.5)

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("長押しバリエーション")
                    .font(.headline)
                Spacer()
                Button("追加", systemImage: "plus") {
                    var key = customKey.wrappedValue
                    key.appendLongpressVariation()
                    customKey.wrappedValue = key
                    state.didAddLongpressVariation(
                        at: customKey.wrappedValue.longpressKeys().indices.last ?? -1
                    )
                }
            }
            if variations.wrappedValue.isEmpty {
                Text("バリエーションはキーを長押しすると選択できます")
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        let count = min(state.longpressIDs.count, variations.wrappedValue.count)
                        let items = (0..<count).map {
                            CustardKeyLongpressItem(id: state.longpressIDs[$0], index: $0)
                        }
                        ForEach(items) { item in
                            longpressChip(
                                variations.wrappedValue[item.index],
                                index: item.index,
                                id: item.id,
                                width: chipWidth,
                                variations: variations,
                                customKey: customKey
                            )
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(.horizontal)
        .onAppear {
            state.synchronizeLongpressIDs(count: variations.wrappedValue.count)
        }
        .onChange(of: variations.wrappedValue.count) { _, count in
            state.synchronizeLongpressIDs(count: count)
        }
    }

    private func longpressChip(
        _ variation: CustardInterfaceVariationKey,
        index: Int,
        id: UUID,
        width: CGFloat,
        variations: Binding<[CustardInterfaceVariationKey]>,
        customKey: Binding<CustardInterfaceCustomKey>
    ) -> some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.background)
            .stroke(state.selectedLongpressIndex == index ? .accentColor : .primary)
            .focus(.accentColor, focused: state.selectedLongpressIndex == index)
            .overlay {
                longpressChipLabel(variation)
            }
            .compositingGroup()
            .frame(width: width, height: 44)
            .padding(6)
            .contentShape(Rectangle())
            .onTapGesture {
                state.selectedLongpressIndex = index
            }
            .onDrag {
                state.draggedLongpressIndex = index
                return NSItemProvider(contentsOf: URL(string: "longpress-\(index)")!)!
            }
            .onDrop(of: [.url], delegate: CustardKeyDropDelegate {
                guard let source = state.draggedLongpressIndex, source != index else {
                    return
                }
                var values = variations.wrappedValue
                let destination = index > source ? index + 1 : index
                values.move(fromOffsets: IndexSet(integer: source), toOffset: destination)

                let movedID = state.longpressIDs.remove(at: source)
                state.longpressIDs.insert(movedID, at: index)

                var key = customKey.wrappedValue
                key.setLongpressKeys(values)
                customKey.wrappedValue = key
                state.draggedLongpressIndex = index
                state.selectedLongpressIndex = index
            })
            .id(id)
    }

    @ViewBuilder
    private func longpressChipLabel(_ variation: CustardInterfaceVariationKey) -> some View {
        switch variation[.labelType] {
        case .text:
            Text(variation[.labelText])
                .lineLimit(1)
                .padding(.horizontal, 6)
        case .systemImage:
            Image(systemName: variation[.labelImageName])
                .padding(.horizontal, 6)
        case .mainAndSub:
            VStack(spacing: 2) {
                Text(variation[.labelMain])
                Text(variation[.labelSub])
                    .font(.caption)
            }
            .padding(.horizontal, 6)
        case .mainAndDirections:
            DirectionalKeyLabel(
                main: variation[.labelMain],
                directions: variation[.labelDirections],
                subFont: .caption
            )
        }
    }

    private var keyPicker: some View {
        Picker("キーの種類", selection: $keyData.model) {
            if [
                CustardInterfaceKey.system(.enter),
                .custom(.flickSpace()),
                .custom(.flickDelete()),
                .system(.changeKeyboard),
                .system(.qwertyLanguageSwitch),
                .system(.flickKogaki),
                .system(.flickKutoten),
                .system(.flickHiraTab),
                .system(.flickAbcTab),
                .system(.flickStar123Tab),
                .system(.upperLower),
                .system(.nextCandidate),
            ].contains(keyData.model) {
                Text("カスタム").tag(CustardInterfaceKey.custom(.empty))
            } else {
                Text("カスタム").tag(keyData.model)
            }
            Text("改行キー").tag(CustardInterfaceKey.system(.enter))
            Text("削除キー").tag(CustardInterfaceKey.custom(.flickDelete()))
            Text("空白キー").tag(CustardInterfaceKey.custom(.flickSpace()))
            Text("次候補キー").tag(CustardInterfaceKey.system(.nextCandidate))
            Text("地球儀キー").tag(CustardInterfaceKey.system(.changeKeyboard))
            Text("QWERTY言語切り替えキー").tag(
                CustardInterfaceKey.system(.qwertyLanguageSwitch)
            )
            Text("小書き・濁点化キー").tag(CustardInterfaceKey.system(.flickKogaki))
            Text("大文字・小文字キー").tag(CustardInterfaceKey.system(.upperLower))
            Text("句読点キー").tag(CustardInterfaceKey.system(.flickKutoten))
            Text("日本語タブキー").tag(CustardInterfaceKey.system(.flickHiraTab))
            Text("英語タブキー").tag(CustardInterfaceKey.system(.flickAbcTab))
            Text("記号タブキー").tag(CustardInterfaceKey.system(.flickStar123Tab))
        }
    }

    @ViewBuilder
    private var sizePicker: some View {
        Stepper("縦幅: \(keyData.height)", value: $keyData.height, in: 1 ... .max)
        Stepper("横幅: \(keyData.width)", value: $keyData.width, in: 1 ... .max)
    }

    private var systemKeyEditor: some View {
        Form {
            Section {
                keyPicker
            }
            if target == .flick {
                Section(header: Text("キーのサイズ")) {
                    sizePicker
                }
            }
            Section {
                Button("クリア") {
                    keyData.model = .custom(.empty)
                }
                .foregroundStyle(.red)
            }
        }
    }

    private func customKeyEditor(position: FlickKeyPosition) -> some View {
        Form {
            inputSection(position: position)
            CustardKeyLabelEditorSection(
                selection: labelSelection(position: position),
                labelText: Binding(
                    get: { keyData.model[.custom][.labelText, position] },
                    set: { keyData.model[.custom][.labelText, position] = $0 }
                ),
                labelImageName: Binding(
                    get: { keyData.model[.custom][.labelImageName, position] },
                    set: { keyData.model[.custom][.labelImageName, position] = $0 }
                ),
                labelMain: Binding(
                    get: { keyData.model[.custom][.labelMain, position] },
                    set: { keyData.model[.custom][.labelMain, position] = $0 }
                ),
                labelSub: Binding(
                    get: { keyData.model[.custom][.labelSub, position] },
                    set: { keyData.model[.custom][.labelSub, position] = $0 }
                ),
                labelDirections: Binding(
                    get: { keyData.model[.custom][.labelDirections, position] },
                    set: { keyData.model[.custom][.labelDirections, position] = $0 }
                ),
                pressActions: $keyData.model[.custom][.pressAction, position],
                supportsAuto: true,
                showHelp: true
            )
            CustardKeyPressActionSection(
                actions: $keyData.model[.custom][.pressAction, position]
            )
            CustardKeyLongpressActionSection(
                action: $keyData.model[.custom][.longpressAction, position],
                warning: longpressWarning(position: position)
            )
            if position == .center {
                Picker("キーの色", selection: $keyData.model[.custom].design.color) {
                    Text("通常のキー").tag(CustardKeyDesign.ColorType.normal)
                    Text("特別なキー").tag(CustardKeyDesign.ColorType.special)
                    Text("押されているキー").tag(CustardKeyDesign.ColorType.selected)
                    Text("目立たないキー").tag(CustardKeyDesign.ColorType.unimportant)
                }
            }
            customKeyOptions(position: position)
        }
    }

    private func inputSection(position: FlickKeyPosition) -> some View {
        Section {
            let actions = keyData.model[.custom][.pressAction, position]
            if CustardInterfaceKeyEditingService.isInputActionEditable(actions) {
                HStack {
                    Text("入力")
                    HelpAlertButton(
                        title: "入力",
                        explanation: "キーを押して入力される文字を設定します。"
                    )
                    TextField(
                        "入力",
                        text: Binding(
                            get: { keyData.model[.custom][.inputAction, position] },
                            set: { keyData.model[.custom][.inputAction, position] = $0 }
                        )
                    )
                    .id(position)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.done)
                }
            } else {
                Text("このキーには入力以外のアクションが設定されています。現在のアクションを消去して入力する文字を設定するには「入力を設定する」を押してください")
                Button("入力を設定する") {
                    keyData.model[.custom][.inputAction, position] = ""
                }
                .foregroundStyle(.accentColor)
            }
        }
    }

    private func labelSelection(position: FlickKeyPosition) -> Binding<CustardKeyLabelSelection> {
        Binding(
            get: {
                guard let type = state.labelTypes[position] else {
                    return .auto
                }
                switch type {
                case .text: return .text
                case .systemImage: return .systemImage
                case .mainAndSub: return .mainAndSub
                case .mainAndDirections: return .mainAndDirections
                }
            },
            set: { selection in
                switch selection {
                case .auto:
                    state.labelTypes[position] = nil
                    let actions = keyData.model[.custom][.pressAction, position]
                    keyData.model[.custom][.label, position] = .text(
                        CustardInterfaceKeyEditingService.inputText(in: actions) ?? ""
                    )
                case .text:
                    state.labelTypes[position] = .text
                    keyData.model[.custom][.label, position] = .text(
                        keyData.model[.custom][.labelText, position]
                    )
                case .systemImage:
                    state.labelTypes[position] = .systemImage
                    keyData.model[.custom][.label, position] = .systemImage(
                        keyData.model[.custom][.labelImageName, position]
                    )
                case .mainAndSub:
                    state.labelTypes[position] = .mainAndSub
                    keyData.model[.custom][.label, position] = .mainAndSub(
                        keyData.model[.custom][.labelMain, position],
                        keyData.model[.custom][.labelSub, position]
                    )
                case .mainAndDirections:
                    state.labelTypes[position] = .mainAndDirections
                    keyData.model[.custom][.label, position] = .mainAndDirections(
                        keyData.model[.custom][.labelMain, position],
                        keyData.model[.custom][.labelDirections, position]
                    )
                }
            }
        )
    }

    private func longpressWarning(position: FlickKeyPosition) -> LocalizedStringKey? {
        if position == .center, !keyData.model[.custom].longpressKeys().isEmpty {
            return "長押しバリエーションが設定されている場合長押しアクションは動作しません"
        }
        return nil
    }

    @ViewBuilder
    private func customKeyOptions(position: FlickKeyPosition) -> some View {
        if target == .flick, position == .center {
            Section {
                sizePicker
            }
            Section {
                keyPicker
            }
            Section {
                Button("クリア") {
                    keyData.model[.custom].press_actions = [.input("")]
                    keyData.model[.custom].longpress_actions = .none
                    keyData.model[.custom].design = .init(label: .text(""), color: .normal)
                }
                .foregroundStyle(.red)
            }
        }
        if let direction = position.flickDirection {
            Button("クリア") {
                keyData.model[.custom].variations.removeAll {
                    $0.type == .flickVariation(direction)
                }
            }
            .foregroundStyle(.red)
        }
    }

    private func flickKeysView(key: CustardInterfaceCustomKey) -> some View {
        VStack {
            keyView(key: key, position: .top)
            HStack {
                keyView(key: key, position: .left)
                keyView(key: key, position: .center)
                keyView(key: key, position: .right)
            }
            keyView(key: key, position: .bottom)
        }
    }

    @ViewBuilder
    private func keyView(
        key: CustardInterfaceCustomKey,
        position: FlickKeyPosition
    ) -> some View {
        switch key[.label, position] {
        case .text:
            CustomKeySettingFlickKeyView(
                position,
                label: key[.labelText, position],
                selectedPosition: $state.selectedPosition
            )
            .frame(width: keySize.width, height: keySize.height)
        case .systemImage:
            CustomKeySettingFlickKeyView(position, selectedPosition: $state.selectedPosition) {
                Image(systemName: key[.labelImageName, position])
            }
            .frame(width: keySize.width, height: keySize.height)
        case .mainAndSub:
            CustomKeySettingFlickKeyView(position, selectedPosition: $state.selectedPosition) {
                VStack {
                    Text(verbatim: key[.labelMain, position])
                    Text(verbatim: key[.labelSub, position])
                        .font(.caption)
                }
            }
            .frame(width: keySize.width, height: keySize.height)
        case .mainAndDirections:
            CustomKeySettingFlickKeyView(position, selectedPosition: $state.selectedPosition) {
                DirectionalKeyLabel(
                    main: key[.labelMain, position],
                    directions: key[.labelDirections, position]
                )
            }
            .frame(width: keySize.width, height: keySize.height)
        }
    }

    private func longpressKeyEditor(index: Int) -> some View {
        let variation = longpressVariation(index: index)
        let id = state.longpressIDs.indices.contains(index) ? state.longpressIDs[index] : nil

        return Form {
            Section {
                let actions = variation.wrappedValue[.pressAction]
                if CustardInterfaceKeyEditingService.isInputActionEditable(actions) {
                    HStack {
                        Text("入力")
                        TextField(
                            "入力",
                            text: Binding(
                                get: { variation.wrappedValue[.inputAction] },
                                set: { variation.wrappedValue[.inputAction] = $0 }
                            )
                        )
                        .id(index)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.done)
                    }
                } else {
                    Text("このキーには入力以外のアクションが設定されています。現在のアクションを消去して入力する文字を設定するには「入力を設定する」を押してください")
                    Button("入力を設定する") {
                        variation.wrappedValue[.inputAction] = ""
                    }
                    .foregroundStyle(.accentColor)
                }
            }
            CustardKeyLabelEditorSection(
                selection: longpressLabelSelection(variation: variation, id: id),
                labelText: variation[.labelText],
                labelImageName: variation[.labelImageName],
                labelMain: variation[.labelMain],
                labelSub: variation[.labelSub],
                labelDirections: variation[.labelDirections],
                pressActions: variation[.pressAction],
                supportsAuto: true,
                showHelp: false
            )
            .onAppear {
                if let id, state.longpressLabelSelections[id] == nil {
                    state.longpressLabelSelections[id] =
                        CustardInterfaceKeyEditingService.initialLabelSelection(
                            for: variation.wrappedValue
                        )
                }
            }
            CustardKeyPressActionSection(actions: variation[.pressAction])
            CustardKeyLongpressActionSection(
                action: variation[.longpressAction],
                warning: nil
            )
            Section {
                Button("このバリエーションを削除") {
                    var key = keyData.model[.custom]
                    key.removeLongpress(at: index)
                    keyData.model[.custom] = key
                    state.didRemoveLongpressVariation(
                        at: index,
                        remainingCount: key.longpressKeys().count
                    )
                }
                .foregroundStyle(.red)
            }
        }
    }

    private func longpressVariation(
        index: Int
    ) -> Binding<CustardInterfaceVariationKey> {
        Binding(
            get: {
                let variations = keyData.model[.custom].longpressKeys()
                if variations.indices.contains(index) {
                    return variations[index]
                }
                return .init(
                    design: .init(label: .text("")),
                    press_actions: [.input("")],
                    longpress_actions: .none
                )
            },
            set: { newValue in
                var key = keyData.model[.custom]
                var variations = key.longpressKeys()
                if variations.indices.contains(index) {
                    variations[index] = newValue
                    key.setLongpressKeys(variations)
                    keyData.model[.custom] = key
                }
            }
        )
    }

    private func longpressLabelSelection(
        variation: Binding<CustardInterfaceVariationKey>,
        id: UUID?
    ) -> Binding<CustardKeyLabelSelection> {
        Binding(
            get: {
                if let id, let selection = state.longpressLabelSelections[id] {
                    return selection
                }
                return CustardInterfaceKeyEditingService.initialLabelSelection(
                    for: variation.wrappedValue
                )
            },
            set: { selection in
                if let id {
                    state.longpressLabelSelections[id] = selection
                }
                switch selection {
                case .auto:
                    variation.wrappedValue.design.label = .text(
                        CustardInterfaceKeyEditingService.inputText(
                            in: variation.wrappedValue[.pressAction]
                        ) ?? ""
                    )
                case .text:
                    variation.wrappedValue[.labelType] = .text
                case .systemImage:
                    variation.wrappedValue[.labelType] = .systemImage
                case .mainAndSub:
                    variation.wrappedValue[.labelType] = .mainAndSub
                case .mainAndDirections:
                    variation.wrappedValue[.labelType] = .mainAndDirections
                }
            }
        )
    }
}
