//
//  FirstThirdCalculation.swift
//  tiny_window_manager
//

import Foundation

/// Calculates window position for the "first third" of the screen.
/// In landscape mode: left 33% of screen
/// In portrait mode: top 33% of screen
///
/// Also handles cycling through thirds when the user repeatedly triggers the action.
class FirstThirdCalculation: WindowCalculation, OrientationAware {

    // MARK: - Main Calculation

    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        let visibleFrameOfScreen = params.visibleFrameOfScreen

        // If cycling is disabled, just return the first third position
        let cyclingDisabled = Defaults.subsequentExecutionMode.value == .none
        if cyclingDisabled {
            return orientationBasedRect(visibleFrameOfScreen)
        }

        // Check if we have a previous action to cycle from
        guard let lastAction = params.lastAction,
              let lastSubAction = lastAction.subAction
        else {
            return orientationBasedRect(visibleFrameOfScreen)
        }

        // Determine which third to move to based on the previous position
        let nextCalculation = findNextThirdCalculation(
            lastAction: lastAction.action,
            lastSubAction: lastSubAction
        )

        // If we found a next position, use it; otherwise start over at first third
        if let nextCalculation = nextCalculation {
            return nextCalculation.calculateRect(params)
        }

        return orientationBasedRect(visibleFrameOfScreen)
    }

    // MARK: - Cycling Logic

    /// Determines which third calculation to use next based on the previous action.
    /// This creates the cycling behavior: 1st → center → last → back to 1st
    private func findNextThirdCalculation(lastAction: WindowAction, lastSubAction: SubWindowAction) -> WindowCalculation? {

        // If user was on firstThird, cycle forward through the thirds
        if lastAction == .firstThird {
            return nextThirdWhenComingFromFirst(lastSubAction: lastSubAction)
        }

        // If user was on lastThird, allow jumping to center third
        if lastAction == .lastThird {
            return nextThirdWhenComingFromLast(lastSubAction: lastSubAction)
        }

        return nil
    }

    /// When cycling forward from firstThird action
    private func nextThirdWhenComingFromFirst(lastSubAction: SubWindowAction) -> WindowCalculation? {
        switch lastSubAction {
        case .topThird, .leftThird:
            // Was at 1st third → move to center third
            return WindowCalculationFactory.centerThirdCalculation
        case .centerHorizontalThird, .centerVerticalThird:
            // Was at center third → move to last third
            return WindowCalculationFactory.lastThirdCalculation
        default:
            return nil
        }
    }

    /// When coming from lastThird action (allows wrap-around behavior)
    private func nextThirdWhenComingFromLast(lastSubAction: SubWindowAction) -> WindowCalculation? {
        switch lastSubAction {
        case .topThird, .leftThird:
            // Was at last third → move to center third
            return WindowCalculationFactory.centerThirdCalculation
        default:
            return nil
        }
    }

    // MARK: - Orientation-Based Rectangles

    /// Returns a rectangle for the left 33% of the screen (landscape orientation)
    func landscapeRect(_ visibleFrameOfScreen: CGRect) -> RectResult {
        var rect = visibleFrameOfScreen
        rect.size.width = floor(visibleFrameOfScreen.width / 3.0)
        return RectResult(rect, subAction: .leftThird)
    }

    /// Returns a rectangle for the top 33% of the screen (portrait orientation)
    func portraitRect(_ visibleFrameOfScreen: CGRect) -> RectResult {
        var rect = visibleFrameOfScreen

        // Calculate height as 1/3 of screen
        rect.size.height = floor(visibleFrameOfScreen.height / 3.0)

        // Position at the top of the screen
        // (In macOS coordinates, higher Y = higher on screen)
        rect.origin.y = visibleFrameOfScreen.minY + visibleFrameOfScreen.height - rect.height

        return RectResult(rect, subAction: .topThird)
    }
}
