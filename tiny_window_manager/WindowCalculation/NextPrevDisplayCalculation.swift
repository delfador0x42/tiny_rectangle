//
//  NextPrevDisplayCalculation.swift
//  tiny_window_manager
//
//

import Cocoa

/// Handles moving windows between multiple displays (monitors).
///
/// User-configurable options that affect behavior:
/// - `Defaults.attemptMatchOnNextPrevDisplay.userEnabled`: When enabled, tries to replicate the window's
///   last positioning action (e.g., left-half, maximize) on the new display
/// - `Defaults.autoMaximize.userDisabled`: When false and window was maximized, keeps it maximized on new display
class NextPrevDisplayCalculation: WindowCalculation {

    // MARK: - Main Entry Point

    /// Calculates the new position for a window moving to the next or previous display.
    /// Returns nil if there's only one display (nothing to move to).
    override func calculate(_ params: WindowCalculationParameters) -> WindowCalculationResult? {
        print(#function, "called")
        let usableScreens = params.usableScreens

        // Can't move to another display if there's only one
        guard usableScreens.numScreens > 1 else {
            return nil
        }

        // Determine which screen to move to based on the action
        guard let targetScreen = getTargetScreen(for: params.action, from: usableScreens) else {
            return nil
        }

        let targetScreenFrame = targetScreen.adjustedVisibleFrame(params.ignoreTodo)
        let rectParams = params.asRectParams(visibleFrame: targetScreenFrame)

        // Try to match the window's previous layout on the new screen (if enabled)
        if let matchedResult = attemptToMatchLastAction(params: params, rectParams: rectParams, targetScreen: targetScreen) {
            return matchedResult
        }

        // Default behavior: center or maximize the window on the new screen
        let rectResult = calculateRect(rectParams)
        let resultingAction = rectResult.resultingAction ?? params.action

        return WindowCalculationResult(rect: rectResult.rect, screen: targetScreen, resultingAction: resultingAction)
    }

    // MARK: - Rectangle Calculation

    /// Calculates the default rectangle when moving to a new display.
    /// If the window was maximized, keeps it maximized; otherwise centers it.
    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        print(#function, "called")
        let wasMaximized = params.lastAction?.action == .maximize
        let autoMaximizeEnabled = !Defaults.autoMaximize.userDisabled

        if wasMaximized && autoMaximizeEnabled {
            // Keep the window maximized on the new display
            let rectResult = WindowCalculationFactory.maximizeCalculation.calculateRect(params)
            return RectResult(rectResult.rect, resultingAction: .maximize)
        }

        // Default: center the window on the new display
        return WindowCalculationFactory.centerCalculation.calculateRect(params)
    }

    // MARK: - Private Helpers

    /// Determines which screen to move the window to based on the action.
    private func getTargetScreen(for action: WindowAction, from usableScreens: UsableScreens) -> NSScreen? {
        print(#function, "called")
        switch action {
        case .nextDisplay:
            return usableScreens.adjacentScreens?.next
        case .previousDisplay:
            return usableScreens.adjacentScreens?.prev
        default:
            return nil
        }
    }

    /// Attempts to replicate the window's last positioning action on the new screen.
    /// For example, if the window was snapped to the left half, it will be snapped to the left half of the new display.
    ///
    /// - Returns: A calculation result if matching was enabled and successful, nil otherwise.
    private func attemptToMatchLastAction(
        params: WindowCalculationParameters,
        rectParams: RectCalculationParameters,
        targetScreen: NSScreen
    ) -> WindowCalculationResult? {
        print(#function, "called")

        // Check if the "match last action" feature is enabled
        guard Defaults.attemptMatchOnNextPrevDisplay.userEnabled else {
            return nil
        }

        // Check if we have a last action to match
        guard let lastAction = params.lastAction else {
            return nil
        }

        // Find the calculation that handles this action type
        guard let calculation = WindowCalculationFactory.calculationsByAction[lastAction.action] else {
            return nil
        }

        // Clear the window's action history so the new position becomes the baseline
        AppDelegate.windowHistory.lasttiny_window_managerActions.removeValue(forKey: params.window.id)

        // Calculate the rect using the same action type but on the new screen
        let newCalculationParams = RectCalculationParameters(
            window: rectParams.window,
            visibleFrameOfScreen: rectParams.visibleFrameOfScreen,
            action: lastAction.action,
            lastAction: nil
        )
        let rectResult = calculation.calculateRect(newCalculationParams)

        return WindowCalculationResult(
            rect: rectResult.rect,
            screen: targetScreen,
            resultingAction: lastAction.action
        )
    }
}
