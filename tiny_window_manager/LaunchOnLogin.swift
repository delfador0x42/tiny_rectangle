//
//  LaunchOnLogin.swift
//  tiny_window_manager
//
//  Manages the "Launch at Login" feature, which automatically starts the app
//  when the user logs into their Mac.
//
//  This uses Apple's ServiceManagement framework (SMAppService), which is the
//  modern way to register apps for launch at login on macOS 13+. The older
//  methods (LSSharedFileList, SMLoginItemSetEnabled) are deprecated.
//
//  Usage:
//    // Check if launch on login is enabled
//    if LaunchOnLogin.isEnabled { ... }
//
//    // Enable launch on login
//    LaunchOnLogin.isEnabled = true
//
//    // Disable launch on login
//    LaunchOnLogin.isEnabled = false
//

import Foundation
import ServiceManagement
import os.log

// MARK: - Launch on Login Manager

/// A namespace for managing the "Launch at Login" setting.
/// Uses an enum with no cases as a pure namespace (cannot be instantiated).
@available(macOS 13.0, *)
public enum LaunchOnLogin {

    // MARK: - Public API

    /// Whether the app is set to launch automatically when the user logs in.
    ///
    /// - Get: Returns `true` if the app is registered for launch on login.
    /// - Set: Registers or unregisters the app with the system's login items.
    ///
    /// Note: Setting this property can fail silently (errors are logged but not thrown).
    /// This is intentional since launch-on-login is a non-critical feature.
    public static var isEnabled: Bool {
        get {
            return SMAppService.mainApp.status == .enabled
        }
        set {
            if newValue {
                enableLaunchOnLogin()
            } else {
                disableLaunchOnLogin()
            }
        }
    }

    // MARK: - Private Implementation

    /// Registers the app to launch when the user logs in.
    private static func enableLaunchOnLogin() {
        do {
            // Workaround: If already registered, unregister first.
            // This handles edge cases where the registration state is corrupted
            // or the previous registration was incomplete.
            if SMAppService.mainApp.status == .enabled {
                try? SMAppService.mainApp.unregister()
            }

            try SMAppService.mainApp.register()
        } catch {
            logError(enabling: true, error: error)
        }
    }

    /// Unregisters the app from launching at login.
    private static func disableLaunchOnLogin() {
        do {
            try SMAppService.mainApp.unregister()
        } catch {
            logError(enabling: false, error: error)
        }
    }

    /// Logs an error that occurred while changing the launch-on-login setting.
    private static func logError(enabling: Bool, error: Error) {
        let action = enabling ? "enable" : "disable"
        os_log("Failed to \(action) launch at login: \(error.localizedDescription)")
    }
}
