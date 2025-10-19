import CustardKit

public extension Custard {
    static let flickJapanese = Custard(
        identifier: "japanese_flick",
        language: .ja_JP,
        input_style: .direct,
        metadata: .init(
            custard_version: .v1_2,
            display_name: "日本語フリック"
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
                    .flickSimpleInputs(center: "あ", left: "い", top: "う", right: "え", bottom: "お")
                ),
                .gridFit(.init(x: 1, y: 1)): .custom(
                    .flickSimpleInputs(center: "た", left: "ち", top: "つ", right: "て", bottom: "と")
                ),
                .gridFit(.init(x: 1, y: 2)): .custom(
                    .flickSimpleInputs(center: "ま", left: "み", top: "む", right: "め", bottom: "も")
                ),
                .gridFit(.init(x: 1, y: 3)): .system(.flickKogaki),
                // 3列目
                .gridFit(.init(x: 2, y: 0)): .custom(
                    .flickSimpleInputs(center: "か", left: "き", top: "く", right: "け", bottom: "こ")
                ),
                .gridFit(.init(x: 2, y: 1)): .custom(
                    .flickSimpleInputs(center: "な", left: "に", top: "ぬ", right: "ね", bottom: "の")
                ),
                .gridFit(.init(x: 2, y: 2)): .custom(
                    .flickSimpleInputs(center: "や", left: "「", top: "ゆ", right: "」", bottom: "よ")
                ),
                .gridFit(.init(x: 2, y: 3)): .custom(
                    .flickSimpleInputs(center: "わ", left: "を", top: "ん", right: "ー")
                ),
                // 4列目
                .gridFit(.init(x: 3, y: 0)): .custom(
                    .flickSimpleInputs(center: "さ", left: "し", top: "す", right: "せ", bottom: "そ")
                ),
                .gridFit(.init(x: 3, y: 1)): .custom(
                    .flickSimpleInputs(center: "は", left: "ひ", top: "ふ", right: "へ", bottom: "ほ")
                ),
                .gridFit(.init(x: 3, y: 2)): .custom(
                    .flickSimpleInputs(center: "ら", left: "り", top: "る", right: "れ", bottom: "ろ")
                ),
                .gridFit(.init(x: 3, y: 3)): .system(.flickKutoten),
                .gridFit(.init(x: 4, y: 0)): .custom(.flickDelete()),
                .gridFit(.init(x: 4, y: 1)): .custom(.flickSpace()),
                .gridFit(.init(x: 4, y: 2, width: 1, height: 2)): .system(.enter),
            ]
        )
    )
}
