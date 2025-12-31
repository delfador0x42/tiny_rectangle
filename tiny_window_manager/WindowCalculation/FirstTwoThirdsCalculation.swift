//
//  FirstTwoThirdsCalculation.swift
//  tiny_window_manager
//

import Foundation

/// Calculates window position for the "first two-thirds" of the screen (66%).
/// In landscape mode: left 66% of screen
/// In portrait mode: top 66% of screen
///
/// When cycling is enabled, toggles between first and last two-thirds positions.
class FirstTwoThirdsCalculation: WindowCalculation, OrientationAware {

    // MARK: - Main Calculation

    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        print(#function, "called")
        let visibleFrameOfScreen = params.visibleFrameOfScreen

        // If cycling is disabled, just return the first two-thirds position
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

        // If already at first two-thirds, toggle to last two-thirds
        let isCurrentlyAtFirstTwoThirds = (lastSubAction == .leftTwoThirds || lastSubAction == .topTwoThirds)
        if isCurrentlyAtFirstTwoThirds {
            return WindowCalculationFactory.lastTwoThirdsCalculation.orientationBasedRect(visibleFrameOfScreen)
        }

        return orientationBasedRect(visibleFrameOfScreen)
    }

    // MARK: - Orientation-Based Rectangles

    /// Returns a rectangle for the left 66% of the screen (landscape orientation)
    func landscapeRect(_ visibleFrameOfScreen: CGRect) -> RectResult {
        print(#function, "called")
        var rect = visibleFrameOfScreen
        rect.size.width = floor(visibleFrameOfScreen.width * 2 / 3.0)
        return RectResult(rect, subAction: .leftTwoThirds)
    }

    /// Returns a rectangle for the top 66% of the screen (portrait orientation)
    func portraitRect(_ visibleFrameOfScreen: CGRect) -> RectResult {
        print(#function, "called")
        var rect = visibleFrameOfScreen

        // Calculate height as 2/3 of screen
        rect.size.height = floor(visibleFrameOfScreen.height * 2 / 3.0)

        // Position at the top of the screen
        // (In macOS coordinates, higher Y = higher on screen)
        rect.origin.y = visibleFrameOfScreen.origin.y + visibleFrameOfScreen.height - rect.height

        return RectResult(rect, subAction: .topTwoThirds)
    }
}
