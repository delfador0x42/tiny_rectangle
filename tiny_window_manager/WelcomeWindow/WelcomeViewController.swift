//
//  WelcomeViewController.swift
//  tiny_window_manager
//
//  Displays a welcome window that lets users choose their initial keyboard shortcut layout.
//  This window is shown as a modal dialog on first launch.
//

import Cocoa

// MARK: - Modal Response Codes
//
// This welcome window runs as a "modal" dialog, meaning it blocks the app
// until the user makes a choice. When closed, it returns a response code
// to tell the app which option was selected:
//
// - .alertFirstButtonReturn  = User chose "Recommended" layout (or closed the window)
// - .alertSecondButtonReturn = User chose "Spectacle" layout

// MARK: - Welcome View Controller

/// Controls the content view of the welcome window.
///
/// This view controller handles the two layout selection buttons.
/// The buttons are connected via Interface Builder (@IBAction).
class WelcomeViewController: NSViewController {

    // MARK: - User Actions

    /// Called when the user clicks the "Recommended" button.
    ///
    /// Closes the modal window and returns a response code indicating
    /// the user wants the recommended keyboard shortcut layout.
    @IBAction func selectRecommended(_ sender: Any) {
        print(#function, "called")
        NSApp.stopModal(withCode: .alertFirstButtonReturn)
    }

    /// Called when the user clicks the "Spectacle" button.
    ///
    /// Closes the modal window and returns a response code indicating
    /// the user wants the Spectacle-compatible keyboard shortcut layout.
    /// (Spectacle was a popular window manager with its own shortcuts.)
    @IBAction func selectSpectacle(_ sender: Any) {
        print(#function, "called")
        NSApp.stopModal(withCode: .alertSecondButtonReturn)
    }
}

// MARK: - Welcome Window Controller

/// Controls the welcome window itself (not its content).
///
/// This controller customizes the window's close button behavior
/// so that closing the window is treated the same as selecting "Recommended".
class WelcomeWindowController: NSWindowController {

    // MARK: - Window Lifecycle

    /// Called after the window has been loaded from the storyboard/xib.
    ///
    /// We override this to customize the close button (the red "X" button).
    /// By default, clicking close would just hide the window without
    /// returning a response. We change it to return "Recommended" instead.
    override func windowDidLoad() {
        print(#function, "called")
        super.windowDidLoad()

        // Get the standard close button (the red circle in the title bar)
        let closeButton = window?.standardWindowButton(.closeButton)

        // Redirect its click action to our custom handler
        closeButton?.target = self
        closeButton?.action = #selector(windowClosed)
    }

    // MARK: - Close Button Handler

    /// Called when the user clicks the window's close button.
    ///
    /// Treats closing the window as if the user selected "Recommended".
    /// This ensures the app always gets a valid response from the modal.
    @objc func windowClosed() {
        print(#function, "called")
        NSApp.stopModal(withCode: .alertFirstButtonReturn)
    }
}

