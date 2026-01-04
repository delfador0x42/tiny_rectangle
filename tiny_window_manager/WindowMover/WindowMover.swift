//
//  WindowMover.swift
//  tiny_window_manager, Ported from Spectacle
//
//  This file defines the WindowMover protocol and the basic movers used for most windows.
//  The window manager uses multiple movers in sequence to handle different edge cases:
//  1. StandardWindowMover     - Does the basic move/resize
//  2. QuantizedWindowMover    - Handles apps that resize in steps (like Terminal)
//  3. CenteringFixedSizedWindowMover - Centers windows that can't resize
//  4. BestEffortWindowMover   - Fixes windows that overflow off-screen
//

import Foundation

// ============================================================================
// MARK: - WindowMover Protocol
// ============================================================================

/// A protocol that defines how to move and resize windows.
///
/// This uses the "Strategy Pattern" - instead of having one giant class with
/// lots of if/else statements for different window types, we have multiple
/// small classes that each handle one specific case. The window manager runs
/// them in sequence, and each one makes small adjustments as needed.
///
/// ## How It Works
///
/// When the user triggers a window action (like "snap to left half"):
/// 1. The system calculates the target rectangle
/// 2. Each WindowMover gets a chance to adjust the window
/// 3. The movers run in order, each one potentially tweaking the position/size
///
/// ## Implementing a New Mover
///
/// To create a new window mover, make a class that conforms to this protocol:
///
/// ```swift
/// class MyCustomMover: WindowMover {
///     func moveWindowRect(_ windowRect: CGRect, ...) {
///         // Your custom logic here
///     }
/// }
/// ```
protocol WindowMover {

    /// Moves and/or resizes a window based on the target rectangle.
    ///
    /// Each mover implementation decides what adjustments (if any) to make.
    /// Some movers might do nothing if their special case doesn't apply.
    ///
    /// - Parameters:
    ///   - windowRect: The target rectangle where we want the window to go.
    ///                 This is the "ideal" position calculated by the window action.
    ///
    ///   - frameOfScreen: The full bounds of the screen, including areas covered
    ///                    by the menu bar. Origin is at bottom-left (Cocoa coordinates).
    ///
    ///   - visibleFrameOfScreen: The usable area of the screen, excluding the menu bar
    ///                           and Dock. This is where windows should typically stay.
    ///
    ///   - frontmostWindowElement: The window to move/resize. This is an accessibility
    ///                             element that lets us control the window programmatically.
    ///                             May be nil if no window is available.
    ///
    ///   - action: The window action being performed (e.g., "leftHalf", "maximize").
    ///             Some movers use this to decide whether to apply their logic.
    ///             May be nil for generic move operations.
    func moveWindowRect(
        _ windowRect: CGRect,
        frameOfScreen: CGRect,
        visibleFrameOfScreen: CGRect,
        frontmostWindowElement: AccessibilityElement?,
        action: WindowAction?
    )
}

// ============================================================================
// MARK: - StandardWindowMover
// ============================================================================

/// The basic window mover that directly applies the requested frame.
///
/// This is the "default" mover used for normal windows that can resize freely.
/// It simply tells the window to move to the target rectangle without any
/// special adjustments for fixed-size windows, quantized windows, or overflow.
///
/// Other movers (like `BestEffortWindowMover`, `QuantizedWindowMover`, etc.)
/// are typically run AFTER this one to handle edge cases.
class StandardWindowMover: WindowMover {

    func moveWindowRect(
        _ windowRect: CGRect,
        frameOfScreen: CGRect,
        visibleFrameOfScreen: CGRect,
        frontmostWindowElement: AccessibilityElement?,
        action: WindowAction?
    ) {
        print(#function, "called")
        // A "null" rect means the window doesn't exist or isn't accessible
        let currentWindowRect = frontmostWindowElement?.frame
        let windowIsInvalid = currentWindowRect?.isNull == true
        if windowIsInvalid {
            return
        }

        // Apply the new frame to the window
        frontmostWindowElement?.setFrame(windowRect)
    }
}

// ============================================================================
// MARK: - BestEffortWindowMover
// ============================================================================

/// Adjusts a window's position to ensure it stays fully visible on screen.
///
/// Some windows have minimum size constraints (e.g., a browser can't shrink below
/// a certain width). When we try to resize such a window to a small target area,
/// the window ends up larger than intended and may overflow off the screen edge.
/// This class detects that overflow and shifts the window back into view.
class BestEffortWindowMover: WindowMover {

    func moveWindowRect(
        _ windowRect: CGRect,
        frameOfScreen: CGRect,
        visibleFrameOfScreen: CGRect,
        frontmostWindowElement: AccessibilityElement?,
        action: WindowAction?
    ) {
        print(#function, "called")
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

        var adjustedRect = currentWindowRect

        // Step 1: Fix horizontal (left/right) overflow
        adjustedRect = adjustHorizontalPosition(adjustedRect, within: visibleFrameOfScreen)

        // Step 2: Fix vertical (top/bottom) overflow
        adjustedRect = adjustVerticalPosition(adjustedRect, within: visibleFrameOfScreen)

        // Only update the window if we actually changed something
        let positionChanged = !currentWindowRect.equalTo(adjustedRect)
        if positionChanged {
            frontmostWindowElement?.setFrame(adjustedRect)
        }
    }

    // MARK: - Private Helper Methods

    private func adjustHorizontalPosition(_ rect: CGRect, within screenBounds: CGRect) -> CGRect {
        print(#function, "called")
        var adjusted = rect

        let windowLeftEdge = adjusted.minX
        let windowRightEdge = adjusted.minX + adjusted.width
        let screenLeftEdge = screenBounds.minX
        let screenRightEdge = screenBounds.minX + screenBounds.width

        let overflowsLeft = windowLeftEdge < screenLeftEdge
        if overflowsLeft {
            adjusted.origin.x = screenLeftEdge
        }

        let overflowsRight = windowRightEdge > screenRightEdge
        if overflowsRight && !overflowsLeft {
            let gapSize = CGFloat(Defaults.gapSize.value)
            adjusted.origin.x = screenRightEdge - adjusted.width - gapSize
        }

        return adjusted
    }

    private func adjustVerticalPosition(_ rect: CGRect, within screenBounds: CGRect) -> CGRect {
        print(#function, "called")
        // macOS uses two coordinate systems - we need to flip for vertical calculations
        var adjusted = rect.screenFlipped

        let windowTopEdge = adjusted.minY
        let windowBottomEdge = adjusted.minY + adjusted.height
        let screenTopEdge = screenBounds.minY
        let screenBottomEdge = screenBounds.minY + screenBounds.height

        let overflowsTop = windowTopEdge < screenTopEdge
        if overflowsTop {
            adjusted.origin.y = screenTopEdge
        }

        let overflowsBottom = windowBottomEdge > screenBottomEdge
        if overflowsBottom && !overflowsTop {
            let gapSize = CGFloat(Defaults.gapSize.value)
            adjusted.origin.y = screenBottomEdge - adjusted.height - gapSize
        }

        return adjusted.screenFlipped
    }
}

// ============================================================================
// MARK: - CenteringFixedSizedWindowMover
// ============================================================================

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

    func moveWindowRect(
        _ windowRect: CGRect,
        frameOfScreen: CGRect,
        visibleFrameOfScreen: CGRect,
        frontmostWindowElement: AccessibilityElement?,
        action: WindowAction?
    ) {
        print(#function, "called")
        guard let currentWindowRect = frontmostWindowElement?.frame else {
            return
        }

        var adjustedWindowRect = currentWindowRect

        // Check if the window's width differs from what we wanted
        let windowDidNotMatchTargetWidth = currentWindowRect.width != windowRect.width
        if windowDidNotMatchTargetWidth {
            adjustedWindowRect.origin.x = calculateCenteredPosition(
                windowSize: currentWindowRect.width,
                targetSize: windowRect.width,
                targetOrigin: windowRect.minX
            )
        }

        // Check if the window's height differs from what we wanted
        let windowDidNotMatchTargetHeight = currentWindowRect.height != windowRect.height
        if windowDidNotMatchTargetHeight {
            adjustedWindowRect.origin.y = calculateCenteredPosition(
                windowSize: currentWindowRect.height,
                targetSize: windowRect.height,
                targetOrigin: windowRect.minY
            )
        }

        let positionChanged = !adjustedWindowRect.equalTo(currentWindowRect)
        if positionChanged {
            frontmostWindowElement?.setFrame(adjustedWindowRect)
        }
    }

    // MARK: - Private Helper Methods

    /// Calculates the position needed to center a window within a target area.
    private func calculateCenteredPosition(
        windowSize: CGFloat,
        targetSize: CGFloat,
        targetOrigin: CGFloat
    ) -> CGFloat {
        print(#function, "called")
        let extraSpace = targetSize - windowSize
        let offsetToCenter = extraSpace / 2.0
        // Round to avoid subpixel positioning (which can cause blurry rendering)
        return round(offsetToCenter) + targetOrigin
    }
}

// ============================================================================
// MARK: - QuantizedWindowMover
// ============================================================================

/// Handles windows that resize in discrete "steps" rather than smoothly.
///
/// Some applications (especially terminals, code editors, and retro-style apps)
/// can only resize to specific sizes based on their content grid. When we request
/// a size like 500x400, they might actually become 512x416 because they snap to
/// their internal grid.
///
/// This class works around that by:
/// 1. Iteratively trying smaller sizes until the window fits within the target
/// 2. Centering the final result within the original target area
class QuantizedWindowMover: WindowMover {

    // MARK: - Constants

    /// How many pixels to shrink on each iteration when trying to fit the window
    private let shrinkStepSize: CGFloat = 2

    /// Stop trying if the window would shrink below 85% of the target size
    private let minimumSizeRatio: CGFloat = 0.85

    // MARK: - WindowMover Protocol

    func moveWindowRect(
        _ windowRect: CGRect,
        frameOfScreen: CGRect,
        visibleFrameOfScreen: CGRect,
        frontmostWindowElement: AccessibilityElement?,
        action: WindowAction?
    ) {
        print(#function, "called")
        guard var actualWindowRect = frontmostWindowElement?.frame else {
            return
        }

        // If the window already matches the target exactly, we're done
        let windowAlreadyFitsTarget = actualWindowRect.equalTo(windowRect)
        if windowAlreadyFitsTarget {
            return
        }

        // Try to shrink the window until it fits within the target
        let fittedRect = shrinkWindowToFit(
            window: frontmostWindowElement,
            currentRect: actualWindowRect,
            targetRect: windowRect
        )

        // Get the final actual size (may differ from what we requested due to quantization)
        if let finalActualRect = frontmostWindowElement?.frame {
            actualWindowRect = finalActualRect
        }

        // Center the window within the original target area
        let centeredRect = centerWindow(
            requestedRect: fittedRect,
            actualWindowSize: actualWindowRect.size,
            withinTarget: windowRect
        )

        frontmostWindowElement?.setFrame(centeredRect)
    }

    // MARK: - Private Helper Methods

    /// Iteratively shrinks the requested size until the window fits within the target.
    private func shrinkWindowToFit(
        window: AccessibilityElement?,
        currentRect: CGRect,
        targetRect: CGRect
    ) -> CGRect {
        print(#function, "called")
        var actualWindowRect = currentRect
        var requestedRect = targetRect

        while windowExceedsTarget(actual: actualWindowRect, target: targetRect) {
            if actualWindowRect.width > targetRect.width {
                requestedRect.size.width -= shrinkStepSize
            }

            if actualWindowRect.height > targetRect.height {
                requestedRect.size.height -= shrinkStepSize
            }

            // Safety check: don't shrink too much (stop at 85% of target)
            if requestedSizeTooSmall(requested: requestedRect, target: targetRect) {
                break
            }

            window?.setFrame(requestedRect)
            if let newActualRect = window?.frame {
                actualWindowRect = newActualRect
            }
        }

        return requestedRect
    }

    private func windowExceedsTarget(actual: CGRect, target: CGRect) -> Bool {
        print(#function, "called")
        return actual.width > target.width || actual.height > target.height
    }

    private func requestedSizeTooSmall(requested: CGRect, target: CGRect) -> Bool {
        print(#function, "called")
        let widthTooSmall = requested.width < target.width * minimumSizeRatio
        let heightTooSmall = requested.height < target.height * minimumSizeRatio
        return widthTooSmall || heightTooSmall
    }

    /// Centers the window within the target area based on the size difference.
    private func centerWindow(
        requestedRect: CGRect,
        actualWindowSize: CGSize,
        withinTarget targetRect: CGRect
    ) -> CGRect {
        print(#function, "called")
        var centeredRect = requestedRect

        let extraHorizontalSpace = targetRect.width - actualWindowSize.width
        let extraVerticalSpace = targetRect.height - actualWindowSize.height

        centeredRect.origin.x += floor(extraHorizontalSpace / 2.0)
        centeredRect.origin.y += floor(extraVerticalSpace / 2.0)

        return centeredRect
    }
}
