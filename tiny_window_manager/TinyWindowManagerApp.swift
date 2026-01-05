//
//  TinyWindowManagerApp.swift
//  tiny_window_manager
//
//  SwiftUI App entry point with MenuBarExtra for the status menu.
//  Uses modern @Observable pattern (macOS 14+) for state management.
//

import SwiftUI

@main
struct TinyWindowManagerApp: App {
    // Bridge to existing AppDelegate for core functionality
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // App services container for dependency injection
    private let services = AppServices.shared

    // Access menu state via services
    @Bindable private var menuState: MenuBarState

    init() {
        // Initialize menuState from services
        self._menuState = Bindable(AppServices.shared.menuBarState)

        // Require macOS 15.0 or later
        if #unavailable(macOS 15.0) {
            let alert = NSAlert()
            alert.messageText = "macOS 15.0 Required"
            alert.informativeText = "This app requires macOS 15.0 (Sequoia) or later. Please update your operating system."
            alert.alertStyle = .critical
            alert.addButton(withTitle: "Quit")
            alert.runModal()
            NSApp.terminate(nil)
        }
    }

    var body: some Scene {
        // Menu Bar Extra - replaces NSStatusItem
        MenuBarExtra(isInserted: $menuState.isMenuBarVisible) {
            if menuState.isAccessibilityAuthorized {
                MainMenuView()
                    .environment(services)
                    .onAppear {
                        menuState.refresh()
                    }
            } else {
                UnauthorizedMenuView()
                    .environment(services)
            }
        } label: {
            Image("StatusTemplate")
                .renderingMode(.template)
        }
        .menuBarExtraStyle(.menu)

        // Settings window (Preferences)
        Settings {
            PreferencesView()
                .environment(services)
        }
    }
}
