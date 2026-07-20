import CustardKit

public enum StandardKeyboardCatalog {
    public static let standardTabs: [TabData.SystemTab] = [
        .flick_japanese,
        .flick_english,
        .flick_numbersymbols,
        .qwerty_japanese,
        .qwerty_english,
        .qwerty_numbers,
        .qwerty_symbols,
    ]

    public struct Configuration: Equatable, Sendable {
        public init(
            useEnglishQwertyShiftKey: Bool,
            useDeprecatedEnglishQwertyShiftKeyBehavior: Bool,
            numberTabCustomKeys: QwertyCustomKeysValue
        ) {
            self.useEnglishQwertyShiftKey = useEnglishQwertyShiftKey
            self.useDeprecatedEnglishQwertyShiftKeyBehavior =
                useDeprecatedEnglishQwertyShiftKeyBehavior
            self.numberTabCustomKeys = numberTabCustomKeys
        }

        public var useEnglishQwertyShiftKey: Bool
        public var useDeprecatedEnglishQwertyShiftKeyBehavior: Bool
        public var numberTabCustomKeys: QwertyCustomKeysValue

        public static let `default` = Self(
            useEnglishQwertyShiftKey: false,
            useDeprecatedEnglishQwertyShiftKeyBehavior: false,
            numberTabCustomKeys: .defaultValue
        )
    }

    public static func custard(
        for tab: TabData.SystemTab,
        configuration: Configuration
    ) -> Custard {
        switch tab {
        case .flick_japanese:
            .flickJapanese
        case .flick_english:
            .flickEnglish
        case .flick_numbersymbols:
            .flickNumberSymbols
        case .qwerty_japanese:
            .qwertyJapanese
        case .qwerty_english:
            .qwertyEnglish(
                useShiftKey: configuration.useEnglishQwertyShiftKey,
                useDeprecatedShiftKeyBehavior:
                    configuration
                        .useDeprecatedEnglishQwertyShiftKeyBehavior
            )
        case .qwerty_numbers:
            .qwertyNumbers(
                customKeys: configuration.numberTabCustomKeys
            )
        case .qwerty_symbols:
            .qwertySymbols
        case .user_japanese,
             .user_english,
             .last_tab,
             .clipboard_history_tab,
             .emoji_tab:
            preconditionFailure("\(tab) is not a standard keyboard")
        }
    }

    public static func templates(
        configuration: Configuration
    ) -> [Custard] {
        standardTabs.map {
            custard(for: $0, configuration: configuration)
        }
    }
}
