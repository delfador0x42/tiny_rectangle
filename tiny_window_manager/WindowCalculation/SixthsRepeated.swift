//
//  SixthsRepeated.swift
//  tiny_window_manager
//
//

import Foundation

// MARK: - Direction Enum

/// Represents the direction to cycle through sixth positions.
enum Direction {
    case left
    case right
}

// MARK: - SixthsRepeated Protocol

/// A protocol for window calculations that cycle through sixth positions when repeated.
///
/// The screen can be divided into 6 equal parts (sixths). When the user repeatedly
/// triggers a sixth-position action, the window cycles through all 6 positions in
/// either a left (counter-clockwise) or right (clockwise) direction.
///
/// ## Landscape Layout (3 columns × 2 rows)
/// ```
/// ┌─────────┬─────────┬─────────┐
/// │ Top-L   │ Top-C   │ Top-R   │
/// ├─────────┼─────────┼─────────┤
/// │ Bot-L   │ Bot-C   │ Bot-R   │
/// └─────────┴─────────┴─────────┘
///
/// Cycle order (right/clockwise):
/// Top-L → Top-C → Top-R → Bot-L → Bot-C → Bot-R → Top-L...
/// ```
///
/// ## Portrait Layout (2 columns × 3 rows)
/// ```
/// ┌─────────┬─────────┐
/// │ Top-L   │ Top-R   │
/// ├─────────┼─────────┤
/// │ Mid-L   │ Mid-R   │
/// ├─────────┼─────────┤
/// │ Bot-L   │ Bot-R   │
/// └─────────┴─────────┘
///
/// Cycle order (right/clockwise):
/// Top-L → Top-R → Mid-L → Mid-R → Bot-L → Bot-R → Top-L...
/// ```
protocol SixthsRepeated {

    /// Returns the next calculation in the cycle based on the current position and direction.
    ///
    /// - Parameters:
    ///   - subAction: The current sixth position (e.g., `.topLeftSixthLandscape`)
    ///   - direction: Which way to cycle (`.left` for counter-clockwise, `.right` for clockwise)
    /// - Returns: The calculation for the next position, or nil if the subAction isn't a sixth
    func nextCalculation(subAction: SubWindowAction, direction: Direction) -> SimpleCalc?
}

// MARK: - Default Implementation

extension SixthsRepeated {

    func nextCalculation(subAction: SubWindowAction, direction: Direction) -> SimpleCalc? {
        switch direction {
        case .left:
            return nextPositionGoingLeft(from: subAction)
        case .right:
            return nextPositionGoingRight(from: subAction)
        }
    }

    // MARK: - Private Helpers

    /// Returns the next sixth position when cycling left (counter-clockwise).
    /// This moves backwards through the cycle order.
    private func nextPositionGoingLeft(from subAction: SubWindowAction) -> SimpleCalc? {
        switch subAction {
        // Landscape layout: cycle backwards through the 6 positions
        case .topLeftSixthLandscape:
            return WindowCalculationFactory.bottomRightSixthCalculation.orientationBasedRect
        case .topCenterSixthLandscape:
            return WindowCalculationFactory.topLeftSixthCalculation.orientationBasedRect
        case .topRightSixthLandscape:
            return WindowCalculationFactory.topCenterSixthCalculation.orientationBasedRect
        case .bottomLeftSixthLandscape:
            return WindowCalculationFactory.topRightSixthCalculation.orientationBasedRect
        case .bottomCenterSixthLandscape:
            return WindowCalculationFactory.bottomLeftSixthCalculation.orientationBasedRect
        case .bottomRightSixthLandscape:
            return WindowCalculationFactory.bottomCenterSixthCalculation.orientationBasedRect

        // Portrait layout: cycle backwards through the 6 positions
        case .topLeftSixthPortrait:
            return WindowCalculationFactory.bottomRightSixthCalculation.orientationBasedRect
        case .topRightSixthPortrait:
            return WindowCalculationFactory.topLeftSixthCalculation.orientationBasedRect
        case .leftCenterSixthPortrait:
            return WindowCalculationFactory.topRightSixthCalculation.orientationBasedRect
        case .rightCenterSixthPortrait:
            return WindowCalculationFactory.topCenterSixthCalculation.orientationBasedRect
        case .bottomLeftSixthPortrait:
            return WindowCalculationFactory.bottomCenterSixthCalculation.orientationBasedRect
        case .bottomRightSixthPortrait:
            return WindowCalculationFactory.bottomLeftSixthCalculation.orientationBasedRect

        default:
            return nil
        }
    }

    /// Returns the next sixth position when cycling right (clockwise).
    /// This moves forward through the cycle order.
    private func nextPositionGoingRight(from subAction: SubWindowAction) -> SimpleCalc? {
        switch subAction {
        // Landscape layout: cycle forward through the 6 positions
        case .topLeftSixthLandscape:
            return WindowCalculationFactory.topCenterSixthCalculation.orientationBasedRect
        case .topCenterSixthLandscape:
            return WindowCalculationFactory.topRightSixthCalculation.orientationBasedRect
        case .topRightSixthLandscape:
            return WindowCalculationFactory.bottomLeftSixthCalculation.orientationBasedRect
        case .bottomLeftSixthLandscape:
            return WindowCalculationFactory.bottomCenterSixthCalculation.orientationBasedRect
        case .bottomCenterSixthLandscape:
            return WindowCalculationFactory.bottomRightSixthCalculation.orientationBasedRect
        case .bottomRightSixthLandscape:
            return WindowCalculationFactory.topLeftSixthCalculation.orientationBasedRect

        // Portrait layout: cycle forward through the 6 positions
        case .topLeftSixthPortrait:
            return WindowCalculationFactory.topRightSixthCalculation.orientationBasedRect
        case .topRightSixthPortrait:
            return WindowCalculationFactory.topCenterSixthCalculation.orientationBasedRect
        case .leftCenterSixthPortrait:
            return WindowCalculationFactory.bottomCenterSixthCalculation.orientationBasedRect
        case .rightCenterSixthPortrait:
            return WindowCalculationFactory.bottomLeftSixthCalculation.orientationBasedRect
        case .bottomLeftSixthPortrait:
            return WindowCalculationFactory.bottomRightSixthCalculation.orientationBasedRect
        case .bottomRightSixthPortrait:
            return WindowCalculationFactory.topLeftSixthCalculation.orientationBasedRect

        default:
            return nil
        }
    }
}
