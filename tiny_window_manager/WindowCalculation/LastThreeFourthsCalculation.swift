//
//  LastThreeFourthsCalculation.swift
//  tiny_window_manager
//

import Foundation

/// Calculates window position for the "last three-fourths" of the screen (75%).
/// In landscape mode: right 75% of screen
/// In portrait mode: bottom 75% of screen
///
/// When cycling is enabled, toggles between last and first three-fourths positions.
class LastThreeFourthsCalculation: WindowCalculation, OrientationAware {

    // MARK: - Main Calculation

    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        let visibleFrameOfScreen = params.visibleFrameOfScreen

        // If cycling is disabled, just return the last three-fourths position
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

        // If already at last three-fourths, toggle to first three-fourths
        let isCurrentlyAtLastThreeFourths = (lastSubAction == .rightThreeFourths || lastSubAction == .bottomThreeFourths)
        if isCurrentlyAtLastThreeFourths {
            return WindowCalculationFactory.firstThreeFourthsCalculation.orientationBasedRect(visibleFrameOfScreen)
        }

        return orientationBasedRect(visibleFrameOfScreen)
    }

    // MARK: - Orientation-Based Rectangles

    /// Returns a rectangle for the right 75% of the screen (landscape orientation)
    func landscapeRect(_ visibleFrameOfScreen: CGRect) -> RectResult {
        var rect = visibleFrameOfScreen

        // Calculate width as 3/4 of screen
        rect.size.width = floor(visibleFrameOfScreen.width * 3 / 4.0)

        // Position at the right edge of the screen
        rect.origin.x = visibleFrameOfScreen.minX + visibleFrameOfScreen.width - rect.width

        return RectResult(rect, subAction: .rightThreeFourths)
    }

    /// Returns a rectangle for the bottom 75% of the screen (portrait orientation)
    func portraitRect(_ visibleFrameOfScreen: CGRect) -> RectResult {
        var rect = visibleFrameOfScreen

        // Calculate height as 3/4 of screen
        rect.size.height = floor(visibleFrameOfScreen.height * 3 / 4.0)

        // Origin stays at bottom (Y=0 in macOS coordinates is at the bottom)

        return RectResult(rect, subAction: .bottomThreeFourths)
    }
}
