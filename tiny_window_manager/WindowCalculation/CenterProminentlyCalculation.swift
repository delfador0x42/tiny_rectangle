//
//  CenterProminentlyCalculation.swift
//  tiny_window_manager
//
//

import Foundation

/// Centers a window horizontally, but positions it in the upper portion of the screen.
///
/// This creates a more "prominent" placement - the window sits higher than dead-center,
/// which is often more natural for focused work (similar to how dialog boxes appear).
///
/// The window is shifted up by 25% of the available vertical space above/below it.
class CenterProminentlyCalculation: WindowCalculation {

    override func calculate(_ params: WindowCalculationParameters) -> WindowCalculationResult? {
        print(#function, "called")
        let currentScreen = params.usableScreens.currentScreen

        // Determine the screen frame to use for positioning
        // When "always account for stage" is disabled, we calculate a custom frame
        var screenFrame: CGRect? = nil
        let shouldUseCustomFrame = !Defaults.alwaysAccountForStage.userEnabled
        if shouldUseCustomFrame {
            screenFrame = currentScreen.adjustedVisibleFrame(params.ignoreTodo, true)
        }

        // Calculate where the prominently-centered window should be positioned
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
        // Start with a normal centered window position
        let centeredResult = WindowCalculationFactory.centerCalculation.calculateRect(params)
        var rect = centeredResult.rect

        // Calculate how much to shift the window upward
        // We want to move it up by 25% of the empty vertical space
        let screenHeight = params.visibleFrameOfScreen.height
        let windowHeight = rect.height
        let emptyVerticalSpace = screenHeight - windowHeight
        let upwardShift = emptyVerticalSpace * 0.25

        // Move the window up (in macOS, increasing Y moves up)
        rect.origin.y += upwardShift

        return RectResult(rect, resultingAction: centeredResult.resultingAction)
    }

}
