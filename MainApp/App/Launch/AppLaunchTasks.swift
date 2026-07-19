import AzooKeyUtils
import KeyboardViews

enum AppLaunchTasks {
    @MainActor
    static func performInitialSetup() {
        SemiStaticStates.shared.setup()
        SharedStore.setInitialAppVersion()
        SharedStore.setLastAppVersion()

        var messageManager = MessageManager()
        messageManager.getMessagesContainerAppShouldMakeWhichDone().forEach {
            messageManager.done($0.id)
        }

        if let initialVersion = SharedStore.initialAppVersion, initialVersion > .azooKey_v2_2_2 {
            KeepDeprecatedShiftKeyBehavior.value = false
        }
    }

    @MainActor
    static func performMaintenance() async {
        do {
            try await HotfixDictionaryV1.updateIfRequired()
        } catch {
            print(error)
        }
        UserDictionaryMigrationRunner.runIfNeeded()
    }
}
