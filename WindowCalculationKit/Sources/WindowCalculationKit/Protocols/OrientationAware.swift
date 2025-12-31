//
//  OrientationAware.swift
//  WindowCalculationKit
//
//  Protocol for calculations that behave differently in landscape vs portrait.
//

import CoreGraphics

/// Protocol for calculations that adapt to screen orientation.
///
/// Implementations provide separate calculation logic for landscape and portrait
/// orientations. The protocol's default implementation handles orientation detection
/// and dispatches to the appropriate method.
///
/// ## Example
/// ```swift
/// class FirstThirdCalculation: Calculation, OrientationAware {
///     func landscapeRect(_ frame: CGRect, _ params: CalculationParams) -> RectResult {
///         // Return left third (vertical strip)
///     }
///
///     func portraitRect(_ frame: CGRect, _ params: CalculationParams) -> RectResult {
///         // Return top third (horizontal strip)
///     }
/// }
/// ```
public protocol OrientationAware: Calculation {

    /// Calculate the rectangle for landscape orientation.
    ///
    /// In landscape, typically divide width (left/center/right).
    ///
    /// - Parameters:
    ///   - frame: The visible screen frame.
    ///   - params: Full calculation parameters.
    /// - Returns: The calculated result for landscape.
    func landscapeRect(_ frame: CGRect, _ params: CalculationParams) -> RectResult

    /// Calculate the rectangle for portrait orientation.
    ///
    /// In portrait, typically divide height (top/center/bottom).
    ///
    /// - Parameters:
    ///   - frame: The visible screen frame.
    ///   - params: Full calculation parameters.
    /// - Returns: The calculated result for portrait.
    func portraitRect(_ frame: CGRect, _ params: CalculationParams) -> RectResult
}

// MARK: - Default Implementation

extension OrientationAware {

    /// Default implementation that dispatches based on orientation.
    public func calculateRect(_ params: CalculationParams) -> RectResult {
        let frame = params.visibleFrame
        if params.isLandscape {
            return landscapeRect(frame, params)
        } else {
            return portraitRect(frame, params)
        }
    }
}
