//
//  RepeatedExecutionsInThirdsCalculation.swift
//  tiny_window_manager
//
//

import Foundation

// MARK: - RepeatedExecutionsInThirdsCalculation Protocol

/// A specialized protocol for window calculations that cycle through fractional sizes (thirds, halves, etc.).
///
/// This protocol extends `RepeatedExecutionsCalculation` and provides default implementations
/// for the cycling behavior. Conforming types only need to implement `calculateFractionalRect`,
/// which positions the window at a given fraction of the screen.
///
/// ## Default Cycle Behavior
/// - First execution: Window snaps to **half** (1/2) of the screen
/// - Subsequent executions: Cycles through configured sizes (e.g., 1/3, 1/2, 2/3)
///
/// ## Example
/// A class conforming to this protocol might snap windows to the left edge:
/// ```swift
/// class LeftSnapCalculation: WindowCalculation, RepeatedExecutionsInThirdsCalculation {
///     func calculateFractionalRect(_ params: RectCalculationParameters, fraction: Float) -> RectResult {
///         // Position window at left edge with width = screen width * fraction
///     }
/// }
/// ```
///
/// With this setup, pressing the hotkey repeatedly would cycle:
/// left-half → left-third → left-two-thirds → left-half...
protocol RepeatedExecutionsInThirdsCalculation: RepeatedExecutionsCalculation {

    /// Calculates a window rectangle at a specific fraction of the screen size.
    ///
    /// - Parameters:
    ///   - params: The calculation parameters (screen frame, window info, etc.)
    ///   - fraction: The fraction of screen width/height to use (e.g., 0.5 for half, 0.333 for third)
    /// - Returns: The calculated window rectangle
    func calculateFractionalRect(_ params: RectCalculationParameters, fraction: Float) -> RectResult
}

// MARK: - Default Implementations

extension RepeatedExecutionsInThirdsCalculation {

    /// Default first rect: half of the screen (1/2).
    /// This is called when the user first triggers the action.
    func calculateFirstRect(_ params: RectCalculationParameters) -> RectResult {
        let halfScreen: Float = 1.0 / 2.0
        return calculateFractionalRect(params, fraction: halfScreen)
    }

    /// Converts a cycle size (like `.oneThird` or `.twoThirds`) to a fraction
    /// and calculates the corresponding rectangle.
    func calculateRect(for cycleDivision: CycleSize, params: RectCalculationParameters) -> RectResult {
        let fraction = cycleDivision.fraction
        return calculateFractionalRect(params, fraction: fraction)
    }
}
