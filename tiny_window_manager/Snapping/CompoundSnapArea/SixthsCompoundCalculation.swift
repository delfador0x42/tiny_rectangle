//
//  SixthsCompoundCalculation.swift
//  tiny_window_manager
//
//  Handles snap areas that divide the screen into sixths (a 3x2 grid).
//
//  Screen layout showing all six regions:
//  ┌───────────┬───────────┬───────────┐
//  │  Top-Left │ Top-Center│ Top-Right │
//  │   Sixth   │   Sixth   │   Sixth   │
//  ├───────────┼───────────┼───────────┤
//  │Bottom-Left│Bottom-Ctr │Bottom-Right
//  │   Sixth   │   Sixth   │   Sixth   │
//  └───────────┴───────────┴───────────┘
//
//  IMPORTANT: Sixths are "secondary" snap areas - they only activate when
//  the user is ALREADY in a related snap position (like a corner or another sixth).
//  This prevents accidental tiny windows and makes the UX more intentional.
//
//  - Top edge: Defaults to MAXIMIZE, only shows sixths when coming from corners/sixths
//  - Bottom edge: Defaults to THIRDS, only shows sixths when coming from corners/sixths
//

import Foundation

// MARK: - Top Edge: Sixths or Maximize

/// Handles snapping on the TOP edge of the screen.
///
/// Behavior:
/// - Default (no prior snap): Maximize the window
/// - Coming from top-left corner or top sixths → Top-left sixth
/// - Coming from top-right corner or top sixths → Top-right sixth
/// - Coming from any sixth → Top-center sixth
///
/// Visual representation:
/// ┌───────────┬───────────┬───────────┐
/// │  Top-Left │Top-Center │ Top-Right │  ← Only shown when coming
/// │   Sixth   │  Sixth    │   Sixth   │    from corners or sixths
/// ├───────────┴───────────┴───────────┤
/// │                                   │
/// │           MAXIMIZE                │  ← Default action
/// │         (full screen)             │
/// │                                   │
/// └───────────────────────────────────┘
///
struct TopSixthsCompoundCalculation: CompoundSnapAreaCalculation {

    func snapArea(
        cursorLocation loc: NSPoint,
        screen: NSScreen,
        directional: Directional,
        priorSnapArea: SnapArea?
    ) -> SnapArea? {
        print(#function, "called")

        // If there's no prior snap area, default to maximize
        guard let priorAction = priorSnapArea?.action else {
            return createSnapArea(screen: screen, directional: directional, action: .maximize)
        }

        let screenFrame = screen.frame
        let thirdWidth = floor(screenFrame.width / 3)

        // Determine which horizontal third the cursor is in
        let cursorRegion = determineHorizontalRegion(
            cursorX: loc.x,
            screenFrame: screenFrame,
            thirdWidth: thirdWidth
        )

        // Check if we should show a sixth based on cursor position and prior action
        switch cursorRegion {
        case .left:
            if shouldShowTopLeftSixth(priorAction: priorAction) {
                return createSnapArea(screen: screen, directional: directional, action: .topLeftSixth)
            }

        case .right:
            if shouldShowTopRightSixth(priorAction: priorAction) {
                return createSnapArea(screen: screen, directional: directional, action: .topRightSixth)
            }

        case .center:
            break // Center region handling falls through to below
        }

        // If coming from any top sixth, show the center sixth
        if isComingFromTopSixth(priorAction: priorAction) {
            return createSnapArea(screen: screen, directional: directional, action: .topCenterSixth)
        }

        // Default: maximize
        return createSnapArea(screen: screen, directional: directional, action: .maximize)
    }

    // MARK: - Helpers

    /// Checks if the prior action qualifies for showing the top-left sixth
    private func shouldShowTopLeftSixth(priorAction: WindowAction) -> Bool {
        print(#function, "called")
        let qualifyingActions: [WindowAction] = [
            .topLeft,           // Coming from top-left corner
            .topLeftSixth,      // Already in top-left sixth
            .topCenterSixth     // Coming from adjacent sixth
        ]
        return qualifyingActions.contains(priorAction)
    }

    /// Checks if the prior action qualifies for showing the top-right sixth
    private func shouldShowTopRightSixth(priorAction: WindowAction) -> Bool {
        print(#function, "called")
        let qualifyingActions: [WindowAction] = [
            .topRight,          // Coming from top-right corner
            .topRightSixth,     // Already in top-right sixth
            .topCenterSixth     // Coming from adjacent sixth
        ]
        return qualifyingActions.contains(priorAction)
    }

    /// Checks if the user is coming from any top sixth position
    private func isComingFromTopSixth(priorAction: WindowAction) -> Bool {
        print(#function, "called")
        let topSixthActions: [WindowAction] = [
            .topLeftSixth,
            .topRightSixth,
            .topCenterSixth
        ]
        return topSixthActions.contains(priorAction)
    }

    private func createSnapArea(screen: NSScreen, directional: Directional, action: WindowAction) -> SnapArea {
        print(#function, "called")
        return SnapArea(screen: screen, directional: directional, action: action)
    }
}

// MARK: - Bottom Edge: Sixths or Thirds

/// Handles snapping on the BOTTOM edge of the screen.
///
/// Behavior:
/// - Default (no prior snap): Delegates to thirds calculation (left/center/right third)
/// - Coming from bottom-left corner or bottom sixths → Bottom-left sixth
/// - Coming from bottom-right corner or bottom sixths → Bottom-right sixth
/// - Coming from any bottom sixth → Bottom-center sixth
///
/// Visual representation:
/// ┌───────────────────────────────────┐
/// │                                   │
/// │           THIRDS                  │  ← Default action
/// │    (left / center / right)        │    (delegates to ThirdsCompoundCalculation)
/// │                                   │
/// ├───────────┬───────────┬───────────┤
/// │Bottom-Left│Bottom-Ctr │Bottom-Right  ← Only shown when coming
/// │   Sixth   │  Sixth    │   Sixth   │    from corners or sixths
/// └───────────┴───────────┴───────────┘
///
struct BottomSixthsCompoundCalculation: CompoundSnapAreaCalculation {

    func snapArea(
        cursorLocation loc: NSPoint,
        screen: NSScreen,
        directional: Directional,
        priorSnapArea: SnapArea?
    ) -> SnapArea? {
        print(#function, "called")

        // If there's no prior snap area, fall back to thirds behavior
        guard let priorAction = priorSnapArea?.action else {
            return fallbackToThirds(loc: loc, screen: screen, directional: directional, priorSnapArea: priorSnapArea)
        }

        let screenFrame = screen.frame
        let thirdWidth = floor(screenFrame.width / 3)

        // Determine which horizontal third the cursor is in
        let cursorRegion = determineHorizontalRegion(
            cursorX: loc.x,
            screenFrame: screenFrame,
            thirdWidth: thirdWidth
        )

        // Check if we should show a sixth based on cursor position and prior action
        switch cursorRegion {
        case .left:
            if shouldShowBottomLeftSixth(priorAction: priorAction) {
                return createSnapArea(screen: screen, directional: directional, action: .bottomLeftSixth)
            }

        case .center:
            if shouldShowBottomCenterSixth(priorAction: priorAction) {
                return createSnapArea(screen: screen, directional: directional, action: .bottomCenterSixth)
            }

        case .right:
            if shouldShowBottomRightSixth(priorAction: priorAction) {
                return createSnapArea(screen: screen, directional: directional, action: .bottomRightSixth)
            }
        }

        // Default: fall back to thirds behavior
        return fallbackToThirds(loc: loc, screen: screen, directional: directional, priorSnapArea: priorSnapArea)
    }

    // MARK: - Helpers

    /// Checks if the prior action qualifies for showing the bottom-left sixth
    private func shouldShowBottomLeftSixth(priorAction: WindowAction) -> Bool {
        print(#function, "called")
        let qualifyingActions: [WindowAction] = [
            .bottomLeft,         // Coming from bottom-left corner
            .bottomLeftSixth,    // Already in bottom-left sixth
            .bottomCenterSixth   // Coming from adjacent sixth
        ]
        return qualifyingActions.contains(priorAction)
    }

    /// Checks if the prior action qualifies for showing the bottom-center sixth
    private func shouldShowBottomCenterSixth(priorAction: WindowAction) -> Bool {
        print(#function, "called")
        let qualifyingActions: [WindowAction] = [
            .bottomRightSixth,   // Coming from adjacent sixth
            .bottomLeftSixth,    // Coming from adjacent sixth
            .bottomCenterSixth   // Already in bottom-center sixth
        ]
        return qualifyingActions.contains(priorAction)
    }

    /// Checks if the prior action qualifies for showing the bottom-right sixth
    private func shouldShowBottomRightSixth(priorAction: WindowAction) -> Bool {
        print(#function, "called")
        let qualifyingActions: [WindowAction] = [
            .bottomRight,        // Coming from bottom-right corner
            .bottomRightSixth,   // Already in bottom-right sixth
            .bottomCenterSixth   // Coming from adjacent sixth
        ]
        return qualifyingActions.contains(priorAction)
    }

    /// Delegates to the thirds calculation when sixths don't apply
    private func fallbackToThirds(
        loc: NSPoint,
        screen: NSScreen,
        directional: Directional,
        priorSnapArea: SnapArea?
    ) -> SnapArea? {
        print(#function, "called")
        return CompoundSnapArea.thirdsCompoundCalculation.snapArea(
            cursorLocation: loc,
            screen: screen,
            directional: directional,
            priorSnapArea: priorSnapArea
        )
    }

    private func createSnapArea(screen: NSScreen, directional: Directional, action: WindowAction) -> SnapArea {
        print(#function, "called")
        return SnapArea(screen: screen, directional: directional, action: action)
    }
}

// MARK: - Shared Helper

/// Represents which horizontal third of the screen the cursor is in
private enum HorizontalRegion {
    case left    // Leftmost third
    case center  // Middle third
    case right   // Rightmost third
}

/// Determines which horizontal third of the screen the cursor is in.
/// Used by both top and bottom sixths calculations.
private func determineHorizontalRegion(
    cursorX: CGFloat,
    screenFrame: CGRect,
    thirdWidth: CGFloat
) -> HorizontalRegion {
    print(#function, "called")

    let leftThirdEnd = screenFrame.minX + thirdWidth
    let rightThirdStart = screenFrame.maxX - thirdWidth

    if cursorX <= leftThirdEnd {
        return .left
    } else if cursorX >= rightThirdStart {
        return .right
    } else {
        return .center
    }
}
