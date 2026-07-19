//
//  AppRootView.swift
//  MainApp
//
//  Created by ensan on 2020/09/03.
//  Copyright © 2020 ensan. All rights reserved.
//

import SwiftUI

@MainActor
struct AppRootView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var keyboardConfiguration: KeyboardConfigurationState
    @EnvironmentObject private var onboarding: OnboardingState
    @EnvironmentObject private var customizationWalkthrough: CustomizationWalkthroughState

    var body: some View {
        ZStack {
            AppTabView()
            .onAppear {
                onboarding.presentInterruptedTutorialIfNeeded()
            }
            .task {
                await AppLaunchTasks.performMaintenance()
            }
            .fullScreenCover(isPresented: $onboarding.isPresented, content: {
                EnableAzooKeyView(resumeProgress: onboarding.resumeProgress)
            })
            .onChange(of: router.selectedTab) { _, selectedTab in
                if selectedTab == .customization {
                    customizationWalkthrough.presentIfNeeded()
                }
            }
            .onOpenURL(perform: router.open)
            .sheet(isPresented: $customizationWalkthrough.isPresented, onDismiss: {
                customizationWalkthrough.markDone()
            }, content: {
                CustomizationWalkthroughView()
                    .background(Color.background)
            })
            AppDataUpdateOverlay()
            if router.importedFileURL != nil {
                URLImportCustardView(
                    manager: $keyboardConfiguration.custardManager,
                    url: $router.importedFileURL
                )
            }
        }
    }
}
