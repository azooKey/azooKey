//
//  EmojiTab.swift
//  azooKey
//
//  Created by ensan on 2023/03/15.
//  Copyright © 2023 ensan. All rights reserved.
//

import KeyboardThemes
import SwiftUI
import SwiftUtils

@MainActor
struct EmojiTab<Extension: ApplicationSpecificKeyboardViewExtension>: View {
    @EnvironmentObject private var variableStates: VariableStates
    @Environment(Extension.Theme.self) private var theme

    private struct EmojiData: Identifiable {
        init(emoji: String, base: String) {
            self.emoji = emoji
            self.base = base
            self.id = UUID()
        }

        var emoji: String
        var base: String
        var id: UUID
    }

    private enum Genre: UInt8, CaseIterable, Identifiable {
        /// 最近使った絵文字
        case recent

        /// 😁👪👩‍🦼👩‍💻
        case smileys

        /// 🐱🍄☀️🔥
        case natures

        /// ☕️🍰🍉🍞
        case eats

        /// ⚽️🏄🥇🎲
        case activities

        /// 🚗🏔🌊🚥
        case trips

        /// 🗒💽🔍💻
        case items

        /// ♌️❤️💮🎵
        case symbols

        /// 🏳️‍🌈🇯🇵🇺🇳🇰🇷
        case flags

        var id: UInt8 {
            self.rawValue
        }

        var icon: String {
            switch self {
            case .smileys:
                return "face.smiling"
            case .natures:
                return "fish"
            case .eats:
                return "fork.knife"
            case .activities:
                return "soccerball"
            case .trips:
                return "building.columns"
            case .items:
                return "lightbulb"
            case .symbols:
                return "exclamationmark.questionmark"
            case .flags:
                return "flag"
            case .recent:
                return "clock"
            }
        }

        var title: LocalizedStringKey {
            switch self {
            case .smileys:
                return "顔と感情"
            case .natures:
                return "生き物と自然"
            case .eats:
                return "食事"
            case .activities:
                return "アクティビティ"
            case .trips:
                return "旅行と場所"
            case .items:
                return "物"
            case .symbols:
                return "記号"
            case .flags:
                return "旗"
            case .recent:
                return "よく使う絵文字"
            }
        }

        var next: Genre? {
            switch self {
            case .recent:
                return .smileys
            case .smileys:
                return .natures
            case .natures:
                return .eats
            case .eats:
                return .activities
            case .activities:
                return .trips
            case .trips:
                return .items
            case .items:
                return .symbols
            case .symbols:
                return .flags
            case .flags:
                return nil
            }
        }

        var prev: Genre? {
            switch self {
            case .recent:
                return nil
            case .smileys:
                return .recent
            case .natures:
                return .smileys
            case .eats:
                return .natures
            case .activities:
                return .eats
            case .trips:
                return .activities
            case .items:
                return .trips
            case .symbols:
                return .items
            case .flags:
                return .symbols
            }
        }
    }

    /// 参考用
    private var keysHeight: CGFloat {
        TabDependentDesign(width: 1, height: 1, interfaceSize: variableStates.interfaceSize, orientation: variableStates.keyboardOrientation).keysHeight
    }

    private var scrollViewHeight: CGFloat {
        keysHeight * 0.85
    }

    private var footerHeight: CGFloat {
        keysHeight * 0.15
    }

    private var verticalCount: Int {
        switch self.expandLevel {
        case .small:
            switch variableStates.keyboardOrientation {
            case .vertical: return 6
            case .horizontal: return 4
            }
        case .medium:
            switch variableStates.keyboardOrientation {
            case .vertical: return 5
            case .horizontal: return 3
            }
        case .large:
            switch variableStates.keyboardOrientation {
            case .vertical: return 3
            case .horizontal: return 2
            }
        }
    }

    private var allGenre: [Genre] {
        Genre.allCases.sorted(by: {$0.rawValue < $1.rawValue})
    }

    @State private var emojis: [Genre: [EmojiData]] = [:]

    @State private var selectedGenre: Genre = .smileys

    @State private var expandLevel: EmojiTabExpandModePreference.Level = .large

    init() {}
    // 正方形のキーにする
    private var keySize: CGFloat {
        scrollViewHeight / CGFloat(verticalCount)
    }

    private static func getEmojiDataItem(for emoji: String, replacements: [String: String]) -> EmojiData {
        .init(emoji: replacements[emoji, default: emoji], base: emoji)
    }

    private static func getEmojis(keyboardInternalSettingManager: KeyboardInternalSettingManager) -> [Genre: [EmojiData]] {
        let fileURL: URL
        // 読み込むファイルはバージョンごとに変更する必要がある
        if #available(iOS 26.4, *) {
            fileURL = Bundle.main.bundleURL.appendingPathComponent("emoji_genre_E17.0.txt", isDirectory: false)
        } else if #available(iOS 18.4, *) {
            fileURL = Bundle.main.bundleURL.appendingPathComponent("emoji_genre_E16.0.txt", isDirectory: false)
        } else {
            // in this case, always satisfies #available(iOS 17.4, *)
            fileURL = Bundle.main.bundleURL.appendingPathComponent("emoji_genre_E15.1.txt", isDirectory: false)
        }
        let genres: [String: Genre] = [
            "Symbols": .symbols,
            "Flags": .flags,
            "Food & Drink": .eats,
            "Smileys & People": .smileys,
            "Activities": .activities,
            "Animals & Nature": .natures,
            "Travel & Places": .trips,
            "Objects": .items,
        ]
        let ignoredGenre = ["Component"]
        var emojis: [Genre: [String]] = [:]
        do {
            let string = try String(contentsOf: fileURL, encoding: .utf8)
            let lines = string.split(separator: "\n")
            for line in lines {
                let splited = line.split(separator: "\t", omittingEmptySubsequences: false)
                guard splited.count == 2 else {
                    debug("error", line)
                    return [:]
                }
                if ignoredGenre.contains(String(splited[0])) {
                    continue
                }
                guard let genre = genres[String(splited[0])] else {
                    debug("unknown genre", line)
                    return [:]
                }
                emojis[genre, default: []].append(contentsOf: splited[1].split(separator: ",").map(String.init))
            }
        } catch {
            debug(error)
            return [:]
        }
        let preference = keyboardInternalSettingManager.tabCharacterPreference
        let recentlyUsed = preference.getRecentlyUsed(for: .system(.emoji), count: 49)
        emojis[.recent] = recentlyUsed

        let replacements = preference.getPreferences(for: .system(.emoji))
        return emojis.mapValues {
            $0.map {
                getEmojiDataItem(for: $0, replacements: replacements)
            }
        }
    }

    private var functionKeyWidth: CGFloat {
        variableStates.interfaceSize.width / 13
    }

    private func deleteKey() -> SimpleKeyView<Extension> {
        SimpleKeyView(model: SimpleKeyModel<Extension>(keyLabelType: .image("delete.left"), unpressedKeyColorType: .special, pressActions: [.delete(1)], longPressActions: .init(repeat: [.delete(1)])), width: functionKeyWidth, height: footerHeight)
    }

    private func expandKey() -> SimpleKeyView<Extension> {
        SimpleKeyView(model: ExpandKeyModel<Extension>(currentLevel: expandLevel, action: {
            let newValue = expandLevel.next()
            self.expandLevel = newValue
            variableStates.keyboardInternalSettingManager.update(\.emojiTabExpandModePreference) { value in
                value.level = newValue
            }
        }), width: functionKeyWidth, height: footerHeight)
    }

    private func backTabKey() -> SimpleKeyView<Extension> {
        SimpleKeyView(model: SimpleKeyModel<Extension>(keyLabelType: .text("戻る"), unpressedKeyColorType: .special, pressActions: [.moveTab(.system(.last_tab))], longPressActions: .none), width: functionKeyWidth * 2, height: footerHeight)
    }

    private func genreKey(_ genre: Genre) -> some View {
        SimpleKeyView<Extension>(model: GenreKeyModel<Extension>(systemImage: genre.icon, unpressedKeyColorType: genre == selectedGenre ? .selected : .unimportant, action: { self.selectedGenre = genre }), width: functionKeyWidth, height: footerHeight)
    }

    private func switchGenreButton(genre: Genre, systemImage: String) -> some View {
        Button {
            self.selectedGenre = genre
        } label: {
            Label(genre.title, systemImage: systemImage)
                .labelStyle(.iconOnly)
                .font(.largeTitle)
                .foregroundStyle(theme.resultTextColor.color)
                .frame(width: footerHeight, height: scrollViewHeight)
                .contentShape(Rectangle())
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                ScrollViewReader { reader in
                    let gridItem = GridItem(.fixed(keySize), spacing: 0)
                    HStack {
                        if let prev = selectedGenre.prev {
                            switchGenreButton(genre: prev, systemImage: "chevron.left")
                        }
                        LazyHGrid(rows: Array(repeating: gridItem, count: verticalCount), spacing: 0) {
                            let models = self.emojis[selectedGenre, default: []]
                            if !models.isEmpty {
                                SimpleKeyView<Extension>(model: SimpleKeyModel<Extension>(keyLabelType: .image(selectedGenre.icon), unpressedKeyColorType: .selected, pressActions: []), width: keySize, height: keySize)
                                    .id(0)
                                ForEach(models) { model in
                                    SimpleKeyView<Extension>(model: EmojiKeyModel<Extension>(model.emoji, base: model.base), width: keySize, height: keySize)
                                }
                            }
                        }
                        .onChange(of: selectedGenre) { (_, _) in
                            reader.scrollTo(0)
                        }
                        .padding(.vertical, 0)
                        .padding(.horizontal, 5)
                        if let next = selectedGenre.next {
                            switchGenreButton(genre: next, systemImage: "chevron.right")
                        }
                    }
                }
            }
            .frame(height: scrollViewHeight)

            HStack(spacing: 0) {
                backTabKey()
                ForEach(allGenre, id: \.self) { genre in
                    if !self.emojis[genre, default: []].isEmpty {
                        genreKey(genre)
                    }
                }
                deleteKey()
                expandKey()
            }
            .labelStyle(.iconOnly)
            .frame(height: footerHeight)
        }
        .frame(width: variableStates.interfaceSize.width)
        .onChange(of: self.selectedGenre) { (_, _) in
            self.updateEmojiData()
        }
        .onAppear {
            self.updateEmojiData()
            self.expandLevel = variableStates.keyboardInternalSettingManager.emojiTabExpandModePreference.level
            if !self.emojis[.recent, default: []].isEmpty {
                self.selectedGenre = .recent
            }
            variableStates.resultModel.setResults([])
            variableStates.barState = .none
        }
        .onDisappear {
            variableStates.resultModel.setResults([])
        }
    }

    /// Recently Usedなどは更新される
    /// - note: 更新頻度が高すぎると使い辛いので、あまり頻繁に呼ばない方がよい。表示を切り替えた場面などに限るとよい
    private func updateEmojiData() {
        self.emojis = Self.getEmojis(keyboardInternalSettingManager: variableStates.keyboardInternalSettingManager)
    }
}

private struct ExpandKeyModel<Extension: ApplicationSpecificKeyboardViewExtension>: SimpleKeyModelProtocol {
    private var currentLevel: EmojiTabExpandModePreference.Level
    private var action: () -> Void
    func label(width: CGFloat, states: VariableStates) -> KeyLabel<Extension> {
        KeyLabel(.image(self.currentLevel.icon), width: width, textSize: .max)
    }

    init(currentLevel: EmojiTabExpandModePreference.Level, action: @escaping () -> Void) {
        self.currentLevel = currentLevel
        self.action = action
    }
    let unpressedKeyColorType: SimpleUnpressedKeyColorType = .special

    func pressActions(variableStates: VariableStates) -> [ActionType] {
        []
    }
    func longPressActions(variableStates: VariableStates) -> LongpressActionType {
        .none
    }
    func feedback(variableStates: VariableStates) {
        KeyboardFeedback<Extension>.tabOrOtherKey()
    }
    func additionalOnPress(variableStates: VariableStates) {
        self.action()
    }
}

private struct GenreKeyModel<Extension: ApplicationSpecificKeyboardViewExtension>: SimpleKeyModelProtocol {
    private var action: () -> Void
    private var systemImage: String
    func label(width: CGFloat, states: VariableStates) -> KeyLabel<Extension> {
        KeyLabel(.image(systemImage), width: width, textSize: .max)
    }

    init(systemImage: String, unpressedKeyColorType: SimpleUnpressedKeyColorType, action: @escaping () -> Void) {
        self.action = action
        self.systemImage = systemImage
        self.unpressedKeyColorType = unpressedKeyColorType
    }
    let unpressedKeyColorType: SimpleUnpressedKeyColorType

    func pressActions(variableStates: VariableStates) -> [ActionType] {
        []
    }
    func longPressActions(variableStates: VariableStates) -> LongpressActionType {
        .none
    }
    func feedback(variableStates: VariableStates) {
        KeyboardFeedback<Extension>.tabOrOtherKey()
    }
    func additionalOnPress(variableStates: VariableStates) {
        self.action()
    }
}

private struct EmojiKeyModel<Extension: ApplicationSpecificKeyboardViewExtension>: SimpleKeyModelProtocol {
    init(_ emoji: String, base: String) {
        self.emoji = emoji
        self.base = base
    }

    private let emoji: String
    private let base: String
    var unpressedKeyColorType: SimpleUnpressedKeyColorType {
        .unimportant
    }
    var longPressActions: LongpressActionType {
        .none
    }
    func label(width: CGFloat, states _: VariableStates) -> KeyLabel<Extension> {
        KeyLabel(.text(emoji), width: width, textSize: .max)
    }

    func additionalOnPress(variableStates: VariableStates) {
        variableStates.keyboardInternalSettingManager.update(\.tabCharacterPreference) { value in
            value.setUsed(base: self.base, for: .system(.emoji))
        }
    }
    func pressActions(variableStates: VariableStates) -> [ActionType] {
        [.input(emoji)]
    }
    func longPressActions(variableStates: VariableStates) -> LongpressActionType {
        .none
    }
    func feedback(variableStates: VariableStates) {
        KeyboardFeedback<Extension>.click()
    }
}

private extension EmojiTabExpandModePreference.Level {
    func next() -> Self {
        switch self {
        case .small: return .medium
        case .medium: return .large
        case .large: return .small
        }
    }

    var icon: String {
        switch self {
        case .small:
            return "arrow.up.left.and.arrow.down.right"
        case .medium:
            return "arrow.up.left.and.arrow.down.right"
        case .large:
            return "arrow.down.right.and.arrow.up.left"
        }
    }
}
