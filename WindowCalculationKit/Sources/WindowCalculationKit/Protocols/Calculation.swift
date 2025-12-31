//
//  Calculation.swift
//  WindowCalculationKit
//
//  Core protocol for window calculations.
//

import Foundation

/// Protocol for window position calculations.
///
/// Conforming types implement the core calculation logic for positioning windows.
/// Each calculation takes parameters about the window and screen, and returns
/// a rectangle representing the target position.
public protocol Calculation: Sendable {

    /// Calculate the target rectangle for a window.
    ///
    /// This is the main entry point for calculations. Implementations should
    /// consider the current action, previous action (for cycling), and settings.
    ///
    /// - Parameter params: All information needed for the calculation.
    /// - Returns: The calculated result, or nil if the calculation cannot be performed.
    func calculateRect(_ params: CalculationParams) -> RectResult
}

// MARK: - Default Implementations

extension Calculation {

    /// Calculate first-time position (no cycling consideration).
    ///
    /// Override this for calculations that have different behavior on first vs repeated execution.
    public func calculateFirstRect(_ params: CalculationParams) -> RectResult {
        calculateRect(params)
    }
}
