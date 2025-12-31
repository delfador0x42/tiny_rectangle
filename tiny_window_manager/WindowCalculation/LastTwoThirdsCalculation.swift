//
//  LastTwoThirdsCalculation.swift
//  tiny_window_manager
//
//  Positions a window to occupy the last (right or bottom) two-thirds of the screen.
//  - Landscape screens: window goes to the RIGHT two-thirds
//  - Portrait screens: window goes to the BOTTOM two-thirds
//

import Foundation

/// Calculates window position for the "last two-thirds" of the screen.
/// "Last" means right side for landscape monitors, bottom for portrait monitors.
class LastTwoThirdsCalculation: WindowCalculation, OrientationAware {

    // MARK: - Main Calculation

    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        print(#function, "called")
        let screenFrame = params.visibleFrameOfScreen

        // Check if we should handle repeated keyboard shortcut presses
        let shouldCycleThroughPositions = Defaults.subsequentExecutionMode.value != .none
        let lastAction = params.lastAction
        let lastSubAction = lastAction?.subAction

        // If cycling is disabled or there's no previous action, use default position
        let hasPreviousAction = lastAction != nil && lastSubAction != nil
        if !shouldCycleThroughPositions || !hasPreviousAction {
            return orientationBasedRect(screenFrame)
        }

        // If user already used "last two-thirds", cycle to "first two-thirds" instead
        let wasAlreadyInLastTwoThirds = lastSubAction == .rightTwoThirds || lastSubAction == .bottomTwoThirds
        if wasAlreadyInLastTwoThirds {
            return WindowCalculationFactory.firstTwoThirdsCalculation.orientationBasedRect(screenFrame)
        }

        // Default: position window in the last two-thirds
        return orientationBasedRect(screenFrame)
    }

    // MARK: - Landscape Mode (Wide Screens)

    /// Positions the window in the RIGHT two-thirds of a landscape screen.
    func landscapeRect(_ screenFrame: CGRect) -> RectResult {
        print(#function, "called")
        // Calculate two-thirds of the screen width
        let twoThirdsWidth = floor(screenFrame.width * 2 / 3.0)

        // Position window on the right side
        let xPosition = screenFrame.minX + screenFrame.width - twoThirdsWidth

        // Build the final rectangle
        var windowRect = screenFrame
        windowRect.size.width = twoThirdsWidth
        windowRect.origin.x = xPosition

        return RectResult(windowRect, subAction: .rightTwoThirds)
    }

    // MARK: - Portrait Mode (Tall Screens)

    /// Positions the window in the BOTTOM two-thirds of a portrait screen.
    func portraitRect(_ screenFrame: CGRect) -> RectResult {
        print(#function, "called")
        // Calculate two-thirds of the screen height
        let twoThirdsHeight = floor(screenFrame.height * 2 / 3.0)

        // Build the final rectangle (origin stays at bottom-left in macOS coordinates)
        var windowRect = screenFrame
        windowRect.size.height = twoThirdsHeight

        return RectResult(windowRect, subAction: .bottomTwoThirds)
    }
}

