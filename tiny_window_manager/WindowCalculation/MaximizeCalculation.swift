//
//  MaximizeCalculation.swift
//  tiny_window_manager
//
//  Maximizes a window to fill the entire usable screen area.
//  "Usable" means excluding the menu bar and dock.
//

import Foundation

/// Calculates window position for maximizing (filling the screen).
/// This is the simplest calculation - just use the full visible screen area.
class MaximizeCalculation: WindowCalculation {

    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        // The visible frame already excludes the menu bar and dock
        let fullScreenRect = params.visibleFrameOfScreen

        // Return the full screen - no modifications needed
        return RectResult(fullScreenRect)
    }
}
