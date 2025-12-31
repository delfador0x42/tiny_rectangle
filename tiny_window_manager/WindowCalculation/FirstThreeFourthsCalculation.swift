//
//  FirstThreeFourthsCalculation.swift
//  tiny_window_manager
//

import Foundation

/// Calculates window position for the "first three-fourths" of the screen (75%).
/// In landscape mode: left 75% of screen
/// In portrait mode: top 75% of screen
///
/// When cycling is enabled, toggles between first and last three-fourths positions.
class FirstThreeFourthsCalculation: WindowCalculation, OrientationAware {

    // MARK: - Main Calculation

    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        print(#function, "called")
        let visibleFrameOfScreen = params.visibleFrameOfScreen

        // If cycling is disabled, just return the first three-fourths position
        let cyclingDisabled = Defaults.subsequentExecutionMode.value == .none
        if cyclingDisabled {
            return orientationBasedRect(visibleFrameOfScreen)
        }

        // Check if we have a previous action to toggle from
        guard let lastAction = params.lastAction,
              let lastSubAction = lastAction.subAction
        else {
            return orientationBasedRect(visibleFrameOfScreen)
        }

        // If already at first three-fourths, toggle to last three-fourths
        let isCurrentlyAtFirstThreeFourths = (lastSubAction == .leftThreeFourths || lastSubAction == .topThreeFourths)
        if isCurrentlyAtFirstThreeFourths {
            return WindowCalculationFactory.lastThreeFourthsCalculation.orientationBasedRect(visibleFrameOfScreen)
        }

        return orientationBasedRect(visibleFrameOfScreen)
    }

    // MARK: - Orientation-Based Rectangles

    /// Returns a rectangle for the left 75% of the screen (landscape orientation)
    func landscapeRect(_ visibleFrameOfScreen: CGRect) -> RectResult {
        print(#function, "called")
        var rect = visibleFrameOfScreen
        rect.size.width = floor(visibleFrameOfScreen.width * 3 / 4.0)
        return RectResult(rect, subAction: .leftThreeFourths)
    }

    /// Returns a rectangle for the top 75% of the screen (portrait orientation)
    func portraitRect(_ visibleFrameOfScreen: CGRect) -> RectResult {
        print(#function, "called")
        var rect = visibleFrameOfScreen

        // Calculate height as 3/4 of screen
        rect.size.height = floor(visibleFrameOfScreen.height * 3 / 4.0)

        // Position at the top of the screen
        // (In macOS coordinates, higher Y = higher on screen)
        rect.origin.y = visibleFrameOfScreen.origin.y + visibleFrameOfScreen.height - rect.height

        return RectResult(rect, subAction: .topThreeFourths)
    }
}
