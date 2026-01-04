//
//  AppDelegate.swift
//  tiny_window_manager
//
//  The main entry point for the application. This file handles:
//  - App startup and lifecycle events
//  - Accessibility permissions (required to move other app's windows)
//  - Keyboard shortcut management
//  - Window snapping (drag to screen edge)
//  - Todo mode feature
//  - URL scheme handling for automation
//
//  The menu bar icon and menu are now handled by SwiftUI MenuBarExtra
//  in TinyWindowManagerApp.swift.
//

import Cocoa
import SwiftUI           // For SwiftUI views hosting
import Sparkle           // For auto-update functionality
import ServiceManagement // For "launch at login" feature
import os.log            // For system logging

// MARK: - AppDelegate

/// The main application delegate that coordinates all app functionality.
///
/// In macOS, the AppDelegate is the central coordinator for your app. It receives
/// notifications about app lifecycle events (launch, quit, become active, etc.)
/// and is responsible for setting up the app's core functionality.
class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Static Properties (Shared Across the App)

    /// Bundle ID used for the "launch at login" helper app
    static let launcherAppId = "com.wudan.tiny_window_manager"

    /// Tracks window positions so users can "undo" window movements
    static let windowHistory = WindowHistory()

    /// Sparkle framework controller for checking/installing app updates
    static let updaterController = SPUStandardUpdaterController(updaterDelegate: nil, userDriverDelegate: nil)

    // MARK: - Core Managers

    /// Handles requesting and checking macOS accessibility permissions
    private let accessibilityAuthorization = AccessibilityAuthorization()

    /// Manages keyboard shortcuts for window actions
    var shortcutManager: ShortcutManager!

    /// Coordinates window movement and resizing operations
    private var windowManager: WindowManager!

    /// Allows users to disable shortcuts for specific apps
    var applicationToggle: ApplicationToggle!

    /// Handles "drag window to screen edge" snapping behavior
    private var snappingManager: SnappingManager!

    /// Manages double-click on title bar behavior
    private var titleBarManager: TitleBarManager!

    // MARK: - App Switching Tracking

    /// Observes changes to the frontmost application
    private var prevActiveAppObservation: NSKeyValueObservation?

    /// Remembers the previously active app (used for URL scheme handling)
    var prevActiveApp: NSRunningApplication?

    // MARK: - App Lifecycle

    /// Called when the app finishes launching. This is our main setup point.
    ///
    /// This method runs through the initial app setup:
    /// 1. Load any config from the Application Support directory
    /// 2. Run version migrations if needed
    /// 3. Check/request accessibility permissions
    /// 4. Register for notifications we care about
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Load any config file that was dropped in the support directory
        Defaults.loadFromSupportDir()

        // Run any needed migrations based on version changes
        checkVersion()

        // Set up launch on login
        checkLaunchOnLogin()

        // Check if we have accessibility permissions (required to move windows)
        // If not authorized, this will show a dialog. When granted, the closure runs.
        let alreadyTrusted = accessibilityAuthorization.checkAccessibility {
            // This runs when user grants accessibility permission
            self.showWelcomeWindow()
            self.checkForConflictingApps()
            self.openPreferences(self)
            self.accessibilityTrusted()
        }

        // If already authorized, initialize immediately
        if alreadyTrusted {
            accessibilityTrusted()
        }

        // Configure auto-update checking based on user preference
        checkAutoCheckForUpdates()

        // Listen for config imports (when user loads a settings file)
        Notification.Name.configImported.onPost(using: { _ in
            self.checkAutoCheckForUpdates()
            self.applicationToggle.reloadFromDefaults()
            self.shortcutManager.reloadFromDefaults()
            self.snappingManager.reloadFromDefaults()
            self.initializeTodo(false)
        })

        // Listen for todo menu toggle events
        Notification.Name.todoMenuToggled.onPost(using: { _ in
            self.initializeTodo(false)
        })

        // Track the previously active app (used for URL scheme handling)
        prevActiveAppObservation = NSWorkspace.shared.observe(
            \.frontmostApplication,
            options: .old
        ) { _, change in
            self.prevActiveApp = change.oldValue ?? nil
        }
    }

    // MARK: - Version Migrations

    /// Checks the app version and runs any necessary data migrations.
    ///
    /// When the app is updated, sometimes we need to migrate data from old formats.
    /// This method checks which version the user was on before and runs appropriate migrations.
    func checkVersion() {
        let currentVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String

        if let lastVersion = Defaults.lastVersion.value,
           let intLastVersion = Int(lastVersion) {
            // User is upgrading from a previous version - run migrations

            // Version 64: Migrated snap area data model
            if intLastVersion < 64 {
                SnapAreaModel.instance.migrate()
            }

            // Version 72: Switched to new launch-at-login API on macOS 13+
            if intLastVersion < 72 {
                if #available(macOS 13, *) {
                    SMLoginItemSetEnabled(AppDelegate.launcherAppId as CFString, false)
                }
            }
        } else {
            // Fresh install - set default values
            Defaults.installVersion.value = currentVersion
            Defaults.allowAnyShortcut.enabled = true
        }

        // Always update the stored version to current
        Defaults.lastVersion.value = currentVersion
    }

    /// Called just before the app becomes active (comes to foreground).
    func applicationWillBecomeActive(_ notification: Notification) {
        Notification.Name.appWillBecomeActive.post()
    }

    /// Syncs the auto-update setting with the Sparkle updater framework.
    func checkAutoCheckForUpdates() {
        Self.updaterController.updater.automaticallyChecksForUpdates = Defaults.SUEnableAutomaticChecks.enabled
    }

    // MARK: - Accessibility Permission Granted

    /// Called once we have accessibility permissions. Sets up all the window management features.
    ///
    /// Accessibility permissions are required because we need to read and modify
    /// windows belonging to OTHER applications. macOS requires explicit user consent for this.
    func accessibilityTrusted() {
        // Update SwiftUI menu state
        Task { @MainActor in
            MenuBarState.shared.isAccessibilityAuthorized = true
        }

        // Create all the core managers now that we have permissions
        self.windowManager = WindowManager()
        self.shortcutManager = ShortcutManager(windowManager: windowManager)
        self.applicationToggle = ApplicationToggle(shortcutManager: shortcutManager)
        self.snappingManager = SnappingManager()
        self.titleBarManager = TitleBarManager()

        // Set up todo mode feature
        self.initializeTodo()

        // Check for apps that have issues with our snapping feature
        checkForProblematicApps()

        // Warn if macOS's built-in tiling is enabled (might conflict)
        MacTilingDefaults.checkForBuiltInTiling(skipIfAlreadyNotified: true)
    }

    // MARK: - Conflict Detection

    /// Checks if any conflicting window management apps are running and warns the user.
    ///
    /// Apps like Spectacle, Magnet, etc. do similar things and can interfere with us.
    func checkForConflictingApps() {
        // Map of bundle IDs to friendly app names
        let conflictingAppsIds: [String: String] = [
            "com.divisiblebyzero.Spectacle": "Spectacle",
            "com.crowdcafe.windowmagnet": "Magnet",
            "com.hegenberg.BetterSnapTool": "BetterSnapTool",
            "com.manytricks.Moom": "Moom"
        ]

        // Check all running apps for conflicts
        let runningApps = NSWorkspace.shared.runningApplications
        for app in runningApps {
            guard let bundleId = app.bundleIdentifier else { continue }

            if let conflictingAppName = conflictingAppsIds[bundleId] {
                AlertUtil.oneButtonAlert(
                    question: "Potential window manager conflict: \(conflictingAppName)",
                    text: "Since \(conflictingAppName) might have some overlapping behavior with tiny_window_manager, it's recommended that you either disable or quit \(conflictingAppName)."
                )
                break // Only show one warning
            }
        }
    }

    /// Checks for installed apps that have known issues with our drag-to-snap feature.
    ///
    /// Some applications (especially Java-based ones and certain Adobe apps) don't
    /// play well with the click/drag listening we do for window snapping. If we detect
    /// these apps, we warn the user so they can either ignore those apps or disable snapping.
    func checkForProblematicApps() {
        // Skip if snapping is disabled or we've already notified the user
        guard !Defaults.windowSnapping.userDisabled,
              !Defaults.notifiedOfProblemApps.enabled else {
            return
        }

        // Apps with known compatibility issues
        let problemBundleIds: [String] = [
            "com.mathworks.matlab",
            "com.live2d.cubism.CECubismEditorApp",
            "com.aquafold.datastudio.DataStudio",
            "com.adobe.illustrator",
            "com.adobe.AfterEffects"
        ]

        // Java-based apps have dynamic bundle IDs, so we look them up by name
        let problemJavaAppNames: [String] = [
            "thinkorswim",
            "Trader Workstation"
        ]

        // Find installed problem apps (that aren't already ignored)
        var problemBundles: [Bundle] = problemBundleIds.compactMap { bundleId in
            // Skip if user already ignored this app
            if applicationToggle.isDisabled(bundleId: bundleId) { return nil }

            // Look up the app by bundle ID
            // Note: Direct Bundle(identifier:) doesn't work for some apps like MATLAB
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
                return Bundle(url: url)
            }
            return nil
        }

        // Check for Java-based apps by name
        for name in problemJavaAppNames {
            if let path = NSWorkspace.shared.fullPath(forApplication: name),
               let bundle = Bundle(path: path),
               let bundleId = bundle.bundleIdentifier {

                // Java apps from install4j have dynamic bundle IDs starting with "com.install4j"
                let isNotIgnored = !applicationToggle.isDisabled(bundleId: bundleId)
                let isInstall4jApp = bundleId.starts(with: "com.install4j")

                if isNotIgnored && isInstall4jApp {
                    problemBundles.append(bundle)
                }
            }
        }

        // Show warning if we found any problematic apps
        if !problemBundles.isEmpty {
            let displayNames = problemBundles.compactMap {
                $0.object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String
            }
            let displayNameString = displayNames.joined(separator: "\n")

            AlertUtil.oneButtonAlert(
                question: "Known issues with installed applications",
                text: """
                    \(displayNameString)

                    These applications have issues with the drag to screen edge to snap \
                    functionality in tiny_window_manager.

                    You can either ignore the applications using the menu item in \
                    tiny_window_manager, or disable drag to screen edge snapping in \
                    tiny_window_manager preferences.
                    """
            )
            Defaults.notifiedOfProblemApps.enabled = true
        }
    }

    // MARK: - Todo Mode

    /// Sets up or refreshes the todo mode feature.
    func initializeTodo(_ bringToFront: Bool = true) {
        TodoManager.registerUnregisterToggleShortcut()
        TodoManager.registerUnregisterReflowShortcut()
        TodoManager.moveAllIfNeeded(bringToFront)
    }

    // MARK: - Welcome & Preferences Windows

    /// Shows the welcome window for first-time users.
    ///
    /// This window helps users choose between recommended shortcuts or custom setup.
    private func showWelcomeWindow() {
        let welcomeController = SwiftUIWelcomeWindowController()
        let usingRecommended = welcomeController.showModal()

        // Apply the chosen settings
        Defaults.alternateDefaultShortcuts.enabled = usingRecommended
        Defaults.subsequentExecutionMode.value = usingRecommended ? .acrossMonitor : .resize
    }

    /// Called when the user clicks the dock icon or relaunches the app.
    ///
    /// Opens the preferences window.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        openPreferences(sender)
        return true
    }

    // MARK: - IBActions (Menu Item Handlers)

    /// Opens the preferences/settings window using SwiftUI's Settings scene.
    @objc func openPreferences(_ sender: Any) {
        NSApp.activate(ignoringOtherApps: true)
        // Use the modern SwiftUI Settings scene (defined in TinyWindowManagerApp.swift)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    /// Shows the standard macOS "About" panel.
    @objc func showAbout(_ sender: Any) {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(sender)
    }

    /// Opens the debug logging window.
    @objc func viewLogging(_ sender: Any) {
        Logger.showLogging(sender: sender)
    }

    /// Triggers a manual check for app updates via Sparkle.
    @objc func checkForUpdates(_ sender: Any) {
        Self.updaterController.checkForUpdates(sender)
    }

    /// Shows the accessibility authorization window/dialog.
    @objc func authorizeAccessibility(_ sender: Any) {
        accessibilityAuthorization.showAuthorizationWindow()
    }

    // MARK: - Launch at Login

    /// Sets up the "launch at login" feature.
    ///
    /// macOS 13+ uses the new ServiceManagement API, while older versions use
    /// a helper app that gets launched at login and then launches the main app.
    private func checkLaunchOnLogin() {
        if #available(macOS 13.0, *) {
            // Modern API: Use the LaunchOnLogin wrapper
            if Defaults.launchOnLogin.enabled, !LaunchOnLogin.isEnabled {
                LaunchOnLogin.isEnabled = true
            }
        } else {
            // Legacy API: Use a helper launcher app

            // Check if our launcher helper is running
            let running = NSWorkspace.shared.runningApplications
            let launcherIsRunning = running.contains { $0.bundleIdentifier == AppDelegate.launcherAppId }

            // If the launcher started us, tell it to quit
            if launcherIsRunning {
                let killNotification = Notification.Name("killLauncher")
                DistributedNotificationCenter.default().post(
                    name: killNotification,
                    object: Bundle.main.bundleIdentifier!
                )
            }

            // Enable launch at login by default on first run
            if !Defaults.SUHasLaunchedBefore {
                Defaults.launchOnLogin.enabled = true
            }

            // Register the login item (macOS can be buggy, so we always re-register)
            if Defaults.launchOnLogin.enabled {
                let smLoginSuccess = SMLoginItemSetEnabled(AppDelegate.launcherAppId as CFString, true)
                if !smLoginSuccess {
                    if #available(OSX 10.12, *) {
                        os_log("Unable to enable launch at login. Attempting one more time.", type: .info)
                    }
                    // Try once more - macOS login items can be flaky
                    SMLoginItemSetEnabled(AppDelegate.launcherAppId as CFString, true)
                }
            }
        }
    }
}

// MARK: - NSWindowDelegate

extension AppDelegate: NSWindowDelegate {

    /// Called when a window is about to close. Used to end modal dialogs.
    func windowWillClose(_ notification: Notification) {
        NSApp.abortModal()
    }
}
