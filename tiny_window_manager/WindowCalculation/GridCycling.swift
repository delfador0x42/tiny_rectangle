//
//  GridCycling.swift
//  tiny_window_manager
//

import Foundation

/// Handles cycling through grid positions when the user repeatedly triggers the same action.
///
/// When a user presses the same keyboard shortcut multiple times, we want to cycle
/// through different grid positions. For example, pressing "ninths" repeatedly cycles:
/// top-left → top-center → top-right → middle-left → ... → bottom-right → back to top-left
///
/// The cycling direction can be left or right (for reverse cycling).
struct GridCycling {

    // MARK: - Cycling Orders

    // These arrays define the order in which we cycle through positions.
    // The order follows a natural reading pattern: left-to-right, top-to-bottom.

    /// Ninths: 3×3 grid, cycles through all 9 positions
    /// ```
    /// [1] [2] [3]
    /// [4] [5] [6]
    /// [7] [8] [9]
    /// ```
    private static let ninthsOrder: [SubWindowAction] = [
        .topLeftNinth, .topCenterNinth, .topRightNinth,
        .middleLeftNinth, .middleCenterNinth, .middleRightNinth,
        .bottomLeftNinth, .bottomCenterNinth, .bottomRightNinth
    ]

    /// Eighths: 4×2 grid, cycles through all 8 positions
    /// ```
    /// [1] [2] [3] [4]
    /// [5] [6] [7] [8]
    /// ```
    private static let eighthsOrder: [SubWindowAction] = [
        .topLeftEighth, .topCenterLeftEighth, .topCenterRightEighth, .topRightEighth,
        .bottomLeftEighth, .bottomCenterLeftEighth, .bottomCenterRightEighth, .bottomRightEighth
    ]

    /// Corner thirds: 2×2 grid of larger cells, cycles through all 4 corners
    /// ```
    /// [1] [2]
    /// [3] [4]
    /// ```
    private static let cornerThirdsOrder: [SubWindowAction] = [
        .topLeftThird, .topRightThird, .bottomLeftThird, .bottomRightThird
    ]

    // MARK: - Public API

    /// Finds the next grid position calculation in the cycle.
    ///
    /// - Parameters:
    ///   - gridType: Which type of grid we're cycling through (ninths, eighths, cornerThirds)
    ///   - currentSubAction: The user's current position in the grid
    ///   - direction: Which direction to cycle (.right = forward, .left = backward)
    /// - Returns: A calculation function for the next position, or nil if current position isn't in the cycle
    static func nextCalculation(for gridType: GridType, currentSubAction: SubWindowAction, direction: Direction) -> SimpleCalc? {
        print(#function, "called")

        // Get the cycling order and calculation lookup function for this grid type
        let (order, getCalculation) = cyclingConfiguration(for: gridType)

        // Find where the user currently is in the cycle
        guard let currentIndex = order.firstIndex(of: currentSubAction) else {
            // Current position isn't part of this grid's cycle
            return nil
        }

        // Calculate the next index, wrapping around at the ends
        let nextIndex = calculateNextIndex(
            currentIndex: currentIndex,
            totalCount: order.count,
            direction: direction
        )

        // Get the calculation for the next position
        let nextSubAction = order[nextIndex]
        return getCalculation(nextSubAction)
    }

    // MARK: - Private Helpers

    /// Returns the cycling order and calculation lookup function for a grid type.
    private static func cyclingConfiguration(for gridType: GridType) -> (order: [SubWindowAction], getCalculation: (SubWindowAction) -> SimpleCalc?) {
        print(#function, "called")
        switch gridType {
        case .ninths:
            return (ninthsOrder, getNinthCalculation)
        case .eighths:
            return (eighthsOrder, getEighthCalculation)
        case .cornerThirds:
            return (cornerThirdsOrder, getCornerThirdCalculation)
        }
    }

    /// Calculates the next index in a circular array.
    ///
    /// - Parameters:
    ///   - currentIndex: Current position in the array
    ///   - totalCount: Total number of elements in the array
    ///   - direction: Which way to move (.right = +1, .left = -1)
    /// - Returns: The next index, wrapping around if necessary
    private static func calculateNextIndex(currentIndex: Int, totalCount: Int, direction: Direction) -> Int {
        print(#function, "called")
        switch direction {
        case .right:
            // Move forward, wrap from last to first
            return (currentIndex + 1) % totalCount
        case .left:
            // Move backward, wrap from first to last
            // Adding totalCount before mod ensures we don't get negative numbers
            return (currentIndex - 1 + totalCount) % totalCount
        }
    }

    // MARK: - Calculation Lookups

    // These functions map SubWindowAction values to their corresponding calculation functions.
    // Each returns a SimpleCalc (a function that takes a screen rect and returns a RectResult).

    /// Looks up the calculation function for a ninths position
    private static func getNinthCalculation(for subAction: SubWindowAction) -> SimpleCalc? {
        print(#function, "called")
        switch subAction {
        case .topLeftNinth:
            return WindowCalculationFactory.topLeftNinthCalculation.orientationBasedRect
        case .topCenterNinth:
            return WindowCalculationFactory.topCenterNinthCalculation.orientationBasedRect
        case .topRightNinth:
            return WindowCalculationFactory.topRightNinthCalculation.orientationBasedRect
        case .middleLeftNinth:
            return WindowCalculationFactory.middleLeftNinthCalculation.orientationBasedRect
        case .middleCenterNinth:
            return WindowCalculationFactory.middleCenterNinthCalculation.orientationBasedRect
        case .middleRightNinth:
            return WindowCalculationFactory.middleRightNinthCalculation.orientationBasedRect
        case .bottomLeftNinth:
            return WindowCalculationFactory.bottomLeftNinthCalculation.orientationBasedRect
        case .bottomCenterNinth:
            return WindowCalculationFactory.bottomCenterNinthCalculation.orientationBasedRect
        case .bottomRightNinth:
            return WindowCalculationFactory.bottomRightNinthCalculation.orientationBasedRect
        default:
            return nil
        }
    }

    /// Looks up the calculation function for an eighths position
    private static func getEighthCalculation(for subAction: SubWindowAction) -> SimpleCalc? {
        print(#function, "called")
        switch subAction {
        case .topLeftEighth:
            return WindowCalculationFactory.topLeftEighthCalculation.orientationBasedRect
        case .topCenterLeftEighth:
            return WindowCalculationFactory.topCenterLeftEighthCalculation.orientationBasedRect
        case .topCenterRightEighth:
            return WindowCalculationFactory.topCenterRightEighthCalculation.orientationBasedRect
        case .topRightEighth:
            return WindowCalculationFactory.topRightEighthCalculation.orientationBasedRect
        case .bottomLeftEighth:
            return WindowCalculationFactory.bottomLeftEighthCalculation.orientationBasedRect
        case .bottomCenterLeftEighth:
            return WindowCalculationFactory.bottomCenterLeftEighthCalculation.orientationBasedRect
        case .bottomCenterRightEighth:
            return WindowCalculationFactory.bottomCenterRightEighthCalculation.orientationBasedRect
        case .bottomRightEighth:
            return WindowCalculationFactory.bottomRightEighthCalculation.orientationBasedRect
        default:
            return nil
        }
    }

    /// Looks up the calculation function for a corner thirds position
    private static func getCornerThirdCalculation(for subAction: SubWindowAction) -> SimpleCalc? {
        print(#function, "called")
        switch subAction {
        case .topLeftThird:
            return WindowCalculationFactory.topLeftThirdCalculation.orientationBasedRect
        case .topRightThird:
            return WindowCalculationFactory.topRightThirdCalculation.orientationBasedRect
        case .bottomLeftThird:
            return WindowCalculationFactory.bottomLeftThirdCalculation.orientationBasedRect
        case .bottomRightThird:
            return WindowCalculationFactory.bottomRightThirdCalculation.orientationBasedRect
        default:
            return nil
        }
    }
}
