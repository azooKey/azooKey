import Foundation
import SwiftUI

@MainActor
final class AppRouter: ObservableObject {
    enum Tab: Hashable {
        case tips
        case theme
        case customization
        case settings
    }

    @Published var selectedTab: Tab = .tips
    @Published var settingsPath: [SettingsRoute] = []
    @Published var importedFileURL: URL?

    func open(_ url: URL) {
        if url.scheme?.lowercased() == "azookey" {
            let host = url.host?.lowercased()
            let lastPathComponent = url.lastPathComponent.lowercased()
            if host == "settings", lastPathComponent == "zenzai" {
                selectedTab = .settings
                settingsPath.append(.zenzai)
            }
            return
        }

        importedFileURL = url
    }
}
