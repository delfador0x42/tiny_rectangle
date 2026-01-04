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

    // Access shared menu state - uses @Bindable for bindings with @Observable
    @Bindable private var menuState = MenuBarState.shared

    init() {
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
                    .onAppear {
                        menuState.refresh()
                    }
            } else {
                UnauthorizedMenuView()
            }
        } label: {
            Image("StatusTemplate")
                .renderingMode(.template)
        }
        .menuBarExtraStyle(.menu)

        // Settings window (Preferences)
        Settings {
            PreferencesView()
        }
    }
}
