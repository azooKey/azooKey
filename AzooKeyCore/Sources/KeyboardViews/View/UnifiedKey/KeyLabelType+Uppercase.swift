import CustardKit
import Foundation

extension KeyLabelType {
    func uppercasedForEnglishIfInputMatches(
        pressActions: [ActionType],
        flickMap: [FlickDirection: UnifiedVariation] = [:]
    ) -> Self {
        switch self {
        case let .text(text):
            return .text(text.uppercasedIfInputMatches(pressActions))
        case let .symbols(symbols):
            guard let main = symbols.first else {
                return self
            }
            return .symbols([main.uppercasedIfInputMatches(pressActions)] + symbols.dropFirst())
        case let .mainAndDirections(main, directions):
            return .mainAndDirections(
                main.uppercasedIfInputMatches(pressActions),
                CustardKeyDirectionalLabel(
                    left: directions.left?.uppercasedIfInputMatches(flickMap[.left]?.pressActions ?? []),
                    top: directions.top?.uppercasedIfInputMatches(flickMap[.top]?.pressActions ?? []),
                    right: directions.right?.uppercasedIfInputMatches(flickMap[.right]?.pressActions ?? []),
                    bottom: directions.bottom?.uppercasedIfInputMatches(flickMap[.bottom]?.pressActions ?? [])
                )
            )
        case .image, .customImage, .changeKeyboard, .selectable:
            return self
        }
    }
}

extension UnifiedVariation {
    func uppercasedForEnglishIfInputMatches() -> Self {
        UnifiedVariation(
            label: label.uppercasedForEnglishIfInputMatches(pressActions: pressActions),
            pressActions: pressActions,
            longPressActions: longPressActions
        )
    }
}

private extension String {
    func uppercasedIfInputMatches(_ actions: [ActionType]) -> Self {
        guard count == 1,
              actions.count == 1,
              case let .input(input, _) = actions[0],
              self == input else {
            return self
        }
        return uppercased()
    }
}
