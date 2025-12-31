//
//  LastThirdCalculation.swift
//  tiny_window_manager
//

import Foundation

/// Calculates window position for the "last third" of the screen.
/// In landscape mode: right 33% of screen
/// In portrait mode: bottom 33% of screen
///
/// Also handles reverse cycling through thirds when the user repeatedly triggers the action.
/// Cycling goes: last → center → first (opposite of FirstThirdCalculation)
class LastThirdCalculation: WindowCalculation, OrientationAware {

    // MARK: - Main Calculation

    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        print(#function, "called")
        let visibleFrameOfScreen = params.visibleFrameOfScreen

        // If cycling is disabled, just return the last third position
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

        // If we found a next position, use it; otherwise start over at last third
        if let nextCalculation = nextCalculation {
            return nextCalculation.calculateRect(params)
        }

        return orientationBasedRect(visibleFrameOfScreen)
    }

    // MARK: - Cycling Logic

    /// Determines which third calculation to use next based on the previous action.
    /// This creates the reverse cycling behavior: last → center → first → back to last
    private func findNextThirdCalculation(lastAction: WindowAction, lastSubAction: SubWindowAction) -> WindowCalculation? {
        print(#function, "called")

        // If user was on lastThird, cycle backward through the thirds
        if lastAction == .lastThird {
            return nextThirdWhenComingFromLast(lastSubAction: lastSubAction)
        }

        // If user was on firstThird, allow jumping to center third
        if lastAction == .firstThird {
            return nextThirdWhenComingFromFirst(lastSubAction: lastSubAction)
        }

        return nil
    }

    /// When cycling backward from lastThird action
    private func nextThirdWhenComingFromLast(lastSubAction: SubWindowAction) -> WindowCalculation? {
        print(#function, "called")
        switch lastSubAction {
        case .bottomThird, .rightThird:
            // Was at last third → move to center third
            return WindowCalculationFactory.centerThirdCalculation
        case .centerHorizontalThird, .centerVerticalThird:
            // Was at center third → move to first third
            return WindowCalculationFactory.firstThirdCalculation
        default:
            return nil
        }
    }

    /// When coming from firstThird action (allows wrap-around behavior)
    private func nextThirdWhenComingFromFirst(lastSubAction: SubWindowAction) -> WindowCalculation? {
        print(#function, "called")
        switch lastSubAction {
        case .bottomThird, .rightThird:
            // Was at first third → move to center third
            return WindowCalculationFactory.centerThirdCalculation
        default:
            return nil
        }
    }

    // MARK: - Orientation-Based Rectangles

    /// Returns a rectangle for the right 33% of the screen (landscape orientation)
    func landscapeRect(_ visibleFrameOfScreen: CGRect) -> RectResult {
        print(#function, "called")
        var rect = visibleFrameOfScreen

        // Calculate width as 1/3 of screen
        rect.size.width = floor(visibleFrameOfScreen.width / 3.0)

        // Position at the right edge of the screen
        rect.origin.x = visibleFrameOfScreen.origin.x + visibleFrameOfScreen.width - rect.width

        return RectResult(rect, subAction: .rightThird)
    }

    /// Returns a rectangle for the bottom 33% of the screen (portrait orientation)
    func portraitRect(_ visibleFrameOfScreen: CGRect) -> RectResult {
        print(#function, "called")
        var rect = visibleFrameOfScreen

        // Calculate height as 1/3 of screen
        rect.size.height = floor(visibleFrameOfScreen.height / 3.0)

        // Origin stays at bottom (Y=0 in macOS coordinates is at the bottom)

        return RectResult(rect, subAction: .bottomThird)
    }
}
