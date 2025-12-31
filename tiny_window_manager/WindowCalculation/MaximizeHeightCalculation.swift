//
//  MaximizeHeightCalculation.swift
//  tiny_window_manager
//
//  Stretches a window to fill the full screen HEIGHT while keeping its current width.
//  The window stays in its current horizontal position (x doesn't change).
//  Useful for making a window span from the menu bar to the dock.
//

import Foundation

/// Calculates window position for "maximize height" action.
/// Keeps the window's current width and x position, but stretches it vertically.
class MaximizeHeightCalculation: WindowCalculation {

    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        print(#function, "called")
        let screenFrame = params.visibleFrameOfScreen

        // Start with the window's current position and size
        var windowRect = params.window.rect

        // Stretch vertically to fill the screen height
        windowRect.origin.y = screenFrame.minY      // Move to bottom of usable screen
        windowRect.size.height = screenFrame.height  // Expand to full height

        // Note: origin.x and size.width are unchanged - window stays in same horizontal position

        return RectResult(windowRect)
    }
}
