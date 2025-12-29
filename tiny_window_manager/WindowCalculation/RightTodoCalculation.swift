//
//  RightTodoCalculation.swift
//  tiny_window_manager
//
//

import Foundation

/// Positions a window as a "todo sidebar" on the right edge of the screen.
///
/// This creates a vertical strip along the right side of the screen, useful for
/// todo apps, notes, or any window you want docked to the right edge.
///
/// The sidebar width is determined by `TodoManager.getSidebarWidth()`, which
/// calculates an appropriate width based on the screen size.
///
/// ## Visual Example
/// ```
/// ┌─────────────────────────┬───────┐
/// │                         │       │
/// │     Main workspace      │ Todo  │
/// │                         │ side- │
/// │                         │ bar   │
/// │                         │       │
/// └─────────────────────────┴───────┘
/// ```
final class RightTodoCalculation: WindowCalculation {

    /// Calculates a rectangle for a right-side todo sidebar.
    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        let visibleFrameOfScreen = params.visibleFrameOfScreen

        // Start with the full screen dimensions (we'll adjust width and x-position)
        var calculatedWindowRect = visibleFrameOfScreen

        // Get the appropriate sidebar width for this screen size
        let sidebarWidth = TodoManager.getSidebarWidth(visibleFrameWidth: visibleFrameOfScreen.width)

        // Position the window at the right edge of the screen
        let rightEdgeX = visibleFrameOfScreen.maxX - sidebarWidth
        calculatedWindowRect.origin.x = rightEdgeX
        calculatedWindowRect.size.width = sidebarWidth

        return RectResult(calculatedWindowRect, subAction: .rightTodo)
    }
}
