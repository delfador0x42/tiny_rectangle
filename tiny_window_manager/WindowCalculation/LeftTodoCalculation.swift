//
//  LeftTodoCalculation.swift
//  tiny_window_manager
//
//  Positions a window as a narrow sidebar on the LEFT side of the screen.
//  Used for "todo" or notes apps that sit alongside your main work.
//

import Foundation

/// Calculates window position for a left-side "todo" sidebar.
/// The sidebar width is determined by TodoManager based on screen size.
final class LeftTodoCalculation: WindowCalculation {

    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        let screenFrame = params.visibleFrameOfScreen

        // Get the appropriate sidebar width for this screen size
        let sidebarWidth = TodoManager.getSidebarWidth(visibleFrameWidth: screenFrame.width)

        // Create a rectangle that spans the full height but only the sidebar width
        var windowRect = screenFrame
        windowRect.size.width = sidebarWidth
        // Note: origin.x stays at screenFrame.minX (left edge) by default

        return RectResult(windowRect, subAction: .leftTodo)
    }
}
