//
//  AccessibilityWindow.swift
//  tiny_window_manager
//
//

import Cocoa

// MARK: - AccessibilityWindowController

/// Controls the window that prompts the user to grant accessibility permissions.
///
/// This window appears when the app doesn't have accessibility permissions.
/// If the user closes this window (clicks the red X button), the app quits
/// because it cannot function without these permissions.
class AccessibilityWindowController: NSWindowController {

    // MARK: - Lifecycle

    override func windowDidLoad() {
        print(#function, "called")
        super.windowDidLoad()
        configureCloseButton()
    }

    // MARK: - Private Methods

    /// Configures the window's close button to quit the app when clicked.
    ///
    /// By default, clicking the close button just closes the window.
    /// We override this behavior because the app can't work without
    /// accessibility permissions, so closing this window should quit the app.
    private func configureCloseButton() {
        print(#function, "called")
        let closeButton = self.window?.standardWindowButton(.closeButton)
        closeButton?.target = self
        closeButton?.action = #selector(quit)
    }

    /// Quits the application with a non-zero exit code.
    ///
    /// Exit code 1 indicates the app exited due to an error condition
    /// (in this case, lacking required permissions).
    @objc func quit() {
        print(#function, "called")
        exit(1)
    }
}

// MARK: - AccessibilityViewController

/// Displays instructions for granting accessibility permissions.
///
/// This view controller shows:
/// - Text explaining how to navigate to the accessibility settings
/// - A button to open System Preferences/Settings directly
/// - (On older macOS) Instructions about the padlock icon
///
/// The UI adapts based on macOS version since Apple renamed
/// "System Preferences" to "System Settings" in macOS 13 (Ventura).
class AccessibilityViewController: NSViewController {

    // MARK: - Constants

    /// The URL scheme that opens the Accessibility section in System Preferences/Settings.
    /// This is a special Apple URL that directly navigates to the correct pane.
    private let accessibilitySettingsURL = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    )!

    // MARK: - Outlets

    /// Label showing the navigation path to accessibility settings.
    @IBOutlet weak var sysPrefsPathField: NSTextField!

    /// Button that opens System Preferences/Settings when clicked.
    @IBOutlet weak var openSysPrefsButton: NSButton!

    /// Label explaining the padlock icon (hidden on macOS 13+ where it no longer exists).
    @IBOutlet weak var padlockField: NSTextField!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        print(#function, "called")
        super.viewDidLoad()
        updateUIForMacOSVersion()
    }

    // MARK: - Actions

    /// Opens the Accessibility section of System Preferences/Settings.
    /// Connected to the "Open System Settings" button in the storyboard.
    @IBAction func openSystemPrefs(_ sender: Any) {
        print(#function, "called")
        NSWorkspace.shared.open(accessibilitySettingsURL)
    }

    // MARK: - Private Methods

    /// Updates the UI text based on the current macOS version.
    ///
    /// macOS 13 (Ventura) renamed "System Preferences" to "System Settings"
    /// and removed the padlock icon for unlocking settings. This method
    /// updates the UI to show the correct terminology.
    private func updateUIForMacOSVersion() {
        print(#function, "called")
        // Check if we're running macOS 13 (Ventura) or later
        if #available(OSX 13, *) {
            // Update the path text for the new "System Settings" naming
            sysPrefsPathField.stringValue = NSLocalizedString(
                "Go to System Settings → Privacy & Security → Accessibility",
                tableName: "Main",
                value: "",
                comment: ""
            )

            // Update button text to match the new naming
            openSysPrefsButton.title = NSLocalizedString(
                "Open System Settings",
                tableName: "Main",
                value: "",
                comment: ""
            )

            // Hide the padlock instructions since macOS 13+ doesn't have the padlock
            padlockField.isHidden = true
        }
        // On older macOS versions, we keep the default storyboard values
        // which reference "System Preferences" and include padlock instructions
    }
}
