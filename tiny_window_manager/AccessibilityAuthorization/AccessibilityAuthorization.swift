//
//  AccessibilityAuthorization.swift
//  tiny_window_manager
//
//

import Foundation
import Cocoa

/// Handles requesting and monitoring accessibility permissions from the user.
///
/// macOS requires apps to be granted accessibility permissions before they can
/// control windows of other applications. This class:
/// 1. Checks if the app already has accessibility permissions
/// 2. If not, shows a window explaining why permissions are needed
/// 3. Polls (repeatedly checks) until the user grants permission
/// 4. Calls a completion handler once permission is granted
///
/// Usage:
/// ```
/// let auth = AccessibilityAuthorization()
/// let alreadyAuthorized = auth.checkAccessibility {
///     print("Permission granted! App can now control windows.")
/// }
/// ```
class AccessibilityAuthorization {

    // MARK: - Constants

    /// How often (in seconds) to check if the user has granted accessibility permission.
    /// We poll because there's no notification when permissions change.
    private let pollingInterval: TimeInterval = 0.3

    // MARK: - Properties

    /// Holds a reference to the authorization prompt window.
    /// We keep this reference so we can close it later when permission is granted.
    private var accessibilityWindowController: NSWindowController?

    // MARK: - Public Methods

    /// Checks if the app has accessibility permissions, and requests them if not.
    ///
    /// If the app already has permissions, this returns `true` immediately.
    /// If not, it shows an authorization window and starts polling for permission.
    /// Once the user grants permission, the completion handler is called.
    ///
    /// - Parameter completion: Called when accessibility permission is granted.
    ///                         Not called if permission was already granted (returns true).
    /// - Returns: `true` if already authorized, `false` if waiting for user to grant permission.
    public func checkAccessibility(completion: @escaping () -> Void) -> Bool {
        // AXIsProcessTrusted() is a system function that checks if this app
        // has been granted accessibility permissions in System Preferences
        let isAlreadyAuthorized = AXIsProcessTrusted()

        if isAlreadyAuthorized {
            // Great! We already have permission, no need to show any UI
            return true
        }

        // We don't have permission yet, so show the authorization window
        showAuthorizationPrompt()

        // Start checking periodically until the user grants permission
        pollAccessibility(completion: completion)

        return false
    }

    /// Brings the authorization window to the front if it's currently showing.
    /// Useful if the user minimized the window and needs to see it again.
    func showAuthorizationWindow() {
        // If the window was minimized to the dock, restore it
        if accessibilityWindowController?.window?.isMiniaturized == true {
            accessibilityWindowController?.window?.deminiaturize(self)
        }

        // Bring our app to the foreground so the user sees the window
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Private Methods

    /// Creates and displays the authorization prompt window from the storyboard.
    private func showAuthorizationPrompt() {
        // Load the window controller from our Main storyboard
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        accessibilityWindowController = storyboard.instantiateController(
            withIdentifier: "AccessibilityWindowController"
        ) as? NSWindowController

        // Bring our app to the front and show the window
        NSApp.activate(ignoringOtherApps: true)
        accessibilityWindowController?.showWindow(self)
    }

    /// Repeatedly checks if accessibility permission has been granted.
    ///
    /// This method schedules itself to run again after a short delay,
    /// creating a polling loop that continues until permission is granted.
    ///
    /// - Parameter completion: Called once when permission is finally granted.
    private func pollAccessibility(completion: @escaping () -> Void) {
        // Schedule a check after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + pollingInterval) { [weak self] in
            guard let self = self else { return }

            if AXIsProcessTrusted() {
                // User granted permission! Clean up and notify.
                self.accessibilityWindowController?.close()
                self.accessibilityWindowController = nil
                completion()
            } else {
                // Still waiting... check again after another delay
                self.pollAccessibility(completion: completion)
            }
        }
    }
}
