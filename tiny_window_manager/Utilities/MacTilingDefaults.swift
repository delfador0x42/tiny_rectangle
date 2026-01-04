//
//  MacTilingDefaults.swift
//  tiny_window_manager
//
//  Manages the macOS built-in window tiling settings (introduced in macOS 15 Sequoia).
//
//  BACKGROUND:
//  Starting with macOS 15, Apple added native window tiling features similar to what
//  third-party window managers provide. This can cause conflicts when both systems
//  try to handle the same drag-to-edge gestures.
//
//  This file allows us to:
//  1. Detect if macOS tiling features are enabled
//  2. Programmatically disable them to avoid conflicts
//  3. Guide users to the relevant System Settings
//
//  WHERE THESE SETTINGS LIVE:
//  System Settings → Desktop & Dock → Windows
//
//  HOW IT WORKS:
//  macOS stores these preferences in a UserDefaults suite called "com.apple.WindowManager".
//  We read/write to that suite to check and modify the settings.
//

import Foundation

// MARK: - MacTilingDefaults Enum

/// Represents the different macOS tiling preferences that can conflict with our app.
///
/// Each case corresponds to a specific setting in System Settings → Desktop & Dock → Windows.
/// The raw value is the actual key name used in macOS's UserDefaults.
///
enum MacTilingDefaults: String {

    // MARK: - Cases

    /// "Drag windows to screen edges to tile" - tiles windows when dragged to left/right edges
    case tilingByEdgeDrag = "EnableTilingByEdgeDrag"

    /// "Hold Option key while dragging to tile" - enables Option+drag for quick tiling
    case tilingOptionAccelerator = "EnableTilingOptionAccelerator"

    /// "Tiled windows have margins" - adds gaps between tiled windows
    case tiledWindowMargins = "EnableTiledWindowMargins"

    /// "Drag windows to top of screen to enter full screen" (macOS 15.1+)
    case topTilingByEdgeDrag = "EnableTopTilingByEdgeDrag"

    // MARK: - Reading Settings

    /// Returns whether this tiling feature is currently enabled in macOS.
    ///
    /// Note: These settings are enabled by DEFAULT in macOS 15+.
    /// If the key doesn't exist, we assume it's enabled.
    ///
    var enabled: Bool {
        // Only relevant for macOS 15 and later
        guard #available(macOS 15, *) else {
            return false
        }

        // Try to access Apple's WindowManager preferences
        guard let windowManagerDefaults = UserDefaults(suiteName: "com.apple.WindowManager") else {
            return false
        }

        // Check if the setting has been explicitly set
        let settingExists = windowManagerDefaults.object(forKey: self.rawValue) != nil

        if !settingExists {
            // Setting hasn't been touched - these are ON by default in macOS
            return true
        }

        // Return the actual stored value
        return windowManagerDefaults.bool(forKey: self.rawValue)
    }

    // MARK: - Modifying Settings

    /// Disables this tiling feature in macOS.
    ///
    /// This writes directly to Apple's WindowManager preferences.
    /// The change takes effect immediately.
    ///
    func disable() {
        // Try to access Apple's WindowManager preferences
        guard let windowManagerDefaults = UserDefaults(suiteName: "com.apple.WindowManager") else {
            return
        }

        // Write the new value
        windowManagerDefaults.set(false, forKey: self.rawValue)

        // Force the preferences to save immediately
        // (normally they save asynchronously, but we want immediate effect)
        windowManagerDefaults.synchronize()
    }

    // MARK: - System Settings Integration

    /// Opens the Desktop & Dock section of System Settings where tiling options are configured.
    ///
    static func openSystemSettings() {
        // This special URL scheme opens System Settings directly to the Desktop & Dock pane
        let settingsURL = URL(string: "x-apple.systempreferences:com.apple.preference.Desktop-Settings.extension")!
        NSWorkspace.shared.open(settingsURL)
    }

    // MARK: - Conflict Detection

    /// Checks if macOS's built-in tiling conflicts with our app and offers to resolve it.
    ///
    /// - Parameter skipIfAlreadyNotified: If true, skips the standard tiling check if we've
    ///   already shown a notification before. Top-edge tiling is always checked.
    ///
    /// This is typically called when the app launches to ensure a smooth user experience.
    ///
    static func checkForBuiltInTiling(skipIfAlreadyNotified: Bool) {
        // Only relevant for macOS 15+
        guard #available(macOS 15, *) else { return }

        // Don't check if user has already disabled our snapping feature
        guard !Defaults.windowSnapping.userDisabled else { return }

        // Check if standard edge tiling is enabled in macOS
        let isStandardTilingConflicting = (tilingByEdgeDrag.enabled || tilingOptionAccelerator.enabled)

        // Should we skip the standard check? (only if already notified AND caller requested skip)
        let shouldSkipStandardCheck = skipIfAlreadyNotified && Defaults.internalTilingNotified.enabled

        // Handle conflicts based on priority
        if isStandardTilingConflicting && !shouldSkipStandardCheck {
            // Standard tiling conflicts - show the main conflict dialog
            resolveStandardTilingConflict()
        } else if isTopTilingConflicting {
            // Only top-edge tiling conflicts - handle it silently
            resolveTopTilingConflict()
        }

        // Remember that we've shown the notification
        Defaults.internalTilingNotified.enabled = true
    }

    // MARK: - Private Conflict Resolution

    /// Checks if macOS's top-edge tiling conflicts with our top snap area.
    ///
    private static var isTopTilingConflicting: Bool {
        // Top-edge tiling was added in macOS 15.1
        guard #available(macOS 15.1, *) else {
            return false
        }

        // Conflict exists if BOTH are true:
        // 1. macOS top-edge tiling is enabled
        // 2. Our app has a top snap area configured
        return topTilingByEdgeDrag.enabled && SnapAreaModel.instance.isTopConfigured
    }

    /// Handles the case where only top-edge tiling conflicts.
    ///
    /// This is less intrusive - we automatically disable macOS's top tiling
    /// since our app has a custom top snap area configured.
    ///
    private static func resolveTopTilingConflict() {
        Logger.log("Automatically disabling macOS top edge tiling to resolve conflict with macOS.")

        // Disable the conflicting macOS feature
        topTilingByEdgeDrag.disable()

        // Only show a notification if this is the first time
        if !Defaults.internalTilingNotified.enabled {
            // First time running the app & only top tiling was conflicting
            let result = AlertUtil.twoButtonAlert(
                question: "Top screen edge tiling in macOS is now disabled".localized,
                text: "To adjust macOS tiling, go to System Settings → Desktop & Dock → Windows".localized,
                cancelText: "Open System Settings".localized
            )

            // If user clicked "Open System Settings" (second button)
            if result == .alertSecondButtonReturn {
                openSystemSettings()
            }
        }
    }

    /// Handles the main tiling conflict dialog.
    ///
    /// Shows a three-button dialog letting the user choose:
    /// 1. Disable tiling in macOS
    /// 2. Disable tiling in our app
    /// 3. Dismiss (do nothing)
    ///
    private static func resolveStandardTilingConflict() {
        // Show the conflict dialog
        let userChoice = AlertUtil.threeButtonAlert(
            question: "Conflict with macOS tiling".localized,
            text: "Drag to screen edge tiling is enabled in both tiny_window_manager and macOS.".localized,
            buttonOneText: "Disable in macOS".localized,
            buttonTwoText: "Disable in tiny_window_manager".localized,
            buttonThreeText: "Dismiss".localized
        )

        switch userChoice {
        case .alertFirstButtonReturn:
            // User chose to disable macOS tiling
            disableMacTiling()

            // Confirm and offer to show System Settings
            let confirmResult = AlertUtil.twoButtonAlert(
                question: "Tiling in macOS has been disabled".localized,
                text: "To re-enable it, go to System Settings → Desktop & Dock → Windows".localized,
                cancelText: "Open System Settings".localized
            )

            if confirmResult == .alertSecondButtonReturn {
                openSystemSettings()
            }

        case .alertSecondButtonReturn:
            // User chose to disable our app's tiling
            Defaults.windowSnapping.enabled = false

            // Notify other parts of the app about this change
            Notification.Name.windowSnapping.post(object: false)

            // Confirm and offer to show System Settings
            let confirmResult = AlertUtil.twoButtonAlert(
                question: "Tiling in tiny_window_manager has been disabled".localized,
                text: "To adjust macOS tiling, go to System Settings → Desktop & Dock → Windows".localized,
                cancelText: "Open System Settings".localized
            )

            if confirmResult == .alertSecondButtonReturn {
                openSystemSettings()
            }

        default:
            // User dismissed - do nothing
            break
        }
    }

    /// Disables all macOS tiling features.
    ///
    private static func disableMacTiling() {
        tilingByEdgeDrag.disable()
        tilingOptionAccelerator.disable()
        topTilingByEdgeDrag.disable()
    }
}
