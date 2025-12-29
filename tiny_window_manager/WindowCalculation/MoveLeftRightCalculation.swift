//
//  MoveLeftRightCalculation.swift
//  tiny_window_manager
//
//
import Cocoa

/// Handles moving windows to the left or right side of the screen.
///
/// User-configurable options that affect behavior:
/// - `Defaults.subsequentExecutionMode.traversesDisplays`: When enabled, repeated commands move window to adjacent monitors
/// - `Defaults.centeredDirectionalMove.enabled`: When enabled, vertically centers the window after moving
/// - `Defaults.resizeOnDirectionalMove.enabled`: When enabled, cycles through 1/3, 1/2, 2/3 widths; otherwise just moves without resizing
class MoveLeftRightCalculation: WindowCalculation, RepeatedExecutionsInThirdsCalculation {

    // MARK: - Main Entry Point

    /// Calculates the new position and size for a window being moved left or right.
    /// This is the main entry point called when the user triggers a move action.
    override func calculate(_ params: WindowCalculationParameters) -> WindowCalculationResult? {
        var screen = params.usableScreens.currentScreen
        var action = params.action

        // Check if we should move the window to an adjacent monitor
        let hasMultipleScreens = params.usableScreens.numScreens > 1
        let canTraverseDisplays = Defaults.subsequentExecutionMode.traversesDisplays && hasMultipleScreens
        let shouldMoveToAdjacentScreen = canTraverseDisplays && isRepeatedCommand(params)

        let rectResult: RectResult

        if shouldMoveToAdjacentScreen {
            // User pressed the same hotkey again, so move to the next/previous monitor
            (screen, action) = getAdjacentScreenAndFlippedAction(params: params, currentAction: action)
            let newVisibleFrame = screen.adjustedVisibleFrame(params.ignoreTodo)
            let rectParams = params.asRectParams(visibleFrame: newVisibleFrame, differentAction: action)
            rectResult = calculateRect(rectParams)
        } else {
            // Normal case: just calculate the rect on the current screen
            rectResult = calculateRect(params.asRectParams())
        }

        return WindowCalculationResult(rect: rectResult.rect, screen: screen, resultingAction: action)
    }

    // MARK: - Rectangle Calculation

    /// Calculates the window rectangle (convenience overload that defaults to current display).
    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        calculateRect(params, newDisplay: false)
    }

    /// Calculates the window rectangle, optionally accounting for a new display.
    ///
    /// - Parameters:
    ///   - params: The calculation parameters including screen frame and window info
    ///   - newDisplay: If true, window is moving to a new monitor (uses first rect in cycle)
    func calculateRect(_ params: RectCalculationParameters, newDisplay: Bool) -> RectResult {
        let visibleFrameOfScreen = params.visibleFrameOfScreen

        // Step 1: Calculate the base window rectangle
        var calculatedWindowRect = calculateBaseRect(params: params, isNewDisplay: newDisplay)

        // Step 2: Optionally center the window vertically on screen
        if Defaults.centeredDirectionalMove.enabled != false {
            calculatedWindowRect = centerVertically(rect: calculatedWindowRect, within: visibleFrameOfScreen)
        }

        // Step 3: If window is taller than screen, constrain it to fit
        let windowIsTallerThanScreen = params.window.rect.height >= visibleFrameOfScreen.height
        if windowIsTallerThanScreen {
            calculatedWindowRect.size.height = visibleFrameOfScreen.height
            calculatedWindowRect.origin.y = visibleFrameOfScreen.minY
        }

        return RectResult(calculatedWindowRect)
    }

    /// Calculates a rect at a specific fraction of screen width (e.g., 0.5 for half).
    func calculateFractionalRect(_ params: RectCalculationParameters, fraction: Float) -> RectResult {
        return calculateGenericRect(params, fraction: fraction)
    }

    /// Moves the window to the left or right edge, optionally resizing to a fraction of screen width.
    ///
    /// - Parameters:
    ///   - params: The calculation parameters
    ///   - fraction: Optional width as fraction of screen (e.g., 0.5 = half width). If nil, keeps current width.
    func calculateGenericRect(_ params: RectCalculationParameters, fraction: Float? = nil) -> RectResult {
        let visibleFrameOfScreen = params.visibleFrameOfScreen
        var rect = params.window.rect

        // Optionally resize width to the requested fraction of screen width
        if let requestedFraction = fraction {
            rect.size.width = floor(visibleFrameOfScreen.width * CGFloat(requestedFraction))
        }

        // Position the window at the left or right edge of the screen
        let isMovingRight = params.action == .moveRight
        if isMovingRight {
            rect.origin.x = visibleFrameOfScreen.maxX - rect.width
        } else {
            rect.origin.x = visibleFrameOfScreen.minX
        }

        return RectResult(rect)
    }

    // MARK: - Private Helpers

    /// When moving to an adjacent screen, get that screen and flip the action.
    /// Moving left goes to previous screen and snaps to right edge (and vice versa).
    private func getAdjacentScreenAndFlippedAction(
        params: WindowCalculationParameters,
        currentAction: WindowAction
    ) -> (screen: NSScreen, action: WindowAction) {

        var screen = params.usableScreens.currentScreen
        var action = currentAction

        if action == .moveLeft {
            // Moving left: go to previous screen, snap to right edge
            if let prevScreen = params.usableScreens.adjacentScreens?.prev {
                screen = prevScreen
            }
            action = .moveRight
        } else {
            // Moving right: go to next screen, snap to left edge
            if let nextScreen = params.usableScreens.adjacentScreens?.next {
                screen = nextScreen
            }
            action = .moveLeft
        }

        return (screen, action)
    }

    /// Calculates the base rectangle before vertical centering and height constraints.
    private func calculateBaseRect(params: RectCalculationParameters, isNewDisplay: Bool) -> CGRect {
        let shouldResize = Defaults.resizeOnDirectionalMove.enabled

        if isNewDisplay && shouldResize {
            // Moving to new display with resize enabled: start at first size in cycle
            return calculateFirstRect(params).rect
        } else if shouldResize {
            // Same display with resize enabled: cycle through sizes (1/3 -> 1/2 -> 2/3)
            return calculateRepeatedRect(params).rect
        } else {
            // Resize disabled: just move without changing size
            return calculateGenericRect(params).rect
        }
    }

    /// Centers a rectangle vertically within a screen frame.
    private func centerVertically(rect: CGRect, within screenFrame: CGRect) -> CGRect {
        var centeredRect = rect
        let verticalPadding = screenFrame.height - rect.height
        let centerY = round(verticalPadding / 2.0) + screenFrame.minY
        centeredRect.origin.y = centerY
        return centeredRect
    }
}
