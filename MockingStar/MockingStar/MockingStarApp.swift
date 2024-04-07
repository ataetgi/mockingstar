//
//  MockingStarApp.swift
//  MockingStar
//
//  Created by Yusuf Özgül on 25.07.2023.
//

import CommonKit
import CommonViewsKit
import JSONEditor
import MockingStarCore
import SwiftUI
import TipKit

@main
struct MockingStarApp: App {

    init() {
        try? Tips.configure([
            .datastoreLocation(.applicationDefault),
        ])
    }

    var body: some Scene {
        WindowGroup {
            AppNavigationSplitView()
                .environment(NavigationStore.shared)
                .environment(MockDomainDiscover())
                .environment(NotificationManager.shared)
                .task {
                    await MainActor.run {
                        JSONEditorView.warmUp()
                    }
                }
        }
        .defaultSize(width: (NSScreen.main?.visibleFrame.size.width ?? 1000) / 1.5, height: (NSScreen.main?.visibleFrame.size.height ?? 600) / 1.5)
        .commands {
            SidebarCommands()
            MenubarCommands()
        }

        Window("Mocking Star Playground", id: "quick-demo") {
            QuickDemo()
        }

        Settings {
            SettingsView()
        }
    }
}
