import SwiftUI

@main
struct MainApp: App {
    @StateObject private var router = AppRouter()
    @StateObject private var keyboardConfiguration = KeyboardConfigurationState()
    @StateObject private var onboarding = OnboardingState()
    @StateObject private var reviewPrompt = RequestReviewManager()
    @StateObject private var customizationWalkthrough = CustomizationWalkthroughState()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(router)
                .environmentObject(keyboardConfiguration)
                .environmentObject(onboarding)
                .environmentObject(reviewPrompt)
                .environmentObject(customizationWalkthrough)
                .onAppear {
                    AppLaunchTasks.performInitialSetup()
                }
        }
    }
}
