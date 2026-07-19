import AzooKeyUtils
import SwiftUI

@MainActor
final class OnboardingState: ObservableObject {
    @Published private(set) var isKeyboardActivated: Bool
    @Published var isPresented: Bool

    var resumeProgress: EnableAzooKeyViewProgress? {
        if isKeyboardActivated, !tutorialFinishedSuccessfully {
            return .setting
        }
        return nil
    }

    init() {
        let isKeyboardActivated = SharedStore.checkKeyboardActivation()
        self.isKeyboardActivated = isKeyboardActivated
        self.isPresented = !isKeyboardActivated
    }

    func present() {
        isPresented = true
    }

    func dismiss() {
        isPresented = false
    }

    func presentInterruptedTutorialIfNeeded() {
        if isKeyboardActivated, !tutorialFinishedSuccessfully {
            isPresented = true
        }
    }

    func setTutorialProgress(_ progress: EnableAzooKeyViewProgress) {
        UserDefaults.standard.set(progress.rawValue, forKey: "tutorial_progress")
    }

    func markKeyboardActivated() {
        isKeyboardActivated = true
    }

    private var tutorialFinishedSuccessfully: Bool {
        guard let progressString = UserDefaults.standard.string(forKey: "tutorial_progress"),
              let progress = EnableAzooKeyViewProgress(rawValue: progressString) else {
            return true
        }
        return progress == .finish
    }
}
