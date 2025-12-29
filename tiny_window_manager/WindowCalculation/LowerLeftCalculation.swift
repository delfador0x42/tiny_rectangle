//
//  LowerLeftCalculation.swift
//  tiny_window_manager
//
//  Positions a window in the LOWER-LEFT corner of the screen.
//  Takes up half the screen height and a variable width.
//  Supports cycling through widths: 1/2 → 2/3 → 1/3 on repeated presses.
//

import Foundation

/// Calculates window position for the lower-left corner.
/// Implements width cycling when the user presses the shortcut repeatedly.
class LowerLeftCalculation: WindowCalculation, RepeatedExecutionsInThirdsCalculation {

    // MARK: - Main Calculation

    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {
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

    /// Creates a lower-left rectangle with a given width fraction (e.g., 0.5 for half-width).
    /// Height is always half the screen.
    func calculateFractionalRect(_ params: RectCalculationParameters, fraction: Float) -> RectResult {
        let screenFrame = params.visibleFrameOfScreen

        // Calculate the fractional width
        let windowWidth = floor(screenFrame.width * CGFloat(fraction))

        // Height is always half the screen for corner positions
        let windowHeight = floor(screenFrame.height / 2.0)

        // Build the rectangle (origin is already at bottom-left in macOS coordinates)
        var windowRect = screenFrame
        windowRect.size.width = windowWidth
        windowRect.size.height = windowHeight
        // Note: origin.x and origin.y stay at screenFrame's origin (bottom-left corner)

        return RectResult(windowRect)
    }
}
