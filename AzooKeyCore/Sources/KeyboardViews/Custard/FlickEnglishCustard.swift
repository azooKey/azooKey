import CustardKit

public extension Custard {
    static let flickEnglish = Custard(
        identifier: "english_flick",
        language: .en_US,
        input_style: .direct,
        metadata: .init(
            custard_version: .v1_2,
            display_name: "英語フリック"
        ),
        interface: CustardInterface(
            keyStyle: .tenkeyStyle,
            keyLayout: .gridFit(.init(rowCount: 5, columnCount: 4)),
            keys: [
                // 1列目
                .gridFit(.init(x: 0, y: 0)): .system(.flickStar123Tab),
                .gridFit(.init(x: 0, y: 1)): .system(.flickAbcTab),
                .gridFit(.init(x: 0, y: 2)): .system(.flickHiraTab),
                .gridFit(.init(x: 0, y: 3)): .system(.changeKeyboard),

                // 2列目
                .gridFit(.init(x: 1, y: 0)): .custom(
                    .flickSimpleInputs(center: "@", subs: ["#", "/", "&", "_"], centerLabel: "@#/&_")
                ),
                .gridFit(.init(x: 1, y: 1)): .custom(
                    .flickSimpleInputs(center: "G", subs: ["H", "I"], centerLabel: "GHI")
                    .lowercasedInput()
                ),
                .gridFit(.init(x: 1, y: 2)): .custom(
                    .flickSimpleInputs(center: "P", subs: ["Q", "R", "S"], centerLabel: "PQRS")
                    .lowercasedInput()
                ),
                .gridFit(.init(x: 1, y: 3)): .system(.upperLower),   // a/A (大文字・小文字切替)

                // 3列目
                    .gridFit(.init(x: 2, y: 0)): .custom(
                        .flickSimpleInputs(center: "A", subs: ["B", "C"], centerLabel: "ABC")
                        .lowercasedInput()
                    ),
                .gridFit(.init(x: 2, y: 1)): .custom(
                    .flickSimpleInputs(center: "J", subs: ["K", "L"], centerLabel: "JKL")
                    .lowercasedInput()
                ),
                .gridFit(.init(x: 2, y: 2)): .custom(
                    .flickSimpleInputs(center: "T", subs: ["U", "V"], centerLabel: "TUV")
                    .lowercasedInput()
                ),
                .gridFit(.init(x: 2, y: 3)): .custom(
                    .flickSimpleInputs(center: "'", subs: ["\"", "(", ")"], centerLabel: "'\"()")
                ),

                // 4列目
                .gridFit(.init(x: 3, y: 0)): .custom(
                    .flickSimpleInputs(center: "D", subs: ["E", "F"], centerLabel: "DEF")
                    .lowercasedInput()
                ),
                .gridFit(.init(x: 3, y: 1)): .custom(
                    .flickSimpleInputs(center: "M", subs: ["N", "O"], centerLabel: "MNO")
                    .lowercasedInput()
                ),
                .gridFit(.init(x: 3, y: 2)): .custom(
                    .flickSimpleInputs(center: "W", subs: ["X", "Y", "Z"], centerLabel: "WXYZ")
                    .lowercasedInput()
                ),
                .gridFit(.init(x: 3, y: 3)): .custom(
                    .flickSimpleInputs(center: ".", subs: [",", "?", "!"], centerLabel: ".,?!")
                ),

                // 5列目 (システムキー列)
                .gridFit(.init(x: 4, y: 0)): .custom(.flickDelete()),
                .gridFit(.init(x: 4, y: 1)): .custom(.flickSpace()),
                .gridFit(.init(x: 4, y: 2, width: 1, height: 2)): .system(.enter),
            ]
        )
    )
}

private extension CustardInterfaceCustomKey {
    /// 小文字カスタードを記述するためのヘルパー関数
    consuming func lowercasedInput() -> CustardInterfaceCustomKey {
        let transform: (CodableActionData) -> CodableActionData = {
            switch $0 {
            case .input(let value): .input(value.lowercased())
            default: $0
            }
        }
        self.press_actions = self.press_actions.map(transform)
        self.longpress_actions.start = self.longpress_actions.start.map(transform)
        self.longpress_actions.repeat = self.longpress_actions.repeat.map(transform)
        self.variations.mutatingForEach { variation in
            variation.key.press_actions = variation.key.press_actions.map(transform)
            variation.key.longpress_actions.start = variation.key.longpress_actions.start.map(transform)
            variation.key.longpress_actions.repeat = variation.key.longpress_actions.repeat.map(transform)
        }
        return self
    }
}
