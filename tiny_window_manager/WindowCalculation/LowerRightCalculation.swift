//
//  LowerRightCalculation.swift
//  tiny_window_manager
//
//  Positions a window in the LOWER-RIGHT corner of the screen.
//  Takes up half the screen height and a variable width.
//  Supports cycling through widths: 1/2 → 2/3 → 1/3 on repeated presses.
//

import Foundation

/// Calculates window position for the lower-right corner.
/// Implements width cycling when the user presses the shortcut repeatedly.
class LowerRightCalculation: WindowCalculation, RepeatedExecutionsInThirdsCalculation {

    // MARK: - Main Calculation

    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        print(#function, "called")
        let isFirstExecution = params.lastAction == nil
        let resizingEnabled = Defaults.subsequentExecutionMode.resizes

        // On first press (or if resize cycling is disabled), use the default size
        if isFirstExecution || !resizingEnabled {
            return calculateFirstRect(params)
        }

        // On repeated presses, cycle through different widths
        return calculateRepeatedRect(params)
    }

    // MARK: - Fractional Size Calculation

    /// Creates a lower-right rectangle with a given width fraction (e.g., 0.5 for half-width).
    /// Height is always half the screen.
    func calculateFractionalRect(_ params: RectCalculationParameters, fraction: Float) -> RectResult {
        print(#function, "called")
        let screenFrame = params.visibleFrameOfScreen

        // Calculate the fractional width
        let windowWidth = floor(screenFrame.width * CGFloat(fraction))

        // Height is always half the screen for corner positions
        let windowHeight = floor(screenFrame.height / 2.0)

        // Position the window on the RIGHT side of the screen
        let xPosition = screenFrame.maxX - windowWidth

        // Build the rectangle
        var windowRect = screenFrame
        windowRect.size.width = windowWidth
        windowRect.size.height = windowHeight
        windowRect.origin.x = xPosition
        // Note: origin.y stays at screenFrame.minY (bottom edge in macOS coordinates)

        return RectResult(windowRect)
    }
}
