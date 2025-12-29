//
//  BottomRightSixthCalculation.swift
//  tiny_window_manager
//
//

import Foundation

/// Calculates window position for the bottom-right sixth of the screen.
/// Supports both landscape (3 columns x 2 rows) and portrait (2 columns x 3 rows) layouts.
class BottomRightSixthCalculation: WindowCalculation, OrientationAware, SixthsRepeated {

    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        let screenFrame = params.visibleFrameOfScreen

        // If cycling through positions is disabled, just return the default position
        let cyclingEnabled = Defaults.subsequentExecutionMode.value != .none
        guard cyclingEnabled else {
            return orientationBasedRect(screenFrame)
        }

        // If there's no previous action to cycle from, use the default position
        guard let lastAction = params.lastAction,
              let lastSubAction = lastAction.subAction else {
            return orientationBasedRect(screenFrame)
        }

        // Only cycle if the last action was also a bottom-right-sixth action
        let isRelevantAction = lastAction.action == .bottomRightSixth
            || lastSubAction == .bottomRightSixthLandscape
            || lastSubAction == .bottomRightSixthPortrait

        guard isRelevantAction else {
            return orientationBasedRect(screenFrame)
        }

        // Try to get the next position in the cycle (moving left)
        if let nextCalculation = self.nextCalculation(subAction: lastSubAction, direction: .left) {
            return nextCalculation(screenFrame)
        }

        return orientationBasedRect(screenFrame)
    }

    /// Calculates the bottom-right cell in a 3-column x 2-row grid (landscape mode).
    func landscapeRect(_ screenFrame: CGRect) -> RectResult {
        let cellWidth = floor(screenFrame.width / 3.0)
        let cellHeight = floor(screenFrame.height / 2.0)

        // Position at the right edge of the screen
        let xPosition = screenFrame.origin.x + screenFrame.width - cellWidth
        let yPosition = screenFrame.origin.y

        let rect = CGRect(x: xPosition, y: yPosition, width: cellWidth, height: cellHeight)
        return RectResult(rect, subAction: .bottomRightSixthLandscape)
    }

    /// Calculates the bottom-right cell in a 2-column x 3-row grid (portrait mode).
    func portraitRect(_ screenFrame: CGRect) -> RectResult {
        let cellWidth = floor(screenFrame.width / 2.0)
        let cellHeight = floor(screenFrame.height / 3.0)

        // Position at the right edge of the screen
        let xPosition = screenFrame.origin.x + screenFrame.width - cellWidth
        let yPosition = screenFrame.origin.y

        let rect = CGRect(x: xPosition, y: yPosition, width: cellWidth, height: cellHeight)
        return RectResult(rect, subAction: .bottomRightSixthPortrait)
    }
}
