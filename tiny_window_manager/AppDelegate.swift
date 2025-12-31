//
//  AppDelegate.swift
//  tiny_window_manager
//
//  The main entry point for the application. This file handles:
//  - App startup and lifecycle events
//  - Accessibility permissions (required to move other app's windows)
//  - Menu bar status item and menu setup
//  - Keyboard shortcut management
//  - Window snapping (drag to screen edge)
//  - Todo mode feature
//  - URL scheme handling for automation
//
//  macOS apps using NSApplicationDelegate receive lifecycle callbacks here.
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
// @NSApplicationMain removed - now using SwiftUI @main in TinyWindowManagerApp.swift
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

    /// The menu bar icon and its associated menu
    private let statusItem = tiny_window_managerStatusItem.instance

    /// Manages keyboard shortcuts for window actions
    private var shortcutManager: ShortcutManager!

    /// Coordinates window movement and resizing operations
    private var windowManager: WindowManager!

    /// Allows users to disable shortcuts for specific apps
    private var applicationToggle: ApplicationToggle!

    /// Factory for creating window position calculations
    private var windowCalculationFactory: WindowCalculationFactory!

    /// Handles "drag window to screen edge" snapping behavior
    private var snappingManager: SnappingManager!

    /// Manages double-click on title bar behavior
    private var titleBarManager: TitleBarManager!

    // MARK: - Window Controllers

    /// The preferences/settings window (created lazily when needed)
    private var prefsWindowController: NSWindowController?

    // MARK: - App Switching Tracking

    /// Observes changes to the frontmost application
    private var prevActiveAppObservation: NSKeyValueObservation?

    /// Remembers the previously active app (used for URL scheme handling)
    private var prevActiveApp: NSRunningApplication?

    // MARK: - Menu Properties (Programmatically Created)

    /// The main dropdown menu shown when clicking the status bar icon
    private var mainStatusMenu: NSMenu!

    /// Shown instead of mainStatusMenu when accessibility isn't authorized
    private var unauthorizedMenu: NSMenu!

    /// Menu item to ignore/unignore the frontmost application
    private var ignoreMenuItem: NSMenuItem!

    /// Menu item to open the logging window (hidden by default)
    private var viewLoggingMenuItem: NSMenuItem!

    /// Menu item to quit the application
    private var quitMenuItem: NSMenuItem!

    // MARK: - App Lifecycle

    /// Called when the app finishes launching. This is our main setup point.
    ///
    /// This method runs through the initial app setup:
    /// 1. Load any config from the Application Support directory
    /// 2. Run version migrations if needed
    /// 3. Check/request accessibility permissions
    /// 4. Set up the menu bar icon and menus
    /// 5. Register for notifications we care about
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print(#function, "called")
        // Create menus programmatically (replaces storyboard IBOutlets)
        setupMenus()

        // Load any config file that was dropped in the support directory
        Defaults.loadFromSupportDir()

        // Run any needed migrations based on version changes
        checkVersion()

        // Set up the menu bar status item
        mainStatusMenu.delegate = self
        statusItem.refreshVisibility()
        checkLaunchOnLogin()

        // Check if we have accessibility permissions (required to move windows)
        // If not authorized, this will show a dialog. When granted, the closure runs.
        let alreadyTrusted = accessibilityAuthorization.checkAccessibility {
            // This runs when user grants accessibility permission
            self.showWelcomeWindow()
            self.checkForConflictingApps()
            self.openPreferences(self)
            self.statusItem.statusMenu = self.mainStatusMenu
            self.accessibilityTrusted()
        }

        // If already authorized, initialize immediately
        if alreadyTrusted {
            accessibilityTrusted()
        }

        // Show different menu based on authorization status
        statusItem.statusMenu = alreadyTrusted ? mainStatusMenu : unauthorizedMenu

        // We manage menu item enabled states ourselves
        mainStatusMenu.autoenablesItems = false
        addWindowActionMenuItems()

        // Configure auto-update checking based on user preference
        checkAutoCheckForUpdates()

        // Listen for config imports (when user loads a settings file)
        Notification.Name.configImported.onPost(using: { _ in
            self.checkAutoCheckForUpdates()
            self.statusItem.refreshVisibility()
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
        print(#function, "called")
        let currentVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String

        if let lastVersion = Defaults.lastVersion.value,
           let intLastVersion = Int(lastVersion) {
            // User is upgrading from a previous version - run migrations

            // Version 46: Migrated keyboard shortcut storage format
            if intLastVersion < 46 {
                MASShortcutMigration.migrate()
            }

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
        print(#function, "called")
        Notification.Name.appWillBecomeActive.post()
    }

    /// Syncs the auto-update setting with the Sparkle updater framework.
    func checkAutoCheckForUpdates() {
        print(#function, "called")
        Self.updaterController.updater.automaticallyChecksForUpdates = Defaults.SUEnableAutomaticChecks.enabled
    }

    // MARK: - Menu Setup

    /// Creates menus programmatically (replacing storyboard IBOutlets).
    private func setupMenus() {
        print(#function, "called")

        // Create the main status menu
        mainStatusMenu = NSMenu(title: "tiny_window_manager")

        // Create the unauthorized menu (shown when accessibility isn't granted)
        unauthorizedMenu = NSMenu(title: "Unauthorized")
        let authorizeItem = NSMenuItem(
            title: NSLocalizedString("Authorize Accessibility...", comment: ""),
            action: #selector(authorizeAccessibility(_:)),
            keyEquivalent: ""
        )
        authorizeItem.target = self
        unauthorizedMenu.addItem(authorizeItem)
        unauthorizedMenu.addItem(NSMenuItem.separator())
        let unauthorizedQuitItem = NSMenuItem(
            title: NSLocalizedString("Quit", comment: ""),
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        unauthorizedMenu.addItem(unauthorizedQuitItem)

        // Create the "Ignore [App]" menu item
        ignoreMenuItem = NSMenuItem(
            title: NSLocalizedString("Ignore frontmost.app", comment: ""),
            action: #selector(ignoreFrontMostApp(_:)),
            keyEquivalent: ""
        )
        ignoreMenuItem.target = self

        // Create the "View Logging" menu item (hidden by default)
        viewLoggingMenuItem = NSMenuItem(
            title: NSLocalizedString("View Logging", comment: ""),
            action: #selector(viewLogging(_:)),
            keyEquivalent: ""
        )
        viewLoggingMenuItem.target = self
        viewLoggingMenuItem.isHidden = true

        // Create the "Quit" menu item
        quitMenuItem = NSMenuItem(
            title: NSLocalizedString("Quit", comment: ""),
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )

        // Add standard menu items to main menu
        mainStatusMenu.addItem(NSMenuItem.separator())
        mainStatusMenu.addItem(ignoreMenuItem)
        mainStatusMenu.addItem(NSMenuItem.separator())

        // Preferences menu item
        let preferencesItem = NSMenuItem(
            title: NSLocalizedString("Preferences...", comment: ""),
            action: #selector(openPreferences(_:)),
            keyEquivalent: ","
        )
        preferencesItem.target = self
        mainStatusMenu.addItem(preferencesItem)

        // Check for Updates menu item
        let checkUpdatesItem = NSMenuItem(
            title: NSLocalizedString("Check for Updates...", comment: ""),
            action: #selector(checkForUpdates(_:)),
            keyEquivalent: ""
        )
        checkUpdatesItem.target = self
        mainStatusMenu.addItem(checkUpdatesItem)

        // About menu item
        let aboutItem = NSMenuItem(
            title: NSLocalizedString("About tiny_window_manager", comment: ""),
            action: #selector(showAbout(_:)),
            keyEquivalent: ""
        )
        aboutItem.target = self
        mainStatusMenu.addItem(aboutItem)

        mainStatusMenu.addItem(NSMenuItem.separator())
        mainStatusMenu.addItem(viewLoggingMenuItem)
        mainStatusMenu.addItem(quitMenuItem)
    }

    // MARK: - Accessibility Permission Granted

    /// Called once we have accessibility permissions. Sets up all the window management features.
    ///
    /// Accessibility permissions are required because we need to read and modify
    /// windows belonging to OTHER applications. macOS requires explicit user consent for this.
    func accessibilityTrusted() {
        print(#function, "called")
        // Create all the core managers now that we have permissions
        self.windowCalculationFactory = WindowCalculationFactory()
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
        print(#function, "called")
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
        print(#function, "called")
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

    // MARK: - Welcome & Preferences Windows

    /// Shows the welcome window for first-time users.
    ///
    /// This window helps users choose between recommended shortcuts or custom setup.
    private func showWelcomeWindow() {
        print(#function, "called")
        let welcomeController = SwiftUIWelcomeWindowController()
        let usingRecommended = welcomeController.showModal()

        // Apply the chosen settings
        Defaults.alternateDefaultShortcuts.enabled = usingRecommended
        Defaults.subsequentExecutionMode.value = usingRecommended ? .acrossMonitor : .resize
    }

    /// Called when the user clicks the dock icon or relaunches the app.
    ///
    /// Based on user preference, this either opens the menu or the preferences window.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        print(#function, "called")
        if Defaults.relaunchOpensMenu.enabled {
            statusItem.openMenu()
        } else {
            openPreferences(sender)
        }
        return true
    }

    // MARK: - IBActions (Menu Item Handlers)

    /// Opens the preferences/settings window.
    @objc func openPreferences(_ sender: Any) {
        print(#function, "called")
        // Lazily create the preferences window controller with SwiftUI view
        if prefsWindowController == nil {
            let hostingController = NSHostingController(rootView: PreferencesView())
            let window = NSWindow(contentViewController: hostingController)
            window.title = "Preferences"
            window.styleMask = NSWindow.StyleMask([.titled, .closable, .miniaturizable, .resizable])
            window.setContentSize(NSSize(width: 800, height: 580))
            window.center()

            prefsWindowController = NSWindowController(window: window)
        }

        // Bring our app to the front and show the window
        NSApp.activate(ignoringOtherApps: true)
        prefsWindowController?.showWindow(self)
    }

    /// Shows the standard macOS "About" panel.
    @objc func showAbout(_ sender: Any) {
        print(#function, "called")
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(sender)
    }

    /// Opens the debug logging window.
    @objc func viewLogging(_ sender: Any) {
        print(#function, "called")
        Logger.showLogging(sender: sender)
    }

    /// Toggles whether the frontmost app is ignored by our shortcuts.
    ///
    /// When "on", the app is currently being ignored, so we re-enable it.
    /// When "off", the app is active, so we disable/ignore it.
    @objc func ignoreFrontMostApp(_ sender: NSMenuItem) {
        print(#function, "called")
        if sender.state == .on {
            applicationToggle.enableApp()
        } else {
            applicationToggle.disableApp()
        }
    }

    /// Triggers a manual check for app updates via Sparkle.
    @objc func checkForUpdates(_ sender: Any) {
        print(#function, "called")
        Self.updaterController.checkForUpdates(sender)
    }

    /// Shows the accessibility authorization window/dialog.
    @objc func authorizeAccessibility(_ sender: Any) {
        print(#function, "called")
        accessibilityAuthorization.showAuthorizationWindow()
    }

    // MARK: - Launch at Login

    /// Sets up the "launch at login" feature.
    ///
    /// macOS 13+ uses the new ServiceManagement API, while older versions use
    /// a helper app that gets launched at login and then launches the main app.
    private func checkLaunchOnLogin() {
        print(#function, "called")
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

// MARK: - NSMenuDelegate (Status Menu Handling)

extension AppDelegate: NSMenuDelegate {

    /// Called just before a menu opens. We use this to update menu item states.
    func menuWillOpen(_ menu: NSMenu) {
        print(#function, "called")
        // For submenus, just update the items
        if menu != mainStatusMenu {
            updateWindowActionMenuItems(menu: menu)
            updateTodoModeMenuItems(menu: menu)
            return
        }

        // Update the "Ignore [App Name]" menu item
        if let frontAppName = ApplicationToggle.frontAppName {
            let ignoreString = NSLocalizedString(
                "D99-0O-MB6.title",
                tableName: "Main",
                value: "Ignore frontmost.app",
                comment: ""
            )
            ignoreMenuItem.title = ignoreString.replacingOccurrences(of: "frontmost.app", with: frontAppName)
            ignoreMenuItem.state = ApplicationToggle.shortcutsDisabled ? .on : .off
            ignoreMenuItem.isHidden = false
        } else {
            ignoreMenuItem.isHidden = true
        }

        updateWindowActionMenuItems(menu: menu)
        updateTodoModeMenuItems(menu: menu)

        // Set keyboard shortcuts for utility menu items
        viewLoggingMenuItem.keyEquivalentModifierMask = .option
        quitMenuItem.keyEquivalent = "q"
        quitMenuItem.keyEquivalentModifierMask = .command
    }

    /// Updates the window action menu items with current state (enabled, shortcuts, icons).
    private func updateWindowActionMenuItems(menu: NSMenu) {
        print(#function, "called")
        let frontmostWindow = AccessibilityElement.getFrontWindowElement()
        let screenCount = NSScreen.screens.count
        let isPortrait = NSScreen.main?.frame.isLandscape == false

        for menuItem in menu.items {
            guard let windowAction = menuItem.representedObject as? WindowAction else { continue }

            // Set the icon for this action
            menuItem.image = windowAction.image.copy() as? NSImage
            menuItem.image?.size = NSSize(width: 18, height: 12)

            // Rotate icons for "thirds" actions when screen is in portrait mode
            if isPortrait && windowAction.classification == .thirds {
                menuItem.image = menuItem.image?.rotated(by: 270)
                menuItem.image?.isTemplate = true
            }

            // Show keyboard shortcut if available and not disabled
            if !ApplicationToggle.shortcutsDisabled {
                if let fullKeyEquivalent = shortcutManager.getKeyEquivalent(action: windowAction),
                   let keyEquivalent = fullKeyEquivalent.0?.lowercased() {
                    menuItem.keyEquivalent = keyEquivalent
                    menuItem.keyEquivalentModifierMask = fullKeyEquivalent.1
                }
            }

            // Disable if there's no frontmost window to act on
            if frontmostWindow == nil {
                menuItem.isEnabled = false
            }
            // Disable display switching when there's only one screen
            if screenCount == 1 &&
               (windowAction == .nextDisplay || windowAction == .previousDisplay) {
                menuItem.isEnabled = false
            }
        }
    }

    /// Called when a menu closes. Resets menu items to their default state.
    func menuDidClose(_ menu: NSMenu) {
        print(#function, "called")
        for menuItem in menu.items {
            // Clear keyboard shortcuts (they're only for display while menu is open)
            menuItem.keyEquivalent = ""
            menuItem.keyEquivalentModifierMask = NSEvent.ModifierFlags()

            // Re-enable all items
            menuItem.isEnabled = true
        }
    }

    /// Handler for when a window action menu item is clicked.
    @objc func executeMenuWindowAction(sender: NSMenuItem) {
        print(#function, "called")
        guard let windowAction = sender.representedObject as? WindowAction else { return }
        windowAction.postMenu()
    }

    // MARK: - Menu Building

    /// Builds all the window action menu items in the status menu.
    ///
    /// This creates menu items for each window action (left half, right half, maximize, etc.)
    /// and optionally groups them into submenus by category.
    func addWindowActionMenuItems() {
        print(#function, "called")
        var menuIndex = 0
        var categoryMenus: [CategoryMenu] = []

        for action in WindowAction.active {
            guard let displayName = action.displayName else { continue }

            // Create a menu item for this action
            let newMenuItem = NSMenuItem(
                title: displayName,
                action: #selector(executeMenuWindowAction),
                keyEquivalent: ""
            )
            newMenuItem.representedObject = action

            // Group into submenus if not showing all actions in main menu
            if !Defaults.showAllActionsInMenu.userEnabled, let category = action.category {
                // Create a new submenu when we hit the first action of a new group
                if menuIndex != 0 && action.firstInGroup {
                    let submenu = NSMenu(title: category.displayName)
                    submenu.autoenablesItems = false
                    categoryMenus.append(CategoryMenu(menu: submenu, category: category))
                }
                categoryMenus.last?.menu.addItem(newMenuItem)
                continue
            }

            // Add separator before new groups (in flat menu mode)
            if menuIndex != 0 && action.firstInGroup {
                mainStatusMenu.insertItem(NSMenuItem.separator(), at: menuIndex)
                menuIndex += 1
            }

            mainStatusMenu.insertItem(newMenuItem, at: menuIndex)
            menuIndex += 1
        }

        // Add category submenus if we have any
        if !categoryMenus.isEmpty {
            mainStatusMenu.insertItem(NSMenuItem.separator(), at: menuIndex)
            menuIndex += 1

            for categoryMenu in categoryMenus {
                categoryMenu.menu.delegate = self
                let submenuItem = NSMenuItem(
                    title: categoryMenu.category.displayName,
                    action: nil,
                    keyEquivalent: ""
                )
                mainStatusMenu.insertItem(submenuItem, at: menuIndex)
                mainStatusMenu.setSubmenu(categoryMenu.menu, for: submenuItem)
                menuIndex += 1
            }
        }

        // Add separator before todo items
        mainStatusMenu.insertItem(NSMenuItem.separator(), at: menuIndex)
        menuIndex += 1

        // Add todo mode menu items
        addTodoModeMenuItems(startingIndex: menuIndex)
    }

    /// Helper struct to track category submenus during menu building.
    struct CategoryMenu {
        let menu: NSMenu
        let category: WindowActionCategory
    }
}

// MARK: - Todo Mode Feature

/// Extension handling the "Todo Mode" feature - keeps a designated app's window
/// visible in a corner while you work.
extension AppDelegate {

    /// Sets up or refreshes the todo mode feature.
    ///
    /// - Parameter bringToFront: Whether to bring the todo window to front
    func initializeTodo(_ bringToFront: Bool = true) {
        print(#function, "called")
        self.showHideTodoMenuItems()
        TodoManager.registerUnregisterToggleShortcut()
        TodoManager.registerUnregisterReflowShortcut()
        TodoManager.moveAllIfNeeded(bringToFront)
    }

    /// Tags used to identify todo-related menu items.
    ///
    /// We use tags so we can easily find and update these items later.
    enum TodoItem {
        case mode, app, reflow, separator, window

        var tag: Int {
            switch self {
            case .mode: return 101
            case .app: return 102
            case .reflow: return 103
            case .separator: return 104
            case .window: return 105
            }
        }

        static let tags = [101, 102, 103, 104, 105]
    }

    /// Adds todo mode menu items to the status menu.
    private func addTodoModeMenuItems(startingIndex: Int) {
        print(#function, "called")
        var menuIndex = startingIndex

        // "Enable Todo Mode" toggle
        let todoModeItemTitle = NSLocalizedString("Enable Todo Mode", tableName: "Main", value: "", comment: "")
        let todoModeMenuItem = NSMenuItem(
            title: todoModeItemTitle,
            action: #selector(toggleTodoMode),
            keyEquivalent: ""
        )
        todoModeMenuItem.tag = TodoItem.mode.tag
        todoModeMenuItem.target = self
        mainStatusMenu.insertItem(todoModeMenuItem, at: menuIndex)
        menuIndex += 1

        // "Use [App] as Todo App" item
        let todoAppItemTitle = NSLocalizedString("Use frontmost.app as Todo App", tableName: "Main", value: "", comment: "")
        let todoAppMenuItem = NSMenuItem(
            title: todoAppItemTitle,
            action: #selector(setTodoApp),
            keyEquivalent: ""
        )
        todoAppMenuItem.tag = TodoItem.app.tag
        mainStatusMenu.insertItem(todoAppMenuItem, at: menuIndex)
        menuIndex += 1

        // "Use as Todo Window" item
        let todoWindowItemTitle = NSLocalizedString("Use as Todo Window", tableName: "Main", value: "", comment: "")
        let todoWindowMenuItem = NSMenuItem(
            title: todoWindowItemTitle,
            action: #selector(setTodoWindow),
            keyEquivalent: ""
        )
        todoWindowMenuItem.tag = TodoItem.window.tag
        mainStatusMenu.insertItem(todoWindowMenuItem, at: menuIndex)
        menuIndex += 1

        // "Reflow Todo" item
        let todoReflowItemTitle = NSLocalizedString("Reflow Todo", tableName: "Main", value: "", comment: "")
        let todoReflowItem = NSMenuItem(
            title: todoReflowItemTitle,
            action: #selector(todoReflow),
            keyEquivalent: ""
        )
        todoReflowItem.tag = TodoItem.reflow.tag
        mainStatusMenu.insertItem(todoReflowItem, at: menuIndex)
        menuIndex += 1

        // Separator after todo items
        let separator = NSMenuItem.separator()
        separator.tag = TodoItem.separator.tag
        mainStatusMenu.insertItem(separator, at: menuIndex)

        showHideTodoMenuItems()
    }

    /// Shows or hides todo menu items based on whether the feature is enabled.
    private func showHideTodoMenuItems() {
        print(#function, "called")
        for item in mainStatusMenu.items {
            if TodoItem.tags.contains(item.tag) {
                item.isHidden = !Defaults.todo.userEnabled
            }
        }
    }

    /// Toggles todo mode on or off.
    @objc func toggleTodoMode(_ sender: NSMenuItem) {
        print(#function, "called")
        let enabled = sender.state == .off
        TodoManager.setTodoMode(enabled)
    }

    /// Sets the frontmost app as the todo app.
    @objc func setTodoApp(_ sender: NSMenuItem) {
        print(#function, "called")
        applicationToggle.setTodoApp()
        TodoManager.moveAllIfNeeded()
    }

    /// Reflows/repositions the todo window.
    @objc func todoReflow(_ sender: NSMenuItem) {
        print(#function, "called")
        TodoManager.moveAll()
    }

    /// Sets the frontmost window as the todo window.
    @objc func setTodoWindow(_ sender: NSMenuItem) {
        print(#function, "called")
        TodoManager.resetTodoWindow()
        TodoManager.moveAllIfNeeded()
    }

    /// Updates todo menu items with current state (enabled, shortcuts, etc.).
    private func updateTodoModeMenuItems(menu: NSMenu) {
        print(#function, "called")
        // Only update if todo feature is enabled and we can find the menu items
        guard Defaults.todo.userEnabled,
              let todoAppMenuItem = menu.item(withTag: TodoItem.app.tag),
              let todoModeMenuItem = menu.item(withTag: TodoItem.mode.tag),
              let todoReflowMenuItem = menu.item(withTag: TodoItem.reflow.tag),
              let todoWindowMenuItem = menu.item(withTag: TodoItem.window.tag)
        else {
            return
        }

        // Update "Use [App] as Todo App" item
        if let frontAppName = ApplicationToggle.frontAppName {
            let appString = NSLocalizedString("Use frontmost.app as Todo App", tableName: "Main", value: "", comment: "")
            todoAppMenuItem.title = appString.replacingOccurrences(of: "frontmost.app", with: frontAppName)
            todoAppMenuItem.isEnabled = !applicationToggle.todoAppIsActive()
            todoAppMenuItem.state = applicationToggle.todoAppIsActive() ? .on : .off
            todoAppMenuItem.isHidden = false
        } else {
            todoAppMenuItem.isHidden = true
        }

        // Update checkmark on "Enable Todo Mode"
        todoModeMenuItem.state = Defaults.todoMode.enabled ? .on : .off

        // Show keyboard shortcuts if available
        if let fullKeyEquivalent = TodoManager.getToggleKeyDisplay(),
           let keyEquivalent = fullKeyEquivalent.0?.lowercased() {
            todoModeMenuItem.keyEquivalent = keyEquivalent
            todoModeMenuItem.keyEquivalentModifierMask = fullKeyEquivalent.1
        }

        if let fullKeyEquivalent = TodoManager.getReflowKeyDisplay(),
           let keyEquivalent = fullKeyEquivalent.0?.lowercased() {
            todoReflowMenuItem.keyEquivalent = keyEquivalent
            todoReflowMenuItem.keyEquivalentModifierMask = fullKeyEquivalent.1
        }

        // Reflow only works when todo mode is enabled
        todoReflowMenuItem.isEnabled = Defaults.todoMode.enabled

        // Hide "Use as Todo Window" when todo app isn't active or current window is already the todo window
        todoWindowMenuItem.isHidden = !applicationToggle.todoAppIsActive() || TodoManager.isTodoWindowFront()
    }
}

// MARK: - NSWindowDelegate

extension AppDelegate: NSWindowDelegate {

    /// Called when a window is about to close. Used to end modal dialogs.
    func windowWillClose(_ notification: Notification) {
        print(#function, "called")
        NSApp.abortModal()
    }
}

// MARK: - URL Scheme Handling

/// Handles custom URL schemes for automation.
///
/// The app supports URLs like:
/// - `tiny-window-manager://execute-action?name=left-half` - Execute a window action
/// - `tiny-window-manager://execute-task?name=ignore-app&app-bundle-id=com.example.app` - Ignore an app
/// - `tiny-window-manager://execute-task?name=unignore-app&app-bundle-id=com.example.app` - Unignore an app
extension AppDelegate {

    /// Handles URLs opened via our custom URL scheme.
    func application(_ application: NSApplication, open urls: [URL]) {
        print(#function, "called")
        // If we're now the frontmost app, switch back to the previous app
        // (URL handling shouldn't steal focus)
        if NSWorkspace.shared.frontmostApplication == NSRunningApplication.current {
            prevActiveApp?.activate()
        }

        // Process URLs asynchronously
        DispatchQueue.main.async {
            self.processURLs(urls)
        }
    }

    /// Processes an array of URLs from the URL scheme handler.
    private func processURLs(_ urls: [URL]) {
        print(#function, "called")
        for url in urls {
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
                  components.path.isEmpty else {
                continue
            }

            let name = components.queryItems?.first { $0.name == "name" }?.value

            switch (components.host, name) {
            case ("execute-action", _):
                // Execute a window action by name
                // URL format: tiny-window-manager://execute-action?name=left-half
                if let action = findWindowAction(byURLName: name) {
                    action.postUrl()
                }

            case ("execute-task", "ignore-app"):
                // Ignore an app
                // URL format: tiny-window-manager://execute-task?name=ignore-app&app-bundle-id=com.example.app
                if let bundleId = extractBundleIdParameter(from: components),
                   isValidBundleId(bundleId) {
                    self.applicationToggle.disableApp(appBundleId: bundleId)
                }

            case ("execute-task", "unignore-app"):
                // Unignore an app
                // URL format: tiny-window-manager://execute-task?name=unignore-app&app-bundle-id=com.example.app
                if let bundleId = extractBundleIdParameter(from: components),
                   isValidBundleId(bundleId) {
                    self.applicationToggle.enableApp(appBundleId: bundleId)
                }

            default:
                continue
            }
        }
    }

    /// Converts a window action name to URL format (camelCase to kebab-case).
    private func actionNameToURLName(_ name: String) -> String {
        print(#function, "called")
        return name.map { $0.isUppercase ? "-" + $0.lowercased() : String($0) }.joined()
    }

    /// Finds a window action by its URL-formatted name.
    private func findWindowAction(byURLName urlName: String?) -> WindowAction? {
        print(#function, "called")
        return WindowAction.active.first { actionNameToURLName($0.name) == urlName }
    }

    /// Extracts the bundle ID parameter from URL components.
    private func extractBundleIdParameter(from components: URLComponents) -> String? {
        print(#function, "called")
        let queryValue = components.queryItems?.first { $0.name == "app-bundle-id" }?.value
        return queryValue ?? ApplicationToggle.frontAppId
    }

    /// Validates that a bundle ID is not empty.
    private func isValidBundleId(_ bundleId: String?) -> Bool {
        print(#function, "called")
        let isValid = bundleId?.isEmpty != true
        if !isValid {
            Logger.log("Received an empty app-bundle-id parameter. Either pass a valid app bundle id or remove the parameter.")
        }
        return isValid
    }
}
