//
//  RepeatedExecutionsCalculation.swift
//  tiny_window_manager
//
//

import Foundation

// MARK: - RepeatedExecutionsCalculation Protocol

/// A protocol for window calculations that cycle through different sizes when repeated.
///
/// When a user triggers the same window action multiple times in a row (e.g., pressing
/// "snap left" repeatedly), the window can cycle through different sizes instead of
/// staying the same. This protocol enables that cycling behavior.
///
/// ## How It Works
/// 1. First execution: Uses the default/first size
/// 2. Second execution: Moves to the next size in the cycle
/// 3. Third execution: Moves to the next size, and so on...
/// 4. After the last size: Wraps back to the first size
///
/// ## Example
/// Pressing "snap left" might cycle through: half → two-thirds → one-third → half...
///
/// Conforming types must implement:
/// - `calculateFirstRect`: The initial size when the action is first triggered
/// - `calculateRect(for:params:)`: The size for a specific cycle position
protocol RepeatedExecutionsCalculation {

    /// Calculates the window rectangle for the first execution of an action.
    /// This is called when the user triggers a new action (not a repeat).
    func calculateFirstRect(_ params: RectCalculationParameters) -> RectResult

    /// Calculates the window rectangle for a specific size in the cycle.
    ///
    /// - Parameters:
    ///   - cycleDivision: The size to use (e.g., half, oneThird, twoThirds)
    ///   - params: The calculation parameters
    func calculateRect(for cycleDivision: CycleSize, params: RectCalculationParameters) -> RectResult
}

// MARK: - Default Implementation

extension RepeatedExecutionsCalculation {

    /// Calculates the appropriate rectangle based on how many times the action has been repeated.
    ///
    /// This method handles the cycling logic:
    /// - If this is the first time (or a different action), returns the first rect
    /// - If this is a repeat, determines which size in the cycle to use
    func calculateRepeatedRect(_ params: RectCalculationParameters) -> RectResult {

        // Check if this is a repeated execution of the same action
        let isRepeatedAction = params.lastAction?.action == params.action
        guard isRepeatedAction, let repeatCount = params.lastAction?.count else {
            // First time triggering this action - use the initial size
            return calculateFirstRect(params)
        }

        // Get the list of sizes to cycle through
        let cycleSizes = getAvailableCycleSizes()

        // Use modulo to wrap around when we reach the end of the cycle
        // Example: if count=3 and we have 3 sizes, position = 3 % 3 = 0 (back to start)
        let positionInCycle = repeatCount % cycleSizes.count

        return calculateRect(for: cycleSizes[positionInCycle], params: params)
    }

    // MARK: - Private Helpers

    /// Returns the list of cycle sizes to use, in sorted order.
    /// Uses custom sizes if configured, otherwise falls back to defaults.
    private func getAvailableCycleSizes() -> [CycleSize] {
        let userHasCustomSizes = Defaults.cycleSizesIsChanged.enabled
        let configuredSizes = userHasCustomSizes ? Defaults.selectedCycleSizes.value : CycleSize.defaultSizes

        // Filter to only include configured sizes, maintaining the standard sort order
        let sortedSizes = CycleSize.sortedSizes.filter { size in
            configuredSizes.contains(size)
        }

        return sortedSizes
    }
}
