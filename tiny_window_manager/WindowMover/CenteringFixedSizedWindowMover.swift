//
//  CenteringFixedSizedWindowMover.swift
//  tiny_window_manager
//
//  This class handles a specific case: windows that can't be resized.
//  When we try to fit a fixed-size window into a target area, this mover
//  centers the window within that area instead of leaving it at the edge.
//

import Foundation

// MARK: - CenteringFixedSizedWindowMover

/// Centers fixed-size windows within their target area.
///
/// Some apps have windows that can't be resized (like calculator or system preferences
/// dialogs). When the user tries to snap such a window to a screen region (e.g., "left half"),
/// the window can't actually resize to fill that region. Instead of leaving the window
/// awkwardly positioned at the top-left corner of the target area, this class centers it
/// within that area for a cleaner look.
///
/// Example: If you snap a 400x300 fixed-size window to the left half of a 1920x1080 screen,
/// instead of placing it at (0, 0), this centers it at (80, 240) within the left-half region.
class CenteringFixedSizedWindowMover: WindowMover {

    /// Centers the window within the target rectangle if the window couldn't resize to fit.
    ///
    /// - Parameters:
    ///   - windowRect: The target rectangle where we wanted the window to go
    ///   - frameOfScreen: The full screen bounds (not used in this implementation)
    ///   - visibleFrameOfScreen: The usable screen area (not used in this implementation)
    ///   - frontmostWindowElement: The window to potentially center
    ///   - action: The window action being performed (not used in this implementation)
    func moveWindowRect(
        _ windowRect: CGRect,
        frameOfScreen: CGRect,
        visibleFrameOfScreen: CGRect,
        frontmostWindowElement: AccessibilityElement?,
        action: WindowAction?
    ) {
        // Get the window's current actual size and position
        guard let currentWindowRect = frontmostWindowElement?.frame else {
            return
        }

        // Start with the current position - we'll adjust if needed
        var adjustedWindowRect = currentWindowRect

        // Check if the window's width differs from what we wanted
        // (This means the window couldn't resize to the target width)
        let windowDidNotMatchTargetWidth = currentWindowRect.width != windowRect.width
        if windowDidNotMatchTargetWidth {
            // Center the window horizontally within the target area
            adjustedWindowRect.origin.x = calculateCenteredPosition(
                windowSize: currentWindowRect.width,
                targetSize: windowRect.width,
                targetOrigin: windowRect.minX
            )
        }

        // Check if the window's height differs from what we wanted
        // (This means the window couldn't resize to the target height)
        let windowDidNotMatchTargetHeight = currentWindowRect.height != windowRect.height
        if windowDidNotMatchTargetHeight {
            // Center the window vertically within the target area
            adjustedWindowRect.origin.y = calculateCenteredPosition(
                windowSize: currentWindowRect.height,
                targetSize: windowRect.height,
                targetOrigin: windowRect.minY
            )
        }

        // Only update the window if we actually changed something
        let positionChanged = !adjustedWindowRect.equalTo(currentWindowRect)
        if positionChanged {
            frontmostWindowElement?.setFrame(adjustedWindowRect)
        }
    }

    // MARK: - Private Helper Methods

    /// Calculates the position needed to center a window within a target area.
    ///
    /// The math: To center something, we need equal space on both sides.
    /// If target is 1000 wide and window is 400 wide, we have 600 extra space.
    /// Half of that (300) goes on each side, so we start at targetOrigin + 300.
    ///
    /// - Parameters:
    ///   - windowSize: The actual size of the window (width or height)
    ///   - targetSize: The size of the target area we're centering within
    ///   - targetOrigin: The starting position of the target area (x or y)
    /// - Returns: The position where the window should be placed to be centered
    private func calculateCenteredPosition(
        windowSize: CGFloat,
        targetSize: CGFloat,
        targetOrigin: CGFloat
    ) -> CGFloat {
        // Calculate how much extra space we have
        let extraSpace = targetSize - windowSize

        // Half the extra space goes before the window (to center it)
        let offsetToCenter = extraSpace / 2.0

        // Round to avoid subpixel positioning (which can cause blurry rendering)
        return round(offsetToCenter) + targetOrigin
    }
}
