//
//  MoveUpDownCalculation.swift
//  tiny_window_manager
//
//

import Foundation

/// Handles moving windows to the top or bottom of the screen.
///
/// User-configurable options that affect behavior:
/// - `Defaults.centeredDirectionalMove.enabled`: When enabled, horizontally centers the window after moving
/// - `Defaults.resizeOnDirectionalMove.enabled`: When enabled, cycles through 1/3, 1/2, 2/3 heights; otherwise just moves without resizing
class MoveUpDownCalculation: WindowCalculation, RepeatedExecutionsInThirdsCalculation {

    // MARK: - Rectangle Calculation

    /// Calculates the window rectangle for moving up or down.
    /// This is the main entry point called when the user triggers a move action.
    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        print(#function, "called")
        let visibleFrameOfScreen = params.visibleFrameOfScreen

        // Step 1: Calculate the base window rectangle
        var calculatedWindowRect = calculateBaseRect(params: params)

        // Step 2: Optionally center the window horizontally on screen
        if Defaults.centeredDirectionalMove.enabled != false {
            calculatedWindowRect = centerHorizontally(rect: calculatedWindowRect, within: visibleFrameOfScreen)
        }

        // Step 3: If window is wider than screen, constrain it to fit
        let windowIsWiderThanScreen = params.window.rect.width >= visibleFrameOfScreen.width
        if windowIsWiderThanScreen {
            calculatedWindowRect.size.width = visibleFrameOfScreen.width
            calculatedWindowRect.origin.x = visibleFrameOfScreen.minX
        }

        return RectResult(calculatedWindowRect)
    }

    /// Calculates a rect at a specific fraction of screen height (e.g., 0.5 for half).
    func calculateFractionalRect(_ params: RectCalculationParameters, fraction: Float) -> RectResult {
        print(#function, "called")
        return calculateGenericRect(params, fraction: fraction)
    }

    /// Moves the window to the top or bottom edge, optionally resizing to a fraction of screen height.
    ///
    /// - Parameters:
    ///   - params: The calculation parameters
    ///   - fraction: Optional height as fraction of screen (e.g., 0.5 = half height). If nil, keeps current height.
    func calculateGenericRect(_ params: RectCalculationParameters, fraction: Float? = nil) -> RectResult {
        print(#function, "called")
        let visibleFrameOfScreen = params.visibleFrameOfScreen
        var rect = params.window.rect

        // Optionally resize height to the requested fraction of screen height
        if let requestedFraction = fraction {
            rect.size.height = floor(visibleFrameOfScreen.height * CGFloat(requestedFraction))
        }

        // Position the window at the top or bottom edge of the screen
        let isMovingUp = params.action == .moveUp
        if isMovingUp {
            rect.origin.y = visibleFrameOfScreen.maxY - rect.height
        } else {
            rect.origin.y = visibleFrameOfScreen.minY
        }

        return RectResult(rect)
    }

    // MARK: - Private Helpers

    /// Calculates the base rectangle before horizontal centering and width constraints.
    private func calculateBaseRect(params: RectCalculationParameters) -> CGRect {
        print(#function, "called")
        let shouldResize = Defaults.resizeOnDirectionalMove.enabled

        if shouldResize {
            // Resize enabled: cycle through sizes (1/3 -> 1/2 -> 2/3)
            return calculateRepeatedRect(params).rect
        } else {
            // Resize disabled: just move without changing size
            return calculateGenericRect(params).rect
        }
    }

    /// Centers a rectangle horizontally within a screen frame.
    private func centerHorizontally(rect: CGRect, within screenFrame: CGRect) -> CGRect {
        print(#function, "called")
        var centeredRect = rect
        let horizontalPadding = screenFrame.width - rect.width
        let centerX = round(horizontalPadding / 2.0) + screenFrame.minX
        centeredRect.origin.x = centerX
        return centeredRect
    }
}
