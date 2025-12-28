//
//  StandardWindowMover.swift
//  tiny_window_manager, Ported from Spectacle
//
//  This is the simplest window mover - it just sets the window to the
//  requested size and position directly, without any special handling.
//

import Foundation

// MARK: - StandardWindowMover

/// The basic window mover that directly applies the requested frame.
///
/// This is the "default" mover used for normal windows that can resize freely.
/// It simply tells the window to move to the target rectangle without any
/// special adjustments for fixed-size windows, quantized windows, or overflow.
///
/// Other movers (like `BestEffortWindowMover`, `QuantizedWindowMover`, etc.)
/// are typically run AFTER this one to handle edge cases.
class StandardWindowMover: WindowMover {

    /// Moves and resizes the window to the target rectangle.
    ///
    /// - Parameters:
    ///   - windowRect: The target position and size for the window
    ///   - frameOfScreen: The full screen bounds (not used in this implementation)
    ///   - visibleFrameOfScreen: The usable screen area (not used in this implementation)
    ///   - frontmostWindowElement: The window to move and resize
    ///   - action: The window action being performed (not used in this implementation)
    func moveWindowRect(
        _ windowRect: CGRect,
        frameOfScreen: CGRect,
        visibleFrameOfScreen: CGRect,
        frontmostWindowElement: AccessibilityElement?,
        action: WindowAction?
    ) {
        // First, check if we can get the window's current frame
        // A "null" rect means the window doesn't exist or isn't accessible
        let currentWindowRect = frontmostWindowElement?.frame
        let windowIsInvalid = currentWindowRect?.isNull == true
        if windowIsInvalid {
            return
        }

        // Apply the new frame to the window
        // The window will move to the new position and resize to the new dimensions
        frontmostWindowElement?.setFrame(windowRect)
    }
}
