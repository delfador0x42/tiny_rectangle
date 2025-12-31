//
//  LastFourthCalculation.swift
//  tiny_window_manager
//

import Foundation

/// Calculates window position for the "last fourth" of the screen.
/// In landscape mode: right 25% of screen
/// In portrait mode: bottom 25% of screen
///
/// Also handles reverse cycling through fourths when the user repeatedly triggers the action.
/// Cycling goes: 4th → 3rd → 2nd → 1st (opposite of FirstFourthCalculation)
class LastFourthCalculation: WindowCalculation, OrientationAware {

    // MARK: - Main Calculation

    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        print(#function, "called")
        let visibleFrameOfScreen = params.visibleFrameOfScreen

        // If cycling is disabled, just return the last fourth position
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

        // Determine which fourth to move to based on the previous position
        let nextCalculation = findNextFourthCalculation(
            lastAction: lastAction.action,
            lastSubAction: lastSubAction
        )

        // If we found a next position, use it; otherwise start over at last fourth
        if let nextCalculation = nextCalculation {
            return nextCalculation.calculateRect(params)
        }

        return orientationBasedRect(visibleFrameOfScreen)
    }

    // MARK: - Cycling Logic

    /// Determines which fourth calculation to use next based on the previous action.
    /// This creates the reverse cycling behavior: 4th → 3rd → 2nd → 1st → back to 4th
    private func findNextFourthCalculation(lastAction: WindowAction, lastSubAction: SubWindowAction) -> WindowCalculation? {
        print(#function, "called")

        // If user was on lastFourth, cycle backward through the fourths
        if lastAction == .lastFourth {
            return nextFourthWhenComingFromLast(lastSubAction: lastSubAction)
        }

        // If user was on firstFourth, allow jumping to third fourth
        if lastAction == .firstFourth {
            return nextFourthWhenComingFromFirst(lastSubAction: lastSubAction)
        }

        return nil
    }

    /// When cycling backward from lastFourth action
    private func nextFourthWhenComingFromLast(lastSubAction: SubWindowAction) -> WindowCalculation? {
        print(#function, "called")
        switch lastSubAction {
        case .bottomFourth, .rightFourth:
            // Was at 4th fourth → move to 3rd fourth
            return WindowCalculationFactory.thirdFourthCalculation
        case .centerBottomFourth, .centerRightFourth:
            // Was at 3rd fourth → move to 2nd fourth
            return WindowCalculationFactory.secondFourthCalculation
        case .centerTopFourth, .centerLeftFourth:
            // Was at 2nd fourth → move to 1st fourth
            return WindowCalculationFactory.firstFourthCalculation
        default:
            return nil
        }
    }

    /// When coming from firstFourth action (allows wrap-around behavior)
    private func nextFourthWhenComingFromFirst(lastSubAction: SubWindowAction) -> WindowCalculation? {
        print(#function, "called")
        switch lastSubAction {
        case .bottomFourth, .rightFourth:
            // Was at 1st fourth → move to 3rd fourth
            return WindowCalculationFactory.thirdFourthCalculation
        default:
            return nil
        }
    }

    // MARK: - Orientation-Based Rectangles

    /// Returns a rectangle for the right 25% of the screen (landscape orientation)
    func landscapeRect(_ visibleFrameOfScreen: CGRect) -> RectResult {
        print(#function, "called")
        var rect = visibleFrameOfScreen

        // Calculate width as 1/4 of screen
        rect.size.width = floor(visibleFrameOfScreen.width / 4.0)

        // Position at the right edge of the screen
        rect.origin.x = visibleFrameOfScreen.origin.x + visibleFrameOfScreen.width - rect.width

        return RectResult(rect, subAction: .rightFourth)
    }

    /// Returns a rectangle for the bottom 25% of the screen (portrait orientation)
    func portraitRect(_ visibleFrameOfScreen: CGRect) -> RectResult {
        print(#function, "called")
        var rect = visibleFrameOfScreen

        // Calculate height as 1/4 of screen
        rect.size.height = floor(visibleFrameOfScreen.height / 4.0)

        // Origin stays at bottom (Y=0 in macOS coordinates is at the bottom)

        return RectResult(rect, subAction: .bottomFourth)
    }
}
