//
//  HalvesCompoundCalculation.swift
//  tiny_window_manager
//
//  This file contains calculations for snap areas that divide the screen into halves.
//  There are four different "halves" behaviors:
//
//  1. LeftTopBottomHalfCalculation - Left edge with corner zones for top/bottom half
//  2. RightTopBottomHalfCalculation - Right edge with corner zones for top/bottom half
//  3. LeftRightHalvesCompoundCalculation - Simple left/right split from top or bottom edge
//  4. TopBottomHalvesCalculation - Top/bottom split for portrait monitors
//

import Foundation

// MARK: - Left Edge: Left Half with Top/Bottom Corners

/// Handles snapping on the LEFT edge of the screen.
///
/// Visual representation:
/// ┌─────────────────────────┐
/// │                         │
/// ├───┐                     │
/// │ T │  ← Top corner zone  │
/// │ O │    snaps to TOP     │
/// │ P │    HALF             │
/// ├───┤                     │
/// │   │                     │
/// │ L │  ← Middle zone      │
/// │ E │    snaps to LEFT    │
/// │ F │    HALF             │
/// │ T │                     │
/// │   │                     │
/// ├───┤                     │
/// │ B │  ← Bottom corner    │
/// │ O │    zone snaps to    │
/// │ T │    BOTTOM HALF      │
/// ├───┘                     │
/// │                         │
/// └─────────────────────────┘
///
struct LeftTopBottomHalfCalculation: CompoundSnapAreaCalculation {

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

        let screenFrame = screen.frame
        let cornerZoneSize = CGFloat(Defaults.shortEdgeSnapAreaSize.value)

        // Check if cursor is in the BOTTOM corner zone
        let bottomCornerThreshold = screenFrame.minY + marginBottom + cornerZoneSize
        let isInBottomCorner = loc.y <= bottomCornerThreshold

        if isInBottomCorner {
            let isBottomLeftEnabled = !ignoredSnapAreas.contains(.bottomLeftShort)
            if isBottomLeftEnabled {
                return SnapArea(screen: screen, directional: directional, action: .bottomHalf)
            }
        }

        // Check if cursor is in the TOP corner zone
        let topCornerThreshold = screenFrame.maxY - marginTop - cornerZoneSize
        let isInTopCorner = loc.y >= topCornerThreshold

        if isInTopCorner {
            let isTopLeftEnabled = !ignoredSnapAreas.contains(.topLeftShort)
            if isTopLeftEnabled {
                return SnapArea(screen: screen, directional: directional, action: .topHalf)
            }
        }

        // Default: snap to left half (middle of the edge)
        return SnapArea(screen: screen, directional: directional, action: .leftHalf)
    }
}

// MARK: - Right Edge: Right Half with Top/Bottom Corners

/// Handles snapping on the RIGHT edge of the screen.
/// Mirror image of LeftTopBottomHalfCalculation.
///
/// Visual representation:
/// ┌─────────────────────────┐
/// │                         │
/// │                     ┌───┤
/// │   Top corner zone → │ T │
/// │   snaps to TOP      │ O │
/// │   HALF              │ P │
/// │                     ├───┤
/// │                     │   │
/// │   Middle zone →     │ R │
/// │   snaps to RIGHT    │ I │
/// │   HALF              │ G │
/// │                     │ H │
/// │                     │ T │
/// │                     ├───┤
/// │   Bottom corner →   │ B │
/// │   zone snaps to     │ O │
/// │   BOTTOM HALF       │ T │
/// │                     └───┤
/// │                         │
/// └─────────────────────────┘
///
struct RightTopBottomHalfCalculation: CompoundSnapAreaCalculation {

    // MARK: - Configuration from User Defaults

    private let marginTop = Defaults.snapEdgeMarginTop.cgFloat
    private let marginBottom = Defaults.snapEdgeMarginBottom.cgFloat
    private let ignoredSnapAreas = SnapAreaOption(rawValue: Defaults.ignoredSnapAreas.value)

    // MARK: - Snap Area Calculation

    func snapArea(
        cursorLocation loc: NSPoint,
        screen: NSScreen,
        directional: Directional,
        priorSnapArea: SnapArea?
    ) -> SnapArea? {

        let screenFrame = screen.frame
        let cornerZoneSize = CGFloat(Defaults.shortEdgeSnapAreaSize.value)

        // Check if cursor is in the BOTTOM corner zone
        let bottomCornerThreshold = screenFrame.minY + marginBottom + cornerZoneSize
        let isInBottomCorner = loc.y <= bottomCornerThreshold

        if isInBottomCorner {
            let isBottomRightEnabled = !ignoredSnapAreas.contains(.bottomRightShort)
            if isBottomRightEnabled {
                return SnapArea(screen: screen, directional: directional, action: .bottomHalf)
            }
        }

        // Check if cursor is in the TOP corner zone
        let topCornerThreshold = screenFrame.maxY - marginTop - cornerZoneSize
        let isInTopCorner = loc.y >= topCornerThreshold

        if isInTopCorner {
            let isTopRightEnabled = !ignoredSnapAreas.contains(.topRightShort)
            if isTopRightEnabled {
                return SnapArea(screen: screen, directional: directional, action: .topHalf)
            }
        }

        // Default: snap to right half (middle of the edge)
        return SnapArea(screen: screen, directional: directional, action: .rightHalf)
    }
}

// MARK: - Top/Bottom Edge: Left or Right Half

/// Handles snapping on the TOP or BOTTOM edge of the screen.
/// Simply divides into left half or right half based on cursor X position.
///
/// Visual representation (dragging along top or bottom edge):
/// ┌────────────┬────────────┐
/// │            │            │
/// │   LEFT     │   RIGHT    │
/// │   HALF     │   HALF     │
/// │            │            │
/// │  ← cursor  │  cursor →  │
/// │    here    │    here    │
/// │            │            │
/// └────────────┴────────────┘
///
struct LeftRightHalvesCompoundCalculation: CompoundSnapAreaCalculation {

    func snapArea(
        cursorLocation loc: NSPoint,
        screen: NSScreen,
        directional: Directional,
        priorSnapArea: SnapArea?
    ) -> SnapArea? {

        let screenFrame = screen.frame
        let screenMidpointX = screenFrame.minX + (screenFrame.width / 2)

        // Simple left/right split based on cursor position
        let isOnLeftSide = loc.x < screenMidpointX

        if isOnLeftSide {
            return SnapArea(screen: screen, directional: directional, action: .leftHalf)
        } else {
            return SnapArea(screen: screen, directional: directional, action: .rightHalf)
        }
    }
}

// MARK: - Portrait Monitor: Top or Bottom Half

/// Handles snapping on the LEFT or RIGHT edge of a PORTRAIT monitor.
/// Divides into top half or bottom half based on cursor Y position,
/// with special corner zones that also trigger top/bottom half.
///
/// This is designed for portrait-oriented displays where the left/right
/// edges are taller than they are wide, making vertical splits more useful.
///
/// Visual representation:
/// ┌───────────┐
/// │  TOP HALF │ ← cursor in upper half
/// │           │
/// ├───────────┤
/// │           │
/// │  BOTTOM   │ ← cursor in lower half
/// │  HALF     │
/// └───────────┘
///
struct TopBottomHalvesCalculation: CompoundSnapAreaCalculation {

    // MARK: - Configuration from User Defaults

    private let marginTop = Defaults.snapEdgeMarginTop.cgFloat
    private let marginBottom = Defaults.snapEdgeMarginBottom.cgFloat
    private let ignoredSnapAreas = SnapAreaOption(rawValue: Defaults.ignoredSnapAreas.value)

    // MARK: - Snap Area Calculation

    func snapArea(
        cursorLocation loc: NSPoint,
        screen: NSScreen,
        directional: Directional,
        priorSnapArea: SnapArea?
    ) -> SnapArea? {

        let screenFrame = screen.frame
        let halfHeight = floor(screenFrame.height / 2)
        let cornerZoneSize = Defaults.shortEdgeSnapAreaSize.cgFloat

        // First, check corner zones (these take priority)
        if let cornerSnapArea = checkCornerZones(
            cursorLocation: loc,
            screen: screen,
            screenFrame: screenFrame,
            directional: directional,
            cornerZoneSize: cornerZoneSize
        ) {
            return cornerSnapArea
        }

        // Then check which half of the screen the cursor is in
        let screenMidpointY = screenFrame.minY + halfHeight
        let isInBottomHalf = loc.y >= screenFrame.minY && loc.y <= screenMidpointY
        let isInTopHalf = loc.y > screenMidpointY && loc.y <= screenFrame.maxY

        if isInBottomHalf {
            return SnapArea(screen: screen, directional: directional, action: .bottomHalf)
        }

        if isInTopHalf {
            return SnapArea(screen: screen, directional: directional, action: .topHalf)
        }

        // Cursor is outside screen bounds (shouldn't happen)
        return nil
    }

    // MARK: - Corner Zone Detection

    /// Checks if the cursor is in a corner zone and returns the appropriate snap area.
    /// Corner zones allow quick access to top/bottom half from the extreme edges.
    private func checkCornerZones(
        cursorLocation loc: NSPoint,
        screen: NSScreen,
        screenFrame: CGRect,
        directional: Directional,
        cornerZoneSize: CGFloat
    ) -> SnapArea? {

        // Check BOTTOM corner zone
        let bottomCornerThreshold = screenFrame.minY + marginBottom + cornerZoneSize
        let isInBottomCorner = loc.y <= bottomCornerThreshold

        if isInBottomCorner {
            // Determine if this is bottom-left or bottom-right based on X position
            let isLeftSide = loc.x < screenFrame.midX
            let snapAreaOption: SnapAreaOption = isLeftSide ? .bottomLeftShort : .bottomRightShort

            let isCornerEnabled = !ignoredSnapAreas.contains(snapAreaOption)
            if isCornerEnabled {
                return SnapArea(screen: screen, directional: directional, action: .bottomHalf)
            }
        }

        // Check TOP corner zone
        let topCornerThreshold = screenFrame.maxY - marginTop - cornerZoneSize
        let isInTopCorner = loc.y >= topCornerThreshold

        if isInTopCorner {
            // Determine if this is top-left or top-right based on X position
            let isLeftSide = loc.x < screenFrame.midX
            let snapAreaOption: SnapAreaOption = isLeftSide ? .topLeftShort : .topRightShort

            let isCornerEnabled = !ignoredSnapAreas.contains(snapAreaOption)
            if isCornerEnabled {
                return SnapArea(screen: screen, directional: directional, action: .topHalf)
            }
        }

        // Not in a corner zone
        return nil
    }
}
