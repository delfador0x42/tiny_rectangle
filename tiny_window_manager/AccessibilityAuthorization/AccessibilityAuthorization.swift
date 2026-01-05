//
//  AccessibilityAuthorization.swift
//  tiny_window_manager
//
//  Handles requesting and monitoring accessibility permissions from the user.
//

import Foundation
import Cocoa

/// Handles requesting and monitoring accessibility permissions from the user.
///
/// macOS requires apps to be granted accessibility permissions before they can
/// control windows of other applications. This class:
/// 1. Checks if the app already has accessibility permissions
/// 2. If not, shows a window explaining why permissions are needed
/// 3. Polls until the user grants permission
/// 4. Notifies via async or callback once permission is granted
@MainActor
class AccessibilityAuthorization {

    // MARK: - Constants

    /// How often (in seconds) to check if the user has granted accessibility permission.
    private let pollingInterval: TimeInterval = 0.3

    // MARK: - Properties

    /// Holds a reference to the authorization prompt window.
    private var accessibilityWindowController: NSWindowController?

    // MARK: - Modern Async/Await API

    /// Ensures the app has accessibility permissions, waiting if necessary.
    ///
    /// If already authorized, returns immediately. Otherwise, shows the authorization
    /// prompt and waits asynchronously until the user grants permission.
    ///
    /// - Returns: `true` once authorized (always returns true, just waits if needed)
    public func ensureAuthorized() async -> Bool {
        if AXIsProcessTrusted() {
            return true
        }

        showAuthorizationPrompt()
        await waitForAuthorization()
        return true
    }

    /// Waits asynchronously until accessibility permission is granted.
    private func waitForAuthorization() async {
        while !AXIsProcessTrusted() {
            try? await Task.sleep(for: .seconds(pollingInterval))
        }

        // Permission granted - clean up
        accessibilityWindowController?.close()
        accessibilityWindowController = nil
    }

    // MARK: - Legacy Callback API

    /// Checks if the app has accessibility permissions, and requests them if not.
    ///
    /// - Parameter completion: Called when accessibility permission is granted.
    /// - Returns: `true` if already authorized, `false` if waiting for user.
    public func checkAccessibility(completion: @escaping () -> Void) -> Bool {
        let isAlreadyAuthorized = AXIsProcessTrusted()

        if isAlreadyAuthorized {
            return true
        }

        showAuthorizationPrompt()
        pollAccessibility(completion: completion)
        return false
    }

    /// Brings the authorization window to the front if it's currently showing.
    func showAuthorizationWindow() {
        if accessibilityWindowController?.window?.isMiniaturized == true {
            accessibilityWindowController?.window?.deminiaturize(self)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Private Methods

    /// Creates and displays the authorization prompt window.
    private func showAuthorizationPrompt() {
        accessibilityWindowController = AccessibilityAuthorizationWindowController()
        NSApp.activate(ignoringOtherApps: true)
        accessibilityWindowController?.showWindow(self)
    }

    /// Repeatedly checks if accessibility permission has been granted (legacy polling).
    private func pollAccessibility(completion: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + pollingInterval) { [weak self] in
            guard let self = self else { return }

            if AXIsProcessTrusted() {
                self.accessibilityWindowController?.close()
                self.accessibilityWindowController = nil
                completion()
            } else {
                self.pollAccessibility(completion: completion)
            }
        }
    }
}
