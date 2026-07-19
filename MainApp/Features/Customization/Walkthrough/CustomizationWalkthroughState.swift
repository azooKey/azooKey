import SwiftUI

@MainActor
final class CustomizationWalkthroughState: ObservableObject {
    @Published var isPresented = false
    private var internalSettings = ContainerInternalSetting()

    func presentIfNeeded() {
        if internalSettings.walkthroughState.shouldDisplay(identifier: .extensions) {
            isPresented = true
        }
    }

    func markDone() {
        internalSettings.update(\.walkthroughState) { value in
            value.done(identifier: .extensions)
        }
    }
}
