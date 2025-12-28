//
//  BestEffortWindowMover.swift
//  tiny_window_manager, Ported from Spectacle
//
//  This class handles a common edge case in window management:
//  When a window is resized but can't shrink enough to fit the target size,
//  part of it may end up off-screen. This "best effort" mover nudges the
//  window back so it's fully visible on screen.
//

import Foundation

// MARK: - BestEffortWindowMover

/// Adjusts a window's position to ensure it stays fully visible on screen.
///
/// Some windows have minimum size constraints (e.g., a browser can't shrink below
/// a certain width). When we try to resize such a window to a small target area,
/// the window ends up larger than intended and may overflow off the screen edge.
/// This class detects that overflow and shifts the window back into view.
class BestEffortWindowMover: WindowMover {

    /// Adjusts the window position if it extends beyond the visible screen area.
    ///
    /// - Parameters:
    ///   - windowRect: The intended/target rectangle for the window (not used directly here)
    ///   - frameOfScreen: The full screen bounds including menu bar area
    ///   - visibleFrameOfScreen: The usable screen area (excludes menu bar and dock)
    ///   - frontmostWindowElement: The window to adjust
    ///   - action: The window action being performed (some actions allow overflow)
    func moveWindowRect(
        _ windowRect: CGRect,
        frameOfScreen: CGRect,
        visibleFrameOfScreen: CGRect,
        frontmostWindowElement: AccessibilityElement?,
        action: WindowAction?
    ) {
        // Get the window's current actual position and size
        guard let currentWindowRect = frontmostWindowElement?.frame else {
            return
        }

        // Some actions (like spanning multiple monitors) are allowed to extend
        // outside the current screen. Skip adjustment in those cases.
        let actionAllowsOverflow = action?.allowedToExtendOutsideCurrentScreenArea == true
        let screensShareSpace = !NSScreen.screensHaveSeparateSpaces
        if actionAllowsOverflow && screensShareSpace {
            return
        }

        // Start with the current window position - we'll adjust as needed
        var adjustedRect = currentWindowRect

        // Step 1: Fix horizontal (left/right) overflow
        adjustedRect = adjustHorizontalPosition(adjustedRect, within: visibleFrameOfScreen)

        // Step 2: Fix vertical (top/bottom) overflow
        // Note: macOS has two coordinate systems - we need to flip for vertical calculations
        adjustedRect = adjustVerticalPosition(adjustedRect, within: visibleFrameOfScreen)

        // Only update the window if we actually changed something
        let positionChanged = !currentWindowRect.equalTo(adjustedRect)
        if positionChanged {
            frontmostWindowElement?.setFrame(adjustedRect)
        }
    }

    // MARK: - Private Helper Methods

    /// Adjusts the window's horizontal position to keep it within screen bounds.
    private func adjustHorizontalPosition(_ rect: CGRect, within screenBounds: CGRect) -> CGRect {
        var adjusted = rect

        let windowLeftEdge = adjusted.minX
        let windowRightEdge = adjusted.minX + adjusted.width
        let screenLeftEdge = screenBounds.minX
        let screenRightEdge = screenBounds.minX + screenBounds.width

        // Check if window extends past the LEFT edge of the screen
        let overflowsLeft = windowLeftEdge < screenLeftEdge
        if overflowsLeft {
            // Snap window's left edge to screen's left edge
            adjusted.origin.x = screenLeftEdge
        }

        // Check if window extends past the RIGHT edge of the screen
        let overflowsRight = windowRightEdge > screenRightEdge
        if overflowsRight && !overflowsLeft {
            // Move window left so its right edge aligns with screen's right edge
            // Account for the user's configured gap size
            let gapSize = CGFloat(Defaults.gapSize.value)
            adjusted.origin.x = screenRightEdge - adjusted.width - gapSize
        }

        return adjusted
    }

    /// Adjusts the window's vertical position to keep it within screen bounds.
    private func adjustVerticalPosition(_ rect: CGRect, within screenBounds: CGRect) -> CGRect {
        // macOS uses two coordinate systems:
        // - Screen coordinates: Origin at BOTTOM-left (Cocoa/AppKit style)
        // - Window coordinates: Origin at TOP-left (accessibility API style)
        // We need to flip to work with vertical positioning correctly
        var adjusted = rect.screenFlipped

        let windowTopEdge = adjusted.minY
        let windowBottomEdge = adjusted.minY + adjusted.height
        let screenTopEdge = screenBounds.minY
        let screenBottomEdge = screenBounds.minY + screenBounds.height

        // Check if window extends past the TOP of the screen
        let overflowsTop = windowTopEdge < screenTopEdge
        if overflowsTop {
            // Snap window's top edge to screen's top edge
            adjusted.origin.y = screenTopEdge
        }

        // Check if window extends past the BOTTOM of the screen
        let overflowsBottom = windowBottomEdge > screenBottomEdge
        if overflowsBottom && !overflowsTop {
            // Move window up so its bottom edge aligns with screen's bottom edge
            // Account for the user's configured gap size
            let gapSize = CGFloat(Defaults.gapSize.value)
            adjusted.origin.y = screenBottomEdge - adjusted.height - gapSize
        }

        // Flip back to the original coordinate system
        return adjusted.screenFlipped
    }
}
