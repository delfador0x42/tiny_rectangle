//
//  FourthsCompoundCalculation.swift
//  tiny_window_manager
//
//  Handles snap areas that divide the screen into 4 equal columns (quarters).
//
//  Screen layout:
//  ┌─────────┬─────────┬─────────┬─────────┐
//  │  1st    │  2nd    │  3rd    │  4th    │
//  │ Fourth  │ Fourth  │ Fourth  │ Fourth  │
//  │  (25%)  │  (25%)  │  (25%)  │  (25%)  │
//  └─────────┴─────────┴─────────┴─────────┘
//
//  Special "expansion" behavior:
//  When dragging from one column into an adjacent middle column, the window
//  can expand to span multiple columns. For example:
//  - Drag from 1st column → 2nd column = expands to "first three fourths" (75%)
//  - Drag from 4th column → 3rd column = expands to "last three fourths" (75%)
//  - Drag between 2nd and 3rd columns = "center half" (50%)
//

import Foundation

// MARK: - Fourths Column Calculation

struct FourthsColumnCompoundCalculation: CompoundSnapAreaCalculation {

    func snapArea(
        cursorLocation loc: NSPoint,
        screen: NSScreen,
        directional: Directional,
        priorSnapArea: SnapArea?
    ) -> SnapArea? {

        let screenFrame = screen.frame
        let columnWidth = floor(screenFrame.width / 4)

        // Calculate the X boundaries for each column
        let column1End = screenFrame.minX + columnWidth
        let column2End = screenFrame.minX + columnWidth * 2
        let column3End = screenFrame.minX + columnWidth * 3

        // Determine which column the cursor is in and return the appropriate snap area
        let column = determineColumn(cursorX: loc.x, screenFrame: screenFrame, columnWidth: columnWidth)

        switch column {
        case .first:
            return createSnapArea(screen: screen, directional: directional, action: .firstFourth)

        case .second:
            return handleMiddleColumn(
                screen: screen,
                directional: directional,
                priorSnapArea: priorSnapArea,
                defaultAction: .secondFourth,
                expandLeftActions: [.firstFourth, .firstThreeFourths],
                expandLeftResult: .firstThreeFourths,
                expandRightActions: [.thirdFourth, .lastThreeFourths, .centerHalf],
                expandRightResult: .centerHalf
            )

        case .third:
            return handleMiddleColumn(
                screen: screen,
                directional: directional,
                priorSnapArea: priorSnapArea,
                defaultAction: .thirdFourth,
                expandLeftActions: [.secondFourth, .firstThreeFourths, .centerHalf],
                expandLeftResult: .centerHalf,
                expandRightActions: [.lastFourth, .lastThreeFourths],
                expandRightResult: .lastThreeFourths
            )

        case .fourth:
            return createSnapArea(screen: screen, directional: directional, action: .lastFourth)

        case .none:
            return nil
        }
    }

    // MARK: - Column Detection

    /// Represents which quarter of the screen the cursor is in
    private enum Column {
        case first   // Leftmost 25%
        case second  // 25-50%
        case third   // 50-75%
        case fourth  // Rightmost 25%
        case none    // Outside screen bounds (shouldn't happen)
    }

    /// Determines which column (quarter) the cursor is currently in
    private func determineColumn(cursorX: CGFloat, screenFrame: CGRect, columnWidth: CGFloat) -> Column {
        let column1End = screenFrame.minX + columnWidth
        let column2End = screenFrame.minX + columnWidth * 2
        let column3End = screenFrame.minX + columnWidth * 3

        if cursorX <= column1End {
            return .first
        } else if cursorX <= column2End {
            return .second
        } else if cursorX <= column3End {
            return .third
        } else if cursorX <= screenFrame.maxX {
            return .fourth
        } else {
            return .none
        }
    }

    // MARK: - Snap Area Creation

    /// Simple helper to create a snap area with the given action
    private func createSnapArea(screen: NSScreen, directional: Directional, action: WindowAction) -> SnapArea {
        return SnapArea(screen: screen, directional: directional, action: action)
    }

    // MARK: - Middle Column Expansion Logic

    /// Handles the "expansion" behavior for the middle columns (2nd and 3rd).
    ///
    /// When the user drags from an outer column into a middle column, instead of
    /// snapping to just that quarter, we can expand to a larger area. This creates
    /// a more fluid drag experience.
    ///
    /// - Parameters:
    ///   - screen: The screen being snapped to
    ///   - directional: Which edge triggered this snap
    ///   - priorSnapArea: What the window was previously snapped to (if any)
    ///   - defaultAction: What to snap to if there's no expansion (just the single column)
    ///   - expandLeftActions: Prior actions that trigger expansion toward the left
    ///   - expandLeftResult: The expanded action when coming from the left
    ///   - expandRightActions: Prior actions that trigger expansion toward the right
    ///   - expandRightResult: The expanded action when coming from the right
    ///
    /// - Returns: The appropriate snap area based on context
    private func handleMiddleColumn(
        screen: NSScreen,
        directional: Directional,
        priorSnapArea: SnapArea?,
        defaultAction: WindowAction,
        expandLeftActions: [WindowAction],
        expandLeftResult: WindowAction,
        expandRightActions: [WindowAction],
        expandRightResult: WindowAction
    ) -> SnapArea {

        // Check if we should expand based on where the user is dragging from
        if let priorAction = priorSnapArea?.action {

            // Coming from the left side? Expand leftward
            if expandLeftActions.contains(priorAction) {
                return createSnapArea(screen: screen, directional: directional, action: expandLeftResult)
            }

            // Coming from the right side? Expand rightward
            if expandRightActions.contains(priorAction) {
                return createSnapArea(screen: screen, directional: directional, action: expandRightResult)
            }
        }

        // No expansion context - just snap to this single column
        return createSnapArea(screen: screen, directional: directional, action: defaultAction)
    }
}
