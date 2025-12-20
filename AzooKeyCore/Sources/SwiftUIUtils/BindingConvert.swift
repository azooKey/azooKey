import Foundation
import SwiftUI

public extension Binding where Value: Sendable {
    @MainActor
    func converted<T>(
        forward forwardConverter: @escaping (Value) -> T,
        backward backwardConverter: @escaping (T) -> Value
    ) -> Binding<T> {
        .init(
            get: {
                forwardConverter(self.wrappedValue)
            },
            set: {newValue in
                self.wrappedValue = backwardConverter(newValue)
            }
        )
    }
    func converted<Translator: Intertranslator>(_ translator: Translator) -> Binding<Translator.Second> where Translator.First == Value {
        .init(
            get: {
                translator.convert(self.wrappedValue)
            },
            set: {newValue in
                self.wrappedValue = translator.convert(newValue)
            }
        )
    }
}

public extension Binding where Value == Optional<String> {
    @MainActor
    func wrapped(default: String = "") -> Binding<String> {
        .init(
            get: {
                self.wrappedValue ?? `default`
            },
            set: {newValue in
                self.wrappedValue = newValue
            }
        )
    }
}
