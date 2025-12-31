//
//  ReverseAllManager.swift
//  tiny_window_manager
//
//

import Cocoa
import MASShortcut

/// Handles reversing (mirroring) the horizontal positions of all windows on a screen.
///
/// This is useful for users who:
/// - Want to quickly flip their window layout horizontally
/// - Are switching between left-to-right and right-to-left workflows
/// - Need to mirror their setup for screen sharing or presentations
///
/// Example: If you have windows arranged like this:
/// ```
/// [A    ] [  B  ] [   C]
/// ```
/// After reversing, they become:
/// ```
/// [C   ] [  B  ] [    A]
/// ```
/// Each window moves to its mirror position on the opposite side of the screen.
class ReverseAllManager {

    // MARK: - Public Methods

    /// Reverses the horizontal position of all windows on the current screen.
    ///
    /// Each window is mirrored horizontally around the center of the screen.
    /// A window on the left moves to the right, and vice versa.
    /// The vertical position and size of each window remain unchanged.
    ///
    /// - Parameter windowElement: Optional window to determine which screen to use.
    ///                            If nil, uses the frontmost window's screen.
    static func reverseAll(windowElement: AccessibilityElement? = nil) {
        print(#function, "called")
        let screenDetection = ScreenDetection()

        // Determine which screen to operate on based on the reference window
        let referenceWindow = windowElement ?? AccessibilityElement.getFrontWindowElement()
        guard let currentScreen = screenDetection.detectScreens(using: referenceWindow)?.currentScreen else {
            return
        }

        // Get the usable screen area (excludes menu bar and dock)
        let screenFrame = currentScreen.adjustedVisibleFrame()

        // Get all windows from all applications
        let allWindows = AccessibilityElement.getAllWindowElements()

        // Reverse each window that's on the current screen
        for window in allWindows {
            // Skip the todo window if todo mode is enabled
            if Defaults.todo.userEnabled && TodoManager.isTodoWindow(window) {
                continue
            }

            // Only reverse windows on the same screen
            let windowScreen = screenDetection.detectScreens(using: window)?.currentScreen
            if windowScreen == currentScreen {
                reverseWindowPosition(window, screenFrame: screenFrame)
            }
        }
    }

    // MARK: - Private Methods

    /// Mirrors a single window's horizontal position around the screen's center.
    ///
    /// The math works like this:
    /// 1. Calculate how far the window's left edge is from the screen's left edge
    /// 2. Place the window's right edge that same distance from the screen's right edge
    ///
    /// Visual example (screen width = 1000, window width = 200):
    /// ```
    /// Before: Window at x=100 (100px from left edge)
    ///         |----[WINDOW]----------------------------------|
    ///         ^100px^
    ///
    /// After:  Window at x=700 (right edge 100px from screen's right edge)
    ///         |----------------------------------[WINDOW]----|
    ///                                                   ^100px^
    /// ```
    ///
    /// - Parameters:
    ///   - window: The window to reverse
    ///   - screenFrame: The usable area of the screen
    private static func reverseWindowPosition(_ window: AccessibilityElement, screenFrame: CGRect) {
        print(#function, "called")
        var windowFrame = window.frame

        // Step 1: Calculate how far the window's left edge is from the screen's left edge
        let distanceFromLeftEdge = windowFrame.minX - screenFrame.minX

        // Step 2: Calculate the new X position so the window's right edge
        //         is the same distance from the screen's right edge
        // Formula: newX = screenRight - distanceFromLeft - windowWidth
        let newX = screenFrame.maxX - distanceFromLeftEdge - windowFrame.width

        // Step 3: Update the window's position (keep Y and size unchanged)
        windowFrame.origin.x = newX
        window.setFrame(windowFrame)
    }
}
