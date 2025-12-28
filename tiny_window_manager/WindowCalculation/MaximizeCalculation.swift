//
//  MaximizeCalculation.swift
//  tiny_window_manager, Ported from Spectacle
//
//

import Foundation

class MaximizeCalculation: WindowCalculation {

    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        let visibleFrameOfScreen = params.visibleFrameOfScreen

        return RectResult(visibleFrameOfScreen)
    }
    
}
