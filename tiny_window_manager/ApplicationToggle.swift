//
//  ApplicationToggle.swift
//  tiny_window_manager
//
//  This file handles per-app enabling/disabling of window management features.
//
//  WHY THIS EXISTS:
//  ----------------
//  Some apps don't play well with window managers. For example:
//  - Games that use custom window handling
//  - Apps with their own window snapping (like some IDEs)
//  - Full-screen apps where shortcuts might interfere
//
//  This class lets users disable window management for specific apps.
//  When the user switches to a disabled app, shortcuts are automatically
//  turned off. When they switch back to a normal app, shortcuts turn back on.
//
//  HOW IT WORKS:
//  -------------
//  1. We maintain a Set of "disabled" bundle IDs (e.g., "com.apple.Safari")
//  2. We listen for macOS "app activated" notifications
//  3. When the frontmost app changes:
//     - If it's in the disabled list → unbind all keyboard shortcuts
//     - If it's NOT in the list → rebind all keyboard shortcuts
//
//  This happens automatically and seamlessly as the user switches apps.
//
//  BUNDLE IDS:
//  -----------
//  Every macOS app has a unique "bundle identifier" like "com.apple.Safari".
//  We use these IDs (not app names) because they're guaranteed to be unique
//  and don't change when the app is renamed or localized.
//

import Cocoa

// MARK: - Application Toggle Class

/// Manages per-application enabling/disabling of window management features.
///
/// This class:
/// - Tracks which apps have window management disabled
/// - Monitors which app is currently in the foreground
/// - Automatically enables/disables shortcuts when switching apps
///
/// Usage:
/// ```swift
/// // Disable window management for the current app
/// applicationToggle.disableApp()
///
/// // Re-enable it
/// applicationToggle.enableApp()
///
/// // Check if a specific app is disabled
/// if applicationToggle.isDisabled(bundleId: "com.apple.Safari") {
///     // Safari has window management disabled
/// }
/// ```
class ApplicationToggle: NSObject {

    // MARK: - Properties

    /// Set of bundle identifiers for apps where window management is disabled.
    /// Stored as JSON in UserDefaults via Defaults.disabledApps.
    private var disabledApps = Set<String>()

    /// The bundle identifier of the currently active (frontmost) application.
    /// Example: "com.apple.Safari"
    ///
    /// This is static so other parts of the app can check which app is active
    /// without needing a reference to this class.
    public private(set) static var frontAppId: String? = "com.knollsoft.tiny_window_manager"

    /// The display name of the currently active (frontmost) application.
    /// Example: "Safari"
    public private(set) static var frontAppName: String? = "tiny_window_manager"

    /// Whether keyboard shortcuts are currently disabled.
    /// True when the frontmost app is in the disabled list.
    public private(set) static var shortcutsDisabled: Bool = false

    /// Reference to the shortcut manager for binding/unbinding shortcuts.
    private let shortcutManager: ShortcutManager

    // MARK: - Initialization

    /// Creates an ApplicationToggle and starts monitoring app switches.
    ///
    /// - Parameter shortcutManager: The ShortcutManager to enable/disable shortcuts on.
    init(shortcutManager: ShortcutManager) {
        self.shortcutManager = shortcutManager
        super.init()

        // Start listening for app activation events
        registerFrontAppChangeNote()

        // Load the list of disabled apps from UserDefaults
        if let disabledApps = getDisabledApps() {
            self.disabledApps = disabledApps
        }
    }

    // MARK: - Public Methods

    /// Reloads the disabled apps list from UserDefaults.
    ///
    /// Call this after the user changes settings in the preferences UI
    /// to pick up any changes.
    public func reloadFromDefaults() {
        if let disabledApps = getDisabledApps() {
            self.disabledApps = disabledApps
        } else {
            disabledApps.removeAll()
        }
    }

    /// Disables window management for the specified app (or the current frontmost app).
    ///
    /// - Parameter appBundleId: The bundle ID to disable, defaults to the current app.
    ///
    /// After calling this:
    /// - The app is added to the disabled list
    /// - If it's the current app, shortcuts are immediately disabled
    public func disableApp(appBundleId: String? = frontAppId) {
        if let appBundleId {
            disabledApps.insert(appBundleId)
            saveDisabledApps()
            disableShortcuts()
        }
    }

    /// Re-enables window management for the specified app (or the current frontmost app).
    ///
    /// - Parameter appBundleId: The bundle ID to enable, defaults to the current app.
    ///
    /// After calling this:
    /// - The app is removed from the disabled list
    /// - If it's the current app, shortcuts are immediately enabled
    public func enableApp(appBundleId: String? = frontAppId) {
        if let appBundleId {
            disabledApps.remove(appBundleId)
            saveDisabledApps()
            enableShortcuts()
        }
    }

    /// Checks if window management is disabled for a specific app.
    ///
    /// - Parameter bundleId: The bundle identifier to check (e.g., "com.apple.Safari").
    /// - Returns: true if the app has window management disabled.
    public func isDisabled(bundleId: String) -> Bool {
        return disabledApps.contains(bundleId)
    }

    // MARK: - Private Persistence Methods

    /// Saves the disabled apps set to UserDefaults as a JSON string.
    private func saveDisabledApps() {
        let encoder = JSONEncoder()

        // Convert Set<String> to JSON string and save
        if let jsonData = try? encoder.encode(disabledApps),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            Defaults.disabledApps.value = jsonString
        }
    }

    /// Loads the disabled apps set from UserDefaults.
    ///
    /// - Returns: The set of disabled bundle IDs, or nil if none are stored.
    private func getDisabledApps() -> Set<String>? {
        // Get the JSON string from UserDefaults
        guard let jsonString = Defaults.disabledApps.value else { return nil }

        // Convert JSON string back to Set<String>
        let decoder = JSONDecoder()
        guard let jsonData = jsonString.data(using: .utf8) else { return nil }
        guard let disabledApps = try? decoder.decode(Set<String>.self, from: jsonData) else { return nil }

        return disabledApps
    }

    // MARK: - Private Shortcut Control Methods

    /// Disables all keyboard shortcuts (called when switching to a disabled app).
    private func disableShortcuts() {
        // Only disable if not already disabled (avoid redundant work)
        if !Self.shortcutsDisabled {
            Self.shortcutsDisabled = true
            shortcutManager.unbindShortcuts()

            // Also disable window snapping unless user explicitly wants it kept on
            if !Defaults.ignoreDragSnapToo.userDisabled {
                Notification.Name.windowSnapping.post(object: false)
            }
        }
    }

    /// Enables all keyboard shortcuts (called when switching to an enabled app).
    private func enableShortcuts() {
        // Only enable if currently disabled (avoid redundant work)
        if Self.shortcutsDisabled {
            Self.shortcutsDisabled = false
            shortcutManager.bindShortcuts()

            // Also re-enable window snapping
            if !Defaults.ignoreDragSnapToo.userDisabled {
                Notification.Name.windowSnapping.post(object: true)
            }
        }
    }

    // MARK: - App Activation Monitoring

    /// Registers to receive notifications when the frontmost app changes.
    private func registerFrontAppChangeNote() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(receiveFrontAppChangeNote(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }

    /// Called by macOS when a different app becomes the frontmost (active) app.
    ///
    /// This is the heart of the automatic enable/disable behavior:
    /// 1. Update our tracking of which app is frontmost
    /// 2. Check if that app is in our disabled list
    /// 3. Enable or disable shortcuts accordingly
    ///
    /// - Parameter notification: Contains the NSRunningApplication that was activated.
    @objc func receiveFrontAppChangeNote(_ notification: Notification) {
        // Extract the application that just became active
        guard let application = notification.userInfo?["NSWorkspaceApplicationKey"] as? NSRunningApplication else {
            return
        }

        // Update our static tracking properties
        Self.frontAppId = application.bundleIdentifier
        Self.frontAppName = application.localizedName

        // Check if this app should have shortcuts disabled
        if let frontAppId = application.bundleIdentifier {
            if isDisabled(bundleId: frontAppId) {
                disableShortcuts()
            } else {
                enableShortcuts()
            }

            // Notify other parts of the app that the frontmost app changed
            Notification.Name.frontAppChanged.post()
        } else {
            // App has no bundle ID (rare) - default to enabling shortcuts
            enableShortcuts()
        }

        // ENHANCED UI HANDLING
        // Some apps (like Terminal) use "Enhanced User Interface" mode which
        // interferes with window manipulation. If the user has chosen to
        // disable Enhanced UI on every app switch, do that now.
        if Defaults.enhancedUI.value == .frontmostDisable {
            // Small delay to let the app finish activating
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(50)) {
                AccessibilityElement.getFrontApplicationElement()?.enhancedUserInterface = false
            }
        }
    }
}

// MARK: - Todo Mode Support

extension ApplicationToggle {

    /// Sets the current frontmost app as the "todo app" for Todo Mode.
    ///
    /// Todo Mode is a feature where one app (like Reminders or Things) is treated
    /// as a sidebar that stays visible alongside other windows.
    public func setTodoApp() {
        Defaults.todoApplication.value = Self.frontAppId
    }

    /// Checks if the currently active app is the designated todo app.
    ///
    /// - Returns: true if the frontmost app is the user's selected todo app.
    public func todoAppIsActive() -> Bool {
        return Defaults.todoApplication.value == Self.frontAppId
    }
}
