import AzooKeyUtils
import KeyboardViews
import SwiftUI

@MainActor
final class KeyboardConfigurationState: ObservableObject {
    @Published var japaneseLayout: LanguageLayout
    @Published var englishLayout: LanguageLayout
    @Published var custardManager: CustardManager

    init() {
        @KeyboardSetting(.japaneseKeyboardLayout) var japaneseKeyboardLayout
        @KeyboardSetting(.englishKeyboardLayout) var englishKeyboardLayout

        self.japaneseLayout = japaneseKeyboardLayout
        self.englishLayout = englishKeyboardLayout
        self.custardManager = CustardManager.load()

        SemiStaticStates.shared.setHapticsAvailable()
        SemiStaticStates.shared.setScreenWidth(UIScreen.main.bounds.width)
    }
}
