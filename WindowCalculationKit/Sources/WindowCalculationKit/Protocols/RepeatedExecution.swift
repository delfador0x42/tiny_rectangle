//
//  RepeatedExecution.swift
//  WindowCalculationKit
//
//  Protocol for calculations that support cycling through sizes on repeated execution.
//

import Foundation

/// Protocol for calculations that cycle through sizes on repeated execution.
///
/// When the user presses the same shortcut multiple times, the window can
/// cycle through different sizes (e.g., 1/2 → 2/3 → 1/3 → 1/2).
///
/// ## Example
/// ```swift
/// class LeftHalfCalculation: Calculation, RepeatedExecution {
///     func calculateFirstRect(_ params: CalculationParams) -> RectResult {
///         // Return left half (width = 1/2)
///     }
///
///     func calculateFractionalRect(_ params: CalculationParams, fraction: Float) -> RectResult {
///         // Return left portion with given fraction
///     }
/// }
/// ```
public protocol RepeatedExecution: Calculation {

    /// Calculate the rectangle for the first execution (before cycling starts).
    func calculateFirstRect(_ params: CalculationParams) -> RectResult

    /// Calculate the rectangle for a specific size fraction.
    ///
    /// - Parameters:
    ///   - params: Calculation parameters.
    ///   - fraction: The size fraction (e.g., 0.5 for half, 0.667 for two-thirds).
    /// - Returns: The calculated result.
    func calculateFractionalRect(_ params: CalculationParams, fraction: Float) -> RectResult
}

// MARK: - Default Implementation

extension RepeatedExecution {

    /// Default implementation that handles cycling logic.
    public func calculateRect(_ params: CalculationParams) -> RectResult {
        let isFirstExecution = params.lastAction == nil
        let cyclingDisabled = !params.settings.cyclingEnabled

        if isFirstExecution || cyclingDisabled {
            return calculateFirstRect(params)
        }

        return calculateRepeatedRect(params)
    }

    /// Calculate the rectangle for a repeated execution (cycling).
    public func calculateRepeatedRect(_ params: CalculationParams) -> RectResult {
        let cycleSizes = params.settings.cycleSizes.sortedForCycle
        guard !cycleSizes.isEmpty else {
            return calculateFirstRect(params)
        }

        // Determine position in cycle
        let repeatCount = (params.lastAction?.count ?? 0) + 1
        let cycleIndex = repeatCount % cycleSizes.count
        let fraction = cycleSizes[cycleIndex].fraction

        return calculateFractionalRect(params, fraction: fraction)
    }
}

/// Protocol for calculations that cycle through sizes in thirds (1/2, 2/3, 1/3).
///
/// This is a specialized version of RepeatedExecution that defaults to
/// the common "thirds" cycling pattern.
public protocol RepeatedExecutionInThirds: RepeatedExecution {
    // Inherits all behavior from RepeatedExecution
}
