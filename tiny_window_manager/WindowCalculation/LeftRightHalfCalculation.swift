//
//  LeftRightHalfCalculation.swift
//  tiny_window_manager
//
//  Positions a window to occupy the left or right half of the screen.
//  Supports multiple behaviors when the shortcut is pressed repeatedly:
//  - Move across monitors (multi-display setups)
//  - Resize through 1/2 → 2/3 → 1/3 cycle
//  - Both across monitors AND resize
//

import Cocoa

/// Calculates window position for left-half and right-half screen layouts.
/// Handles repeated keypresses to cycle sizes or move across displays.
class LeftRightHalfCalculation: WindowCalculation, RepeatedExecutionsInThirdsCalculation {

    // MARK: - Main Entry Point

    override func calculate(_ params: WindowCalculationParameters) -> WindowCalculationResult? {
        print(#function, "called")
        let usableScreens = params.usableScreens
        let executionMode = Defaults.subsequentExecutionMode.value

        switch executionMode {

        case .acrossMonitor:
            // Move window across displays on repeated presses
            return calculateAcrossDisplays(params)

        case .acrossAndResize:
            // Move across displays, but resize if there's only one screen
            let hasMultipleScreens = usableScreens.numScreens > 1
            if hasMultipleScreens {
                return calculateAcrossDisplays(params)
            } else {
                return calculateResize(params)
            }

        case .resize:
            // Cycle through sizes: 1/2 → 2/3 → 1/3 → 1/2...
            return calculateResize(params)

        case .none, .cycleMonitor:
            // Simple mode: just snap to half, no cycling
            let screen = usableScreens.currentScreen
            let halfRect = calculateFirstRect(params.asRectParams())
            return WindowCalculationResult(rect: halfRect.rect, screen: screen, resultingAction: params.action)
        }
    }

    // MARK: - Fractional Width Calculation

    /// Calculates a rectangle with a given fraction of screen width (e.g., 0.5 for half, 0.66 for two-thirds).
    func calculateFractionalRect(_ params: RectCalculationParameters, fraction: Float) -> RectResult {
        print(#function, "called")
        let screenFrame = params.visibleFrameOfScreen

        var windowRect = screenFrame
        windowRect.size.width = floor(screenFrame.width * CGFloat(fraction))

        // For right-half, position the window on the right side of the screen
        let isRightHalf = params.action == .rightHalf
        if isRightHalf {
            windowRect.origin.x = screenFrame.maxX - windowRect.width
        }

        return RectResult(windowRect)
    }

    // MARK: - Resize Cycling

    /// Handles the resize cycling behavior (1/2 → 2/3 → 1/3 → 1/2...).
    func calculateResize(_ params: WindowCalculationParameters) -> WindowCalculationResult? {
        print(#function, "called")
        let screen = params.usableScreens.currentScreen
        let rectResult: RectResult = calculateRepeatedRect(params.asRectParams())
        return WindowCalculationResult(rect: rectResult.rect, screen: screen, resultingAction: params.action)
    }

    // MARK: - Multi-Display Support

    /// Routes to left or right display calculation based on the current action.
    func calculateAcrossDisplays(_ params: WindowCalculationParameters) -> WindowCalculationResult? {
        print(#function, "called")
        let screen = params.usableScreens.currentScreen
        let isRightHalfAction = params.action == .rightHalf

        if isRightHalfAction {
            return calculateRightAcrossDisplays(params, screen: screen)
        } else {
            return calculateLeftAcrossDisplays(params, screen: screen)
        }
    }

    /// Handles left-half positioning, moving to the previous monitor on repeated presses.
    func calculateLeftAcrossDisplays(_ params: WindowCalculationParameters, screen: NSScreen) -> WindowCalculationResult? {
        print(#function, "called")
        let isRepeated = isRepeatedCommand(params)
        let previousScreen = params.usableScreens.adjacentScreens?.prev

        // On repeated press, try to move to the previous screen
        if isRepeated, let prevScreen = previousScreen {
            // If we've wrapped around to the last screen and resize is enabled, start resizing instead
            let hasWrappedAround = prevScreen == params.usableScreens.screensOrdered.last
            let shouldResizeOnWrap = Defaults.subsequentExecutionMode.value == .acrossAndResize

            if shouldResizeOnWrap && hasWrappedAround {
                return calculateResize(params)
            }

            // Move to the previous screen, but as a right-half (since we're moving left)
            return calculateRightAcrossDisplays(params.withDifferentAction(.rightHalf), screen: prevScreen)
        }

        // Default: position on the left half of the current screen
        let visibleFrame = screen.adjustedVisibleFrame(params.ignoreTodo)
        let halfRect = calculateFirstRect(params.asRectParams(visibleFrame: visibleFrame, differentAction: .leftHalf))
        return WindowCalculationResult(rect: halfRect.rect, screen: screen, resultingAction: .leftHalf)
    }

    /// Handles right-half positioning, moving to the next monitor on repeated presses.
    func calculateRightAcrossDisplays(_ params: WindowCalculationParameters, screen: NSScreen) -> WindowCalculationResult? {
        print(#function, "called")
        let isRepeated = isRepeatedCommand(params)
        let nextScreen = params.usableScreens.adjacentScreens?.next

        // On repeated press, try to move to the next screen
        if isRepeated, let nextScr = nextScreen {
            // If we've wrapped around to the first screen and resize is enabled, start resizing instead
            let hasWrappedAround = nextScr == params.usableScreens.screensOrdered.first
            let shouldResizeOnWrap = Defaults.subsequentExecutionMode.value == .acrossAndResize

            if shouldResizeOnWrap && hasWrappedAround {
                return calculateResize(params)
            }

            // Move to the next screen, but as a left-half (since we're moving right)
            return calculateLeftAcrossDisplays(params.withDifferentAction(.leftHalf), screen: nextScr)
        }

        // Default: position on the right half of the current screen
        let visibleFrame = screen.adjustedVisibleFrame(params.ignoreTodo)
        let halfRect = calculateFirstRect(params.asRectParams(visibleFrame: visibleFrame, differentAction: .rightHalf))
        return WindowCalculationResult(rect: halfRect.rect, screen: screen, resultingAction: .rightHalf)
    }

    // MARK: - Snapping Preview

    /// Calculates the rectangle for snapping preview (drag-to-edge visual feedback).
    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        print(#function, "called")
        let screenFrame = params.visibleFrameOfScreen
        let halfWidth = floor(screenFrame.width / 2.0)

        var windowRect = screenFrame
        windowRect.size.width = halfWidth

        // For right-half, shift the rectangle to the right side
        let isLeftHalf = params.action == .leftHalf
        if !isLeftHalf {
            windowRect.origin.x += halfWidth
        }

        return RectResult(windowRect)
    }
}
