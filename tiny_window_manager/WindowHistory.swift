//
//  WindowHistory.swift
//  tiny_window_manager
//
//  This file tracks the position/size history of windows.
//  It enables the "restore" feature (undo a window action) and
//  tracks what actions have been applied to each window.
//

import Foundation

// MARK: - WindowHistory Class

/// Stores historical information about window positions and actions.
///
/// This class maintains two key pieces of data for each window:
/// 1. **Restore rectangles**: The original position/size before the app moved the window.
///    This allows users to "undo" and restore their window to where it was.
/// 2. **Last actions**: What action was most recently applied to each window.
///    This enables features like cycling through positions.
///
/// Windows are identified by their `CGWindowID`, a unique identifier assigned by macOS.
class WindowHistory {

    // MARK: - Properties

    /// Stores the "original" position/size of each window before the app modified it.
    ///
    /// When a user triggers a window action (like "left half"), we save the window's
    /// current frame here BEFORE moving it. This allows the "restore" action to
    /// return the window to its previous position.
    ///
    /// - Key: The window's unique identifier (`CGWindowID`)
    /// - Value: The window's frame (position + size) as a `CGRect`
    ///
    /// Example flow:
    /// 1. User's window is at (100, 100) with size 800x600
    /// 2. User triggers "left half"
    /// 3. We save CGRect(100, 100, 800, 600) to restoreRects[windowId]
    /// 4. Window moves to left half of screen
    /// 5. User triggers "restore"
    /// 6. We read restoreRects[windowId] and move window back to (100, 100, 800x600)
    var restoreRects = [CGWindowID: CGRect]()

    /// Stores the most recent action applied to each window by this app.
    ///
    /// This tracks what positioning action was last performed on each window,
    /// which is useful for:
    /// - Cycling through positions (e.g., repeated "left half" might cycle through thirds)
    /// - Knowing the current state of a window
    /// - Avoiding redundant operations
    ///
    /// - Key: The window's unique identifier (`CGWindowID`)
    /// - Value: The action that was applied (contains the action type and resulting frame)
    var lasttiny_window_managerActions = [CGWindowID: tiny_window_managerAction]()
}
