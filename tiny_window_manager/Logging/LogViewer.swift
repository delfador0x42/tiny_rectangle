//
//  LogViewer.swift
//  tiny_window_manager
//
//  This file provides a simple logging window for debugging purposes.
//  It shows timestamped log messages in a scrollable text view.
//
//  Usage:
//    Logger.showLogging(sender: nil)  // Open the log window
//    Logger.log("Something happened")  // Add a message to the log
//

import Cocoa

// MARK: - Logger Class

/// A simple static logger that displays messages in a floating window.
///
/// This is primarily used for debugging during development. The log window
/// only accumulates messages while it's open - if closed, messages are discarded.
///
/// ## Example Usage:
/// ```swift
/// // Open the log window (usually from a menu item)
/// Logger.showLogging(sender: nil)
///
/// // Log messages from anywhere in the app
/// Logger.log("Window moved to left half")
/// Logger.log("Keyboard shortcut triggered: Cmd+Opt+Left")
/// ```
class Logger {

    // MARK: - Properties

    /// Whether the log window is currently open and accepting messages.
    /// When false, calls to `log()` are ignored for performance.
    static var logging = false

    /// The window controller for the log viewer (created lazily when first opened)
    static private var logWindowController: LogWindowController?

    // MARK: - Public Methods

    /// Opens the log viewer window and starts capturing log messages.
    ///
    /// - Parameter sender: The object that triggered this action (e.g., a menu item)
    static func showLogging(sender: Any?) {
        // Create the window controller if this is the first time opening
        if logWindowController == nil {
            logWindowController = LogWindowController.freshController()
        }

        // Bring the app to the foreground and show the log window
        NSApp.activate(ignoringOtherApps: true)
        logWindowController?.showWindow(sender)

        // Start accepting log messages
        logging = true
    }

    /// Adds a timestamped message to the log window.
    ///
    /// Messages are only displayed if the log window is open.
    /// This is intentionally lightweight when logging is disabled.
    ///
    /// - Parameter string: The message to log
    static func log(_ string: String) {
        // Early exit if logging is disabled (avoids unnecessary work)
        if logging {
            logWindowController?.append(string)
        }
    }
}

// MARK: - LogWindowController Class

/// The window controller that manages the log viewer window.
///
/// This class:
/// - Creates and manages the log window
/// - Adds timestamps to log messages
/// - Handles the "Clear" button
/// - Cleans up when the window closes
class LogWindowController: NSWindowController, NSWindowDelegate {

    // MARK: - Actions

    /// Called when the user clicks the "Clear" button.
    /// Removes all text from the log view.
    @IBAction func clearClicked(_ sender: Any) {
        (contentViewController as? LogViewController)?.clear()
    }

    // MARK: - Logging Methods

    /// Appends a timestamped message to the log view.
    ///
    /// - Parameter string: The message to append (timestamp is added automatically)
    func append(_ string: String) {
        // Create a timestamp for this log entry
        let datestamp = createTimestamp()

        // Format: "2024-01-15T10:30:45-08:00: Your message here\n"
        let formattedMessage = datestamp + ": " + string + "\n"

        // Add to the text view
        (contentViewController as? LogViewController)?.append(formattedMessage)
    }

    /// Creates an ISO 8601 formatted timestamp for the current time.
    private func createTimestamp() -> String {
        if #available(OSX 10.12, *) {
            // Modern approach: ISO 8601 format (e.g., "2024-01-15T10:30:45-08:00")
            return ISO8601DateFormatter.string(
                from: Date(),
                timeZone: TimeZone.current,
                formatOptions: .withInternetDateTime
            )
        } else {
            // Fallback for older macOS: Unix timestamp (e.g., "1705340045.123")
            return String(NSDate().timeIntervalSince1970)
        }
    }

    // MARK: - NSWindowDelegate

    /// Called when the log window is about to close.
    /// Disables logging and clears the log content.
    func windowWillClose(_ notification: Notification) {
        Logger.logging = false
        clearClicked(self)  // Clear the log to free memory
    }
}

// MARK: - LogWindowController Storyboard Instantiation

extension LogWindowController {

    /// Creates a new LogWindowController from the storyboard.
    ///
    /// This is the proper way to create this controller since it's
    /// defined in a storyboard file (LogViewer.storyboard).
    static func freshController() -> LogWindowController {
        // Load from the LogViewer storyboard
        let storyboard = NSStoryboard(name: "LogViewer", bundle: nil)
        let identifier = "LogWindowController"

        guard let windowController = storyboard.instantiateController(withIdentifier: identifier) as? LogWindowController else {
            fatalError("Unable to find LogWindowController in LogViewer.storyboard")
        }

        // Set ourselves as the window delegate to receive windowWillClose
        windowController.window?.delegate = windowController

        return windowController
    }
}

// MARK: - LogViewController Class

/// The view controller that contains the scrolling text view for log messages.
///
/// This controller manages the actual text display, including:
/// - Appending styled text
/// - Auto-scrolling to new content (smart scroll)
/// - Clearing the log
class LogViewController: NSViewController {

    // MARK: - Outlets

    /// The text view that displays log messages (connected in storyboard)
    @IBOutlet var textView: NSTextView!

    // MARK: - Text Styling

    /// The monospace font used for log messages
    let font = NSFont(name: "Monaco", size: 10) ?? NSFont.systemFont(ofSize: 10)

    /// Text attributes applied to all log messages.
    /// Uses Monaco font (monospace) for easy reading of technical logs.
    let textColorAttribute: [NSAttributedString.Key: Any] = [
        .foregroundColor: NSColor.textColor,
        .font: NSFont(name: "Monaco", size: 10) ?? NSFont.systemFont(ofSize: 10)
    ]

    // MARK: - Public Methods

    /// Appends styled text to the log view.
    ///
    /// Includes "smart scroll" behavior: if the user is already scrolled to
    /// the bottom, new content will auto-scroll into view. If they've scrolled
    /// up to read older messages, new content won't interrupt them.
    ///
    /// - Parameter string: The text to append
    func append(_ string: String) {
        // Check if user is currently scrolled to the bottom
        let isScrolledToBottom = textView.visibleRect.maxY == textView.bounds.maxY

        // Add the new text with styling
        let styledText = NSAttributedString(string: string, attributes: textColorAttribute)
        textView.textStorage?.append(styledText)

        // Only auto-scroll if user was already at the bottom
        if isScrolledToBottom {
            textView.scrollToEndOfDocument(self)
        }
    }

    /// Clears all text from the log view.
    func clear() {
        textView.string = ""
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        // Make the text view read-only (users shouldn't edit log messages)
        textView.isEditable = false
    }
}

// MARK: - KeyDownTextView Class

/// A custom NSTextView subclass that handles keyboard shortcuts.
///
/// This allows the log window to respond to standard macOS shortcuts:
/// - Cmd+W: Close the window
/// - Cmd+H: Hide the window
class KeyDownTextView: NSTextView {

    /// Intercepts key presses to handle window management shortcuts.
    override func keyDown(with event: NSEvent) {
        // Check if the Command key is held
        let isCommandPressed = event.modifierFlags.contains(.command)

        if isCommandPressed {
            // Handle Command+key combinations
            switch event.charactersIgnoringModifiers {
            case "w":
                // Cmd+W: Close the window
                self.window?.close()
            case "h":
                // Cmd+H: Hide the window (minimize to dock)
                self.window?.orderOut(self)
            default:
                // Let other Cmd+key combinations pass through
                super.keyDown(with: event)
            }
        } else {
            // Non-command keys: pass to default handler
            super.keyDown(with: event)
        }
    }
}
