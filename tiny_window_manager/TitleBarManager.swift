//
//  TitleBarManager.swift
//  tiny_window_manager
//
//  This file handles double-clicking on window title bars to trigger window actions.
//  For example, users can configure double-clicking a title bar to maximize the window.
//
//  Note: This only works when macOS's built-in "Double-click a window's title bar to"
//  setting is set to "Do Nothing" in System Settings > Desktop & Dock.
//

import Foundation

// MARK: - TitleBarManager Class

/// Monitors mouse events to detect double-clicks on window title bars.
///
/// When the user double-clicks a window's title bar, this class can trigger
/// a configured window action (like maximize, left half, etc.).
///
/// ## How it works:
/// 1. Listens for left mouse button releases (to detect double-clicks)
/// 2. Checks if the click was on a title bar (not the window content)
/// 3. Triggers the user's configured action for that double-click
///
/// ## Requirements:
/// - macOS's built-in title bar double-click action must be disabled
/// - User must have configured a double-click action in settings
class TitleBarManager {

    // MARK: - Properties

    /// Monitors mouse events passively (doesn't block other handlers)
    private var eventMonitor: EventMonitor!

    /// Tracks the last event we processed to avoid handling the same click twice.
    /// macOS can send duplicate events, so we use this to deduplicate.
    private var lastEventNumber: Int?

    // MARK: - Initialization

    init() {
        // Set up a passive monitor for left mouse button releases
        // (Double-clicks are detected by checking clickCount == 2 on mouse up)
        eventMonitor = PassiveEventMonitor(mask: .leftMouseUp, handler: handle)

        // Start or stop listening based on whether feature is enabled
        toggleListening()

        // Re-check when settings change
        Notification.Name.windowTitleBar.onPost { notification in
            self.toggleListening()
        }
        Notification.Name.configImported.onPost { notification in
            self.toggleListening()
        }
    }

    // MARK: - Private Methods

    /// Starts or stops event monitoring based on user settings.
    /// If no action is configured for double-click, we don't need to listen.
    private func toggleListening() {
        let hasConfiguredAction = WindowAction(rawValue: Defaults.doubleClickTitleBar.value - 1) != nil

        if hasConfiguredAction {
            eventMonitor.start()
        } else {
            eventMonitor.stop()
        }
    }

    /// Called for every left mouse button release. Filters to find title bar double-clicks.
    private func handle(_ event: NSEvent) {
        // STEP 1: Basic event validation
        // ─────────────────────────────────────────────────────────────────────
        guard
            event.type == .leftMouseUp,
            event.clickCount == 2,                                    // Must be a double-click
            event.eventNumber != lastEventNumber,                      // Avoid duplicate events
            TitleBarManager.systemSettingDisabled,                     // macOS setting must be "None"
            let action = WindowAction(rawValue: Defaults.doubleClickTitleBar.value - 1)
        else {
            return
        }

        // STEP 2: Find what UI element was clicked
        // ─────────────────────────────────────────────────────────────────────
        let clickLocation = NSEvent.mouseLocation.screenFlipped

        guard
            let element = AccessibilityElement(clickLocation)?.getSelfOrChildElementRecursively(clickLocation),
            let windowElement = element.windowElement,
            var titleBarFrame = windowElement.titleBarFrame
        else {
            return
        }

        // Remember this event to avoid processing it twice
        lastEventNumber = event.eventNumber

        // STEP 3: Get the app's bundle identifier (for ignore lists)
        // ─────────────────────────────────────────────────────────────────────
        var bundleIdentifier: String?
        if let pid = element.pid {
            bundleIdentifier = NSRunningApplication(processIdentifier: pid)?.bundleIdentifier
        }

        // STEP 4: Expand title bar to include toolbar (if applicable)
        // ─────────────────────────────────────────────────────────────────────
        // Some apps have toolbars that are visually part of the title bar area.
        // We expand our hit-testing area to include these, unless the app is ignored.
        if let toolbarFrame = windowElement.getChildElement(.toolbar)?.frame, toolbarFrame != .null {
            let isToolbarIgnoredForThisApp = bundleIdentifier != nil
                && Defaults.doubleClickToolBarIgnoredApps.typedValue?.contains(bundleIdentifier!) == true

            if !isToolbarIgnoredForThisApp {
                titleBarFrame = titleBarFrame.union(toolbarFrame)
            }
        }

        // STEP 5: Verify click is in title bar and on valid UI element type
        // ─────────────────────────────────────────────────────────────────────
        let isClickInTitleBar = titleBarFrame.contains(clickLocation)
        let isValidElementType = element.isWindow == true
            || element.isToolbar == true
            || element.isGroup == true
            || element.isTabGroup == true
            || element.isStaticText == true

        guard isClickInTitleBar && isValidElementType else {
            return
        }

        // STEP 6: Check if this app is in the ignore list
        // ─────────────────────────────────────────────────────────────────────
        if let bundleIdentifier,
           let ignoredApps = Defaults.doubleClickTitleBarIgnoredApps.typedValue,
           ignoredApps.contains(bundleIdentifier) {
            return
        }

        // STEP 7: Handle "restore on second double-click" feature
        // ─────────────────────────────────────────────────────────────────────
        // If the window is already in the position from a previous double-click,
        // double-clicking again restores it to its original position.
        if Defaults.doubleClickTitleBarRestore.enabled != false,
           let windowId = windowElement.windowId,
           case let windowFrame = windowElement.frame,
           windowFrame != .null,
           let historyAction = AppDelegate.windowHistory.lasttiny_window_managerActions[windowId],
           historyAction.action == action,
           historyAction.rect == windowFrame {
            // Window is in the same position as the last action - restore instead
            WindowAction.restore.postTitleBar(windowElement: windowElement)
            return
        }

        // STEP 8: Trigger the configured action
        // ─────────────────────────────────────────────────────────────────────
        action.postTitleBar(windowElement: windowElement)
    }
}

// MARK: - System Settings Check

extension TitleBarManager {

    /// Checks if macOS's built-in title bar double-click action is disabled.
    ///
    /// This feature only works when the system setting "Double-click a window's
    /// title bar to" (in System Settings > Desktop & Dock) is set to "Do Nothing".
    ///
    /// If the user has it set to "Zoom" or "Minimize", macOS will handle the
    /// double-click and our handler won't work properly.
    static var systemSettingDisabled: Bool {
        // Read the global macOS preference for title bar double-click behavior
        let globalPrefs = UserDefaults(suiteName: ".GlobalPreferences")
        let setting = globalPrefs?.string(forKey: "AppleActionOnDoubleClick")
        return setting == "None"
    }
}
