//  AppDelegate+Todo.swift - Todo mode feature
//
//  This file handles the todo mode feature initialization and actions.
//  Menu items are now displayed via SwiftUI in MenuBarView.swift.

import Cocoa

// MARK: - Todo Mode Feature

/// Extension handling the "Todo Mode" feature - keeps a designated app's window
/// visible in a corner while you work.
extension AppDelegate {

    /// Sets up or refreshes the todo mode feature.
    func initializeTodo(_ bringToFront: Bool = true) {
        TodoManager.registerUnregisterToggleShortcut()
        TodoManager.registerUnregisterReflowShortcut()
        TodoManager.moveAllIfNeeded(bringToFront)
    }
}
