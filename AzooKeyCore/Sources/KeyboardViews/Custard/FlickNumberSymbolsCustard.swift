import CustardKit

public extension Custard {
    static let flickNumberSymbols = Custard(
        identifier: "symbols_flick",
        language: .ja_JP,
        input_style: .direct,
        metadata: .init(
            custard_version: .v1_2,
            display_name: "記号フリック"
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
                    .flickSimpleInputs(center: "1", subs: ["☆", "♪", "→"])
                    .mainAndSubLabel()
                ),
                .gridFit(.init(x: 1, y: 1)): .custom(
                    .flickSimpleInputs(center: "4", subs: ["○", "＊", "・"])
                    .mainAndSubLabel()
                ),
                .gridFit(.init(x: 1, y: 2)): .custom(
                    .flickSimpleInputs(center: "7", subs: ["「", "」", ":"])
                    .mainAndSubLabel()
                ),
                .gridFit(.init(x: 1, y: 3)): .custom(
                    .flickSimpleInputs(center: "(", subs: [")", "[", "]"], centerLabel: "()[]")
                ),

                // 3列目
                .gridFit(.init(x: 2, y: 0)): .custom(
                    .flickSimpleInputs(center: "2", subs: ["¥", "$", "€"])
                    .mainAndSubLabel()
                ),
                .gridFit(.init(x: 2, y: 1)): .custom(
                    .flickSimpleInputs(center: "5", subs: ["+", "×", "÷"])
                    .mainAndSubLabel()
                ),
                .gridFit(.init(x: 2, y: 2)): .custom(
                    .flickSimpleInputs(center: "8", subs: ["〒", "々", "〆"])
                    .mainAndSubLabel()
                ),
                .gridFit(.init(x: 2, y: 3)): .custom(
                    .flickSimpleInputs(center: "0", subs: ["〜", "…"])
                    .mainAndSubLabel()
                ),

                // 4列目
                .gridFit(.init(x: 3, y: 0)): .custom(
                    .flickSimpleInputs(center: "3", subs: ["%", "°", "#"])
                    .mainAndSubLabel()
                ),
                .gridFit(.init(x: 3, y: 1)): .custom(
                    .flickSimpleInputs(center: "6", subs: ["<", "=", ">"])
                    .mainAndSubLabel()
                ),
                .gridFit(.init(x: 3, y: 2)): .custom(
                    .flickSimpleInputs(center: "9", subs: ["^", "|", "\\"])
                    .mainAndSubLabel()
                ),
                .gridFit(.init(x: 3, y: 3)): .custom(
                    .flickSimpleInputs(center: ".", subs: [",", "-", "/"], centerLabel: ".,-/")
                ),

                // 5列目
                .gridFit(.init(x: 4, y: 0)): .custom(.flickDelete()),
                .gridFit(.init(x: 4, y: 1)): .custom(.flickSpace()),
                .gridFit(.init(x: 4, y: 2, width: 1, height: 2)): .system(.enter),
            ]
        )
    )
}

private extension CustardInterfaceCustomKey {
    /// ベースカスタードを記述するためのヘルパー関数
    consuming func mainAndSubLabel() -> CustardInterfaceCustomKey {
        let center: String? = self.press_actions.first.flatMap {
            if case let .input(value) = $0 {
                value
            } else {
                nil
            }
        }
        let subs: [String] = self.variations.compactMap { (variation: CustardInterfaceVariation) in
            variation.key.press_actions.first.flatMap {
                if case let .input(value) = $0 {
                    value
                } else {
                    nil
                }
            }
        }
        if let center {
            self.design = .init(label: .mainAndSub(center, subs.joined()), color: .normal)
        }
        return self
    }

}
