//
//  BottomHalfCalculation.swift
//  tiny_window_manager, Ported from Spectacle
//
//

import Foundation

class BottomHalfCalculation: WindowCalculation, RepeatedExecutionsInThirdsCalculation {

    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {

        if params.lastAction == nil || !Defaults.subsequentExecutionMode.resizes {
            return calculateFirstRect(params)
        }
        
        return calculateRepeatedRect(params)
    }
    
    func calculateFractionalRect(_ params: RectCalculationParameters, fraction: Float) -> RectResult {
        let visibleFrameOfScreen = params.visibleFrameOfScreen

        var rect = visibleFrameOfScreen
        rect.size.height = floor(visibleFrameOfScreen.height * CGFloat(fraction))
        return RectResult(rect)
    }
    
}
