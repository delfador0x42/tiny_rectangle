//
//  SecondFourthCalculation.swift
//  tiny_window_manager
//
//

import Foundation

/// Positions a window in the second quarter of the screen.
///
/// The "second fourth" is the quarter that's one step in from the edge:
/// - **Landscape (wide screens)**: Second column from the left (positions 25%-50% horizontally)
/// - **Portrait (tall screens)**: Second row from the top (positions 50%-75% vertically)
///
/// ## Visual Examples
///
/// **Landscape mode:**
/// ```
/// ┌───────┬───────┬───────┬───────┐
/// │       │XXXXXXX│       │       │
/// │   1   │   2   │   3   │   4   │
/// │       │XXXXXXX│       │       │
/// └───────┴───────┴───────┴───────┘
/// ```
///
/// **Portrait mode:**
/// ```
/// ┌───────────┐
/// │     1     │
/// ├───────────┤
/// │XXXXXXXXXXX│  ← Second fourth
/// ├───────────┤
/// │     3     │
/// ├───────────┤
/// │     4     │
/// └───────────┘
/// ```
///
/// ## Cycling Behavior
/// When executed repeatedly, this calculation cycles through related layouts:
/// - Second fourth → Last three-fourths → Center half → (back to start)
class SecondFourthCalculation: WindowCalculation, OrientationAware {

    // MARK: - Main Calculation

    /// Calculates the window rectangle, handling both first execution and cycling.
    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        let visibleFrameOfScreen = params.visibleFrameOfScreen

        // Check if this is a repeated execution that should cycle to a different layout
        guard let nextCalculation = getNextCalculationInCycle(params: params) else {
            // First execution or cycling disabled: use the orientation-based default
            return orientationBasedRect(visibleFrameOfScreen)
        }

        return nextCalculation(visibleFrameOfScreen)
    }

    // MARK: - OrientationAware Implementation

    /// Landscape layout: Second column from the left (25%-50% of screen width).
    func landscapeRect(_ visibleFrameOfScreen: CGRect) -> RectResult {
        var rect = visibleFrameOfScreen

        // Width is 1/4 of the screen
        let quarterWidth = floor(visibleFrameOfScreen.width / 4.0)
        rect.size.width = quarterWidth

        // Position starts at the end of the first quarter
        rect.origin.x = visibleFrameOfScreen.minX + quarterWidth

        return RectResult(rect, subAction: .centerLeftFourth)
    }

    /// Portrait layout: Second row from the top (50%-75% of screen height, measured from bottom).
    func portraitRect(_ visibleFrameOfScreen: CGRect) -> RectResult {
        var rect = visibleFrameOfScreen

        // Height is 1/4 of the screen
        let quarterHeight = floor(visibleFrameOfScreen.height / 4.0)
        rect.size.height = quarterHeight

        // Position is 2 quarters down from the top (remember: macOS y-axis starts at bottom)
        // So we calculate: bottom + total height - (2 * quarter height)
        rect.origin.y = visibleFrameOfScreen.minY + visibleFrameOfScreen.height - (quarterHeight * 2.0)

        return RectResult(rect, subAction: .centerTopFourth)
    }

    // MARK: - Private Helpers

    /// Determines the next calculation in the cycle based on the last action.
    /// Returns nil if this is the first execution or cycling is disabled.
    private func getNextCalculationInCycle(params: RectCalculationParameters) -> SimpleCalc? {
        // Check if cycling is enabled
        let cyclingEnabled = Defaults.subsequentExecutionMode.value != .none
        guard cyclingEnabled else {
            return nil
        }

        // Check if this is a repeated execution of the same action
        guard let lastAction = params.lastAction,
              lastAction.action == .secondFourth,
              let lastSubAction = lastAction.subAction
        else {
            return nil
        }

        // Determine the next layout based on what was shown last
        return getNextCalculation(after: lastSubAction)
    }

    /// Maps each sub-action to the next calculation in the cycle.
    ///
    /// Cycle order:
    /// - centerLeftFourth → lastThreeFourths (landscape)
    /// - centerTopFourth → lastThreeFourths (portrait)
    /// - rightThreeFourths → centerHalf (landscape)
    /// - bottomThreeFourths → centerHalf (portrait)
    private func getNextCalculation(after lastSubAction: SubWindowAction) -> SimpleCalc {
        switch lastSubAction {
        case .centerLeftFourth:
            // From second-fourth landscape → expand to last three-fourths
            return WindowCalculationFactory.lastThreeFourthsCalculation.landscapeRect

        case .centerTopFourth:
            // From second-fourth portrait → expand to last three-fourths
            return WindowCalculationFactory.lastThreeFourthsCalculation.portraitRect

        case .rightThreeFourths:
            // From last three-fourths landscape → shrink to center half
            return WindowCalculationFactory.centerHalfCalculation.landscapeRect

        case .bottomThreeFourths:
            // From last three-fourths portrait → shrink to center half
            return WindowCalculationFactory.centerHalfCalculation.portraitRect

        default:
            // Unknown state: reset to orientation-based default
            return orientationBasedRect
        }
    }
}
