//
//  BottomHalfCalculation.swift
//  tiny_window_manager, Ported from Spectacle
//
//

import Foundation

/// Positions a window to fill the bottom half of the screen.
/// When triggered repeatedly, cycles through 1/2 → 2/3 → 1/3 heights.
class BottomHalfCalculation: WindowCalculation, RepeatedExecutionsInThirdsCalculation {

    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        print(#function, "called")
        let isFirstExecution = params.lastAction == nil
        let shouldCycleSizes = Defaults.subsequentExecutionMode.resizes

        if isFirstExecution || !shouldCycleSizes {
            return calculateFirstRect(params)
        }

        return calculateRepeatedRect(params)
    }

    /// Creates a rect that spans the full width and a fraction of the height.
    /// The window is anchored to the bottom-left corner of the screen.
    func calculateFractionalRect(_ params: RectCalculationParameters, fraction: Float) -> RectResult {
        print(#function, "called")
        let screenFrame = params.visibleFrameOfScreen

        let width = screenFrame.width
        let height = floor(screenFrame.height * CGFloat(fraction))

        let rect = CGRect(
            x: screenFrame.origin.x,
            y: screenFrame.origin.y,
            width: width,
            height: height
        )

        return RectResult(rect)
    }
}
