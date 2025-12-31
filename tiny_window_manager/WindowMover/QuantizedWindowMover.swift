//
//  QuantizedWindowMover.swift
//  tiny_window_manager, Ported from Spectacle
//
//  This class handles "quantized" windows - windows that can only resize in
//  discrete steps rather than to any arbitrary size.
//
//  Example: Terminal apps often resize by character cells (e.g., 80x24 characters).
//  If you ask for a 500px wide terminal, it might snap to 504px or 496px instead.
//  This mover iteratively finds the best fit and then centers the result.
//

import Foundation

// MARK: - QuantizedWindowMover

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
    /// (at that point, the window clearly can't fit well)
    private let minimumSizeRatio: CGFloat = 0.85

    // MARK: - WindowMover Protocol

    /// Attempts to fit a quantized window into the target rectangle.
    ///
    /// - Parameters:
    ///   - windowRect: The target rectangle we want the window to fit within
    ///   - frameOfScreen: The full screen bounds (not used in this implementation)
    ///   - visibleFrameOfScreen: The usable screen area (not used in this implementation)
    ///   - frontmostWindowElement: The window to resize
    ///   - action: The window action being performed (not used in this implementation)
    func moveWindowRect(
        _ windowRect: CGRect,
        frameOfScreen: CGRect,
        visibleFrameOfScreen: CGRect,
        frontmostWindowElement: AccessibilityElement?,
        action: WindowAction?
    ) {
        print(#function, "called")
        // Get the window's current size after the initial resize attempt
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
    ///
    /// Because quantized windows snap to discrete sizes, we can't just set the exact
    /// target size. Instead, we keep trying slightly smaller sizes until the window's
    /// actual size fits within our target bounds.
    private func shrinkWindowToFit(
        window: AccessibilityElement?,
        currentRect: CGRect,
        targetRect: CGRect
    ) -> CGRect {
        print(#function, "called")
        var actualWindowRect = currentRect
        var requestedRect = targetRect

        // Keep shrinking while the window is still too big
        while windowExceedsTarget(actual: actualWindowRect, target: targetRect) {

            // Shrink the requested width if the window is too wide
            if actualWindowRect.width > targetRect.width {
                requestedRect.size.width -= shrinkStepSize
            }

            // Shrink the requested height if the window is too tall
            if actualWindowRect.height > targetRect.height {
                requestedRect.size.height -= shrinkStepSize
            }

            // Safety check: don't shrink too much (stop at 85% of target)
            // If we've shrunk this much and still don't fit, something's wrong
            if requestedSizeTooSmall(requested: requestedRect, target: targetRect) {
                break
            }

            // Apply the new size and check the result
            window?.setFrame(requestedRect)
            if let newActualRect = window?.frame {
                actualWindowRect = newActualRect
            }
        }

        return requestedRect
    }

    /// Checks if the actual window size exceeds the target in either dimension.
    private func windowExceedsTarget(actual: CGRect, target: CGRect) -> Bool {
        print(#function, "called")
        return actual.width > target.width || actual.height > target.height
    }

    /// Checks if we've shrunk the requested size too much (below 85% of target).
    private func requestedSizeTooSmall(requested: CGRect, target: CGRect) -> Bool {
        print(#function, "called")
        let widthTooSmall = requested.width < target.width * minimumSizeRatio
        let heightTooSmall = requested.height < target.height * minimumSizeRatio
        return widthTooSmall || heightTooSmall
    }

    /// Centers the window within the target area based on the size difference.
    ///
    /// After fitting, the window may be smaller than the target area.
    /// This calculates the position that centers it within that area.
    private func centerWindow(
        requestedRect: CGRect,
        actualWindowSize: CGSize,
        withinTarget targetRect: CGRect
    ) -> CGRect {
        print(#function, "called")
        var centeredRect = requestedRect

        // Calculate how much smaller the window is than the target
        let extraHorizontalSpace = targetRect.width - actualWindowSize.width
        let extraVerticalSpace = targetRect.height - actualWindowSize.height

        // Offset by half the extra space to center (floor to avoid subpixel positioning)
        centeredRect.origin.x += floor(extraHorizontalSpace / 2.0)
        centeredRect.origin.y += floor(extraVerticalSpace / 2.0)

        return centeredRect
    }
}
