//
//  FirstFourthCalculation.swift
//  tiny_window_manager
//

import Foundation

/// Calculates window position for the "first fourth" of the screen.
/// In landscape mode: left 25% of screen
/// In portrait mode: top 25% of screen
///
/// Also handles cycling through fourths when the user repeatedly triggers the action.
class FirstFourthCalculation: WindowCalculation, OrientationAware {

    // MARK: - Main Calculation

    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        let visibleFrameOfScreen = params.visibleFrameOfScreen

        // If cycling is disabled, just return the first fourth position
        let cyclingDisabled = Defaults.subsequentExecutionMode.value == .none
        if cyclingDisabled {
            return orientationBasedRect(visibleFrameOfScreen)
        }

        // Check if this is a repeated action that should cycle to the next fourth
        let isFirstFourthAction = params.action == .firstFourth
        guard isFirstFourthAction,
              let lastAction = params.lastAction,
              let lastSubAction = lastAction.subAction
        else {
            return orientationBasedRect(visibleFrameOfScreen)
        }

        // Determine which fourth to move to based on the previous position
        let nextCalculation = findNextFourthCalculation(
            lastAction: lastAction.action,
            lastSubAction: lastSubAction
        )

        // If we found a next position, use it; otherwise start over at first fourth
        if let nextCalculation = nextCalculation {
            return nextCalculation.calculateRect(params)
        }

        return orientationBasedRect(visibleFrameOfScreen)
    }

    // MARK: - Cycling Logic

    /// Determines which fourth calculation to use next based on the previous action.
    /// This creates the cycling behavior: 1st → 2nd → 3rd → 4th → back to 1st
    private func findNextFourthCalculation(lastAction: WindowAction, lastSubAction: SubWindowAction) -> WindowCalculation? {

        // If user was on firstFourth, cycle forward through the fourths
        if lastAction == .firstFourth {
            return nextFourthWhenComingFromFirst(lastSubAction: lastSubAction)
        }

        // If user was on lastFourth, allow jumping to second fourth
        if lastAction == .lastFourth {
            return nextFourthWhenComingFromLast(lastSubAction: lastSubAction)
        }

        return nil
    }

    /// When cycling forward from firstFourth action
    private func nextFourthWhenComingFromFirst(lastSubAction: SubWindowAction) -> WindowCalculation? {
        switch lastSubAction {
        case .topFourth, .leftFourth:
            // Was at 1st fourth → move to 2nd fourth
            return WindowCalculationFactory.secondFourthCalculation
        case .centerTopFourth, .centerLeftFourth:
            // Was at 2nd fourth → move to 3rd fourth
            return WindowCalculationFactory.thirdFourthCalculation
        case .centerBottomFourth, .centerRightFourth:
            // Was at 3rd fourth → move to 4th fourth
            return WindowCalculationFactory.lastFourthCalculation
        default:
            return nil
        }
    }

    /// When coming from lastFourth action (allows wrap-around behavior)
    private func nextFourthWhenComingFromLast(lastSubAction: SubWindowAction) -> WindowCalculation? {
        switch lastSubAction {
        case .leftFourth, .topFourth:
            // Was at 4th fourth → move to 2nd fourth
            return WindowCalculationFactory.secondFourthCalculation
        default:
            return nil
        }
    }

    // MARK: - Orientation-Based Rectangles

    /// Returns a rectangle for the left 25% of the screen (landscape orientation)
    func landscapeRect(_ visibleFrameOfScreen: CGRect) -> RectResult {
        var rect = visibleFrameOfScreen
        rect.size.width = floor(visibleFrameOfScreen.width / 4.0)
        return RectResult(rect, subAction: .leftFourth)
    }

    /// Returns a rectangle for the top 25% of the screen (portrait orientation)
    func portraitRect(_ visibleFrameOfScreen: CGRect) -> RectResult {
        var rect = visibleFrameOfScreen

        // Calculate height as 1/4 of screen
        rect.size.height = floor(visibleFrameOfScreen.height / 4.0)

        // Position at the top of the screen
        // (In macOS coordinates, higher Y = higher on screen)
        rect.origin.y = visibleFrameOfScreen.origin.y + visibleFrameOfScreen.height - rect.height

        return RectResult(rect, subAction: .topFourth)
    }
}
