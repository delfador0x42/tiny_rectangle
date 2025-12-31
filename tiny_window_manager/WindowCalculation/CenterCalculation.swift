//
//  CenterCalculation.swift
//  tiny_window_manager, Ported from Spectacle
//
//

import Foundation

/// Centers a window on the current screen.
/// If the window is larger than the screen, it will be resized to fit.
class CenterCalculation: WindowCalculation {

    override func calculate(_ params: WindowCalculationParameters) -> WindowCalculationResult? {
        print(#function, "called")
        let currentScreen = params.usableScreens.currentScreen

        // Determine the screen frame to use for centering
        // When "always account for stage" is disabled, we calculate a custom frame
        var screenFrame: CGRect? = nil
        let shouldUseCustomFrame = !Defaults.alwaysAccountForStage.userEnabled
        if shouldUseCustomFrame {
            screenFrame = currentScreen.adjustedVisibleFrame(params.ignoreTodo, true)
        }

        // Calculate where the centered window should be positioned
        let rectResult = calculateRect(params.asRectParams(visibleFrame: screenFrame))

        // Use the action from the result if available, otherwise keep the original action
        let resultingAction = rectResult.resultingAction ?? params.action

        return WindowCalculationResult(
            rect: rectResult.rect,
            screen: currentScreen,
            resultingAction: resultingAction,
            resultingScreenFrame: screenFrame
        )
    }

    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        print(#function, "called")
        let screenFrame = params.visibleFrameOfScreen
        let windowRect = params.window.rect

        // Check if the window is too big for the screen
        let windowIsTooTall = windowRect.height > screenFrame.height
        let windowIsTooWide = windowRect.width > screenFrame.width

        // If window exceeds screen in both dimensions, just maximize it
        if windowIsTooTall && windowIsTooWide {
            return RectResult(screenFrame, resultingAction: .maximize)
        }

        // Start with the current window size and position
        var centeredRect = windowRect

        // Handle vertical positioning
        if windowIsTooTall {
            // Window is taller than screen: resize to screen height and align to top
            centeredRect.size.height = screenFrame.height
            centeredRect.origin.y = screenFrame.minY
        } else {
            // Window fits: center it vertically
            let verticalSpace = screenFrame.height - windowRect.height
            let verticalOffset = round(verticalSpace / 2.0)
            centeredRect.origin.y = screenFrame.minY + verticalOffset
        }

        // Handle horizontal positioning
        if windowIsTooWide {
            // Window is wider than screen: resize to screen width and align to left
            centeredRect.size.width = screenFrame.width
            centeredRect.origin.x = screenFrame.minX
        } else {
            // Window fits: center it horizontally
            let horizontalSpace = screenFrame.width - windowRect.width
            let horizontalOffset = round(horizontalSpace / 2.0)
            centeredRect.origin.x = screenFrame.minX + horizontalOffset
        }

        return RectResult(centeredRect)
    }

}
