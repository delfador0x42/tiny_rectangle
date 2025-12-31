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

    var body: some Scene {
        // Settings window (Preferences)
        Settings {
            PreferencesView()
        }
    }
}
