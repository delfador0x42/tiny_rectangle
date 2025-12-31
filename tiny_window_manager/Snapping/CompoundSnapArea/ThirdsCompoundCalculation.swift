//
//  ThirdsCompoundCalculation.swift
//  tiny_window_manager
//
//  Handles snap areas that divide the screen into thirds.
//
//  There are two variants:
//  1. ThirdsCompoundCalculation - Horizontal thirds for LANDSCAPE monitors
//  2. PortraitSideThirdsCompoundCalculation - Vertical thirds for PORTRAIT monitors
//
//  Key feature - "Expansion" behavior:
//  When dragging from an outer third into the center, the window EXPANDS to
//  cover two-thirds instead of just the center third. This creates a smooth
//  drag experience for getting 2/3 width windows.
//
//  Example: Drag left → center = "first two thirds" (66%)
//           Drag right → center = "last two thirds" (66%)
//           Direct to center = "center third" (33%)
//

import Foundation

// MARK: - Landscape: Horizontal Thirds

/// Handles snapping on the TOP or BOTTOM edge of a LANDSCAPE monitor.
/// Divides the screen into three horizontal columns.
///
/// Visual representation:
/// ┌───────────┬───────────┬───────────┐
/// │   First   │  Center   │   Last    │
/// │   Third   │  Third    │   Third   │
/// │   (33%)   │  (33%)    │   (33%)   │
/// └───────────┴───────────┴───────────┘
///
/// Expansion behavior in center:
/// ┌─────────────────────┬───────────┐
/// │   First Two Thirds  │   Last    │  ← When dragging from left → center
/// │        (66%)        │   Third   │
/// └─────────────────────┴───────────┘
///
/// ┌───────────┬─────────────────────┐
/// │   First   │   Last Two Thirds   │  ← When dragging from right → center
/// │   Third   │        (66%)        │
/// └───────────┴─────────────────────┘
///
struct ThirdsCompoundCalculation: CompoundSnapAreaCalculation {

    func snapArea(
        cursorLocation loc: NSPoint,
        screen: NSScreen,
        directional: Directional,
        priorSnapArea: SnapArea?
    ) -> SnapArea? {
        print(#function, "called")

        let screenFrame = screen.frame
        let thirdWidth = floor(screenFrame.width / 3)

        // Determine which horizontal third the cursor is in
        let region = determineHorizontalThird(
            cursorX: loc.x,
            screenFrame: screenFrame,
            thirdWidth: thirdWidth
        )

        switch region {
        case .first:
            // Left third - always snap to first third
            return createSnapArea(screen: screen, directional: directional, action: .firstThird)

        case .center:
            // Center third - may expand based on where user is coming from
            let action = determineCenterAction(priorAction: priorSnapArea?.action)
            return createSnapArea(screen: screen, directional: directional, action: action)

        case .last:
            // Right third - always snap to last third
            return createSnapArea(screen: screen, directional: directional, action: .lastThird)

        case .none:
            return nil
        }
    }

    // MARK: - Helpers

    private func createSnapArea(screen: NSScreen, directional: Directional, action: WindowAction) -> SnapArea {
        print(#function, "called")
        return SnapArea(screen: screen, directional: directional, action: action)
    }
}

// MARK: - Portrait: Vertical Thirds with Corner Zones

/// Handles snapping on the LEFT or RIGHT edge of a PORTRAIT monitor.
/// Divides the screen into three vertical rows, plus corner zones for top/bottom half.
///
/// Visual representation:
/// ┌───────────────────┐
/// │ Top corner zone   │ ← Snaps to TOP HALF (if enabled)
/// ├───────────────────┤
/// │    First Third    │ ← Top row (33%)
/// │      (top)        │
/// ├───────────────────┤
/// │   Center Third    │ ← Middle row (33%)
/// │    (middle)       │   Expands like landscape version
/// ├───────────────────┤
/// │    Last Third     │ ← Bottom row (33%)
/// │    (bottom)       │
/// ├───────────────────┤
/// │ Bottom corner zone│ ← Snaps to BOTTOM HALF (if enabled)
/// └───────────────────┘
///
/// Note: "First" third is at the TOP, "Last" third is at the BOTTOM.
/// This matches the visual order when reading top-to-bottom.
///
struct PortraitSideThirdsCompoundCalculation: CompoundSnapAreaCalculation {

    // MARK: - Configuration from User Defaults

    /// Space reserved at the top of the screen (e.g., for menu bar)
    private let marginTop = Defaults.snapEdgeMarginTop.cgFloat

    /// Space reserved at the bottom of the screen (e.g., for dock)
    private let marginBottom = Defaults.snapEdgeMarginBottom.cgFloat

    /// Snap areas the user has chosen to disable
    private let ignoredSnapAreas = SnapAreaOption(rawValue: Defaults.ignoredSnapAreas.value)

    // MARK: - Snap Area Calculation

    func snapArea(
        cursorLocation loc: NSPoint,
        screen: NSScreen,
        directional: Directional,
        priorSnapArea: SnapArea?
    ) -> SnapArea? {
        print(#function, "called")

        let screenFrame = screen.frame
        let thirdHeight = floor(screenFrame.height / 3)
        let cornerZoneSize = Defaults.shortEdgeSnapAreaSize.cgFloat

        // First, check corner zones (these take priority over thirds)
        if let cornerSnapArea = checkCornerZones(
            cursorLocation: loc,
            screen: screen,
            screenFrame: screenFrame,
            directional: directional,
            cornerZoneSize: cornerZoneSize
        ) {
            return cornerSnapArea
        }

        // Determine which vertical third the cursor is in
        let region = determineVerticalThird(
            cursorY: loc.y,
            screenFrame: screenFrame,
            thirdHeight: thirdHeight
        )

        switch region {
        case .first:
            // Top third (remember: Y increases upward in macOS coordinates)
            return createSnapArea(screen: screen, directional: directional, action: .firstThird)

        case .center:
            // Center third - may expand based on where user is coming from
            let action = determineCenterAction(priorAction: priorSnapArea?.action)
            return createSnapArea(screen: screen, directional: directional, action: action)

        case .last:
            // Bottom third
            return createSnapArea(screen: screen, directional: directional, action: .lastThird)

        case .none:
            return nil
        }
    }

    // MARK: - Corner Zone Detection

    /// Checks if the cursor is in a corner zone and returns the appropriate snap area.
    /// Corner zones provide quick access to top/bottom half from the extreme edges.
    private func checkCornerZones(
        cursorLocation loc: NSPoint,
        screen: NSScreen,
        screenFrame: CGRect,
        directional: Directional,
        cornerZoneSize: CGFloat
    ) -> SnapArea? {
        print(#function, "called")

        // Check BOTTOM corner zone
        let bottomCornerThreshold = screenFrame.minY + marginBottom + cornerZoneSize
        let isInBottomCorner = loc.y <= bottomCornerThreshold

        if isInBottomCorner {
            // Determine which side (left or right) based on X position
            let isLeftSide = loc.x < screenFrame.midX
            let snapAreaOption: SnapAreaOption = isLeftSide ? .bottomLeftShort : .bottomRightShort

            let isCornerEnabled = !ignoredSnapAreas.contains(snapAreaOption)
            if isCornerEnabled {
                return createSnapArea(screen: screen, directional: directional, action: .bottomHalf)
            }
        }

        // Check TOP corner zone
        let topCornerThreshold = screenFrame.maxY - marginTop - cornerZoneSize
        let isInTopCorner = loc.y >= topCornerThreshold

        if isInTopCorner {
            // Determine which side (left or right) based on X position
            let isLeftSide = loc.x < screenFrame.midX
            let snapAreaOption: SnapAreaOption = isLeftSide ? .topLeftShort : .topRightShort

            let isCornerEnabled = !ignoredSnapAreas.contains(snapAreaOption)
            if isCornerEnabled {
                return createSnapArea(screen: screen, directional: directional, action: .topHalf)
            }
        }

        // Not in a corner zone
        return nil
    }

    // MARK: - Vertical Third Detection

    /// Determines which vertical third of the screen the cursor is in.
    /// Note: In macOS, Y=0 is at the BOTTOM, so we check from bottom to top.
    private func determineVerticalThird(
        cursorY: CGFloat,
        screenFrame: CGRect,
        thirdHeight: CGFloat
    ) -> ThirdRegion {
        print(#function, "called")

        let bottomThirdEnd = screenFrame.minY + thirdHeight
        let topThirdStart = screenFrame.maxY - thirdHeight

        // Bottom third (low Y values) = "last" third
        if cursorY >= screenFrame.minY && cursorY <= bottomThirdEnd {
            return .last
        }

        // Middle third
        if cursorY > bottomThirdEnd && cursorY < topThirdStart {
            return .center
        }

        // Top third (high Y values) = "first" third
        if cursorY >= topThirdStart && cursorY <= screenFrame.maxY {
            return .first
        }

        return .none
    }

    // MARK: - Helpers

    private func createSnapArea(screen: NSScreen, directional: Directional, action: WindowAction) -> SnapArea {
        print(#function, "called")
        return SnapArea(screen: screen, directional: directional, action: action)
    }
}

// MARK: - Shared Types and Functions

/// Represents which third of the screen the cursor is in
private enum ThirdRegion {
    case first   // Left third (landscape) or Top third (portrait)
    case center  // Middle third
    case last    // Right third (landscape) or Bottom third (portrait)
    case none    // Outside screen bounds
}

/// Determines which horizontal third (left/center/right) the cursor is in.
/// Used by landscape thirds calculation.
private func determineHorizontalThird(
    cursorX: CGFloat,
    screenFrame: CGRect,
    thirdWidth: CGFloat
) -> ThirdRegion {
    print(#function, "called")

    let leftThirdEnd = screenFrame.minX + thirdWidth
    let rightThirdStart = screenFrame.maxX - thirdWidth

    if cursorX <= leftThirdEnd {
        return .first
    } else if cursorX >= rightThirdStart {
        return .last
    } else if cursorX > leftThirdEnd && cursorX < rightThirdStart {
        return .center
    }

    return .none
}

/// Determines what action to use when the cursor is in the CENTER third.
/// Implements the "expansion" behavior: if coming from an outer third, expand to two-thirds.
///
/// - Parameter priorAction: The window action from the previous snap position
/// - Returns: The appropriate center action (.centerThird, .firstTwoThirds, or .lastTwoThirds)
private func determineCenterAction(priorAction: WindowAction?) -> WindowAction {
    print(#function, "called")
    guard let priorAction = priorAction else {
        // No prior action - just use center third
        return .centerThird
    }

    switch priorAction {
    case .firstThird, .firstTwoThirds:
        // Coming from the left/top - expand to first two thirds (66%)
        return .firstTwoThirds

    case .lastThird, .lastTwoThirds:
        // Coming from the right/bottom - expand to last two thirds (66%)
        return .lastTwoThirds

    default:
        // Coming from somewhere else - just use center third
        return .centerThird
    }
}
