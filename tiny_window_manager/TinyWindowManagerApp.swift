//
//  TinyWindowManagerApp.swift
//  tiny_window_manager
//
//  SwiftUI App entry point that bridges to the existing AppDelegate.
//

import SwiftUI

@main
struct TinyWindowManagerApp: App {
    // Bridge to existing AppDelegate for all the complex functionality
    // (status bar, accessibility, shortcuts, URL schemes, etc.)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        // Require macOS 14.0 or later
        if #unavailable(macOS 14.0) {
            let alert = NSAlert()
            alert.messageText = "macOS 14.0 Required"
            alert.informativeText = "This app requires macOS 14.0 (Sonoma) or later. Please update your operating system."
            alert.alertStyle = .critical
            alert.addButton(withTitle: "Quit")
            alert.runModal()
            NSApp.terminate(nil)
        }
    }

    var body: some Scene {
        // Settings window (Preferences)
        Settings {
            PreferencesView()
        }
    }
}
