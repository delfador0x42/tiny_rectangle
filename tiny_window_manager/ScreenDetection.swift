//
//  ScreenDetection.swift
//  tiny_window_manager
//
//  This file handles multi-monitor support - detecting screens, finding which
//  screen a window is on, and determining adjacent screens for navigation.
//
//  WHY THIS IS NEEDED:
//  -------------------
//  Window management gets complicated with multiple monitors:
//  - Which screen should a window snap to?
//  - When user presses "next display", which screen is "next"?
//  - If a window spans two screens, which one "owns" it?
//
//  This file answers these questions.
//
//  KEY CONCEPTS:
//  -------------
//  1. SCREEN DETECTION: Figure out which screen a window is currently on
//     - A window might span multiple screens
//     - We pick the screen that contains the most of the window
//
//  2. SCREEN ORDERING: Determine the order of screens for navigation
//     - By default: top-to-bottom, then left-to-right
//     - Optional: pure left-to-right ordering
//
//  3. ADJACENT SCREENS: Find "previous" and "next" screens for navigation
//     - Wraps around (last screen's "next" is first screen)
//     - With 2 screens, both prev and next are the other screen
//
//  4. VISIBLE FRAME: The usable area of a screen after accounting for:
//     - Menu bar and Dock (handled by macOS)
//     - Stage Manager strip (macOS Ventura+)
//     - Todo sidebar (this app's feature)
//     - User-configured screen edge gaps
//
//  COORDINATE SYSTEM NOTE:
//  -----------------------
//  macOS has two coordinate systems:
//  - AppKit (NSScreen): Origin at BOTTOM-left, Y increases upward
//  - Core Graphics (CGRect): Origin at TOP-left, Y increases downward
//
//  This file primarily uses AppKit coordinates (NSScreen.frame) but converts
//  to Core Graphics when needed (using .screenFlipped).
//

import Cocoa

// MARK: - Screen Detection Class

/// Handles detection and navigation of multiple screens/monitors.
///
/// This class is used by WindowManager to determine:
/// - Which screen a window is on
/// - Which screens are adjacent for "next/previous display" actions
/// - The proper order of screens for navigation
class ScreenDetection {

    // MARK: - Main Detection Methods

    /// Detects available screens and determines which one contains the given window.
    ///
    /// This is the primary method called when executing a window action.
    /// It figures out which screen the window is on and which screens are
    /// adjacent for "move to next/previous display" commands.
    ///
    /// - Parameter frontmostWindowElement: The window to find a screen for.
    /// - Returns: UsableScreens containing the current screen, adjacent screens, and screen order.
    func detectScreens(using frontmostWindowElement: AccessibilityElement?) -> UsableScreens? {
        let screens = NSScreen.screens

        // Need at least one screen
        guard let firstScreen = screens.first else { return nil }

        // SINGLE SCREEN CASE
        // With only one screen, "next" and "prev" can either loop back to the same
        // screen (if user enabled that) or be nil (no screen navigation possible)
        if screens.count == 1 {
            let adjacentScreens = Defaults.traverseSingleScreen.enabled == true
                ? AdjacentScreens(prev: firstScreen, next: firstScreen)
                : nil

            return UsableScreens(
                currentScreen: firstScreen,
                adjacentScreens: adjacentScreens,
                numScreens: screens.count,
                screensOrdered: [firstScreen]
            )
        }

        // MULTI-SCREEN CASE
        // Order the screens first (affects which is "next" vs "previous")
        let screensOrdered = order(screens: screens)

        // Find which screen contains the window
        let windowFrame = frontmostWindowElement?.frame ?? CGRect.zero
        guard let sourceScreen = screenContaining(windowFrame, screens: screensOrdered) else {
            // Fallback: use first screen if we can't determine window's screen
            let adjacentScreens = AdjacentScreens(prev: firstScreen, next: firstScreen)
            return UsableScreens(
                currentScreen: firstScreen,
                adjacentScreens: adjacentScreens,
                numScreens: screens.count,
                screensOrdered: screensOrdered
            )
        }

        // Find adjacent screens for next/prev navigation
        let adjacentScreens = adjacent(toFrameOfScreen: sourceScreen.frame, screens: screensOrdered)

        return UsableScreens(
            currentScreen: sourceScreen,
            adjacentScreens: adjacentScreens,
            numScreens: screens.count,
            screensOrdered: screensOrdered
        )
    }

    /// Detects screens based on cursor position rather than window position.
    ///
    /// Used when the user prefers cursor-based screen detection
    /// (controlled by `Defaults.useCursorScreenDetection`).
    ///
    /// - Returns: UsableScreens for the screen containing the cursor.
    func detectScreensAtCursor() -> UsableScreens? {
        let screens = NSScreen.screens

        // Single screen: just use normal detection
        if screens.count == 1 {
            return detectScreens(using: nil)
        }

        let screensOrdered = order(screens: screens)

        // Find the screen containing the mouse cursor
        guard let cursorScreen = screens.first(where: { $0.frame.contains(NSEvent.mouseLocation) }) else {
            // Fallback: use normal detection if cursor isn't on any screen (rare)
            return detectScreens(using: nil)
        }

        let adjacentScreens = adjacent(toFrameOfScreen: cursorScreen.frame, screens: screensOrdered)

        return UsableScreens(
            currentScreen: cursorScreen,
            adjacentScreens: adjacentScreens,
            numScreens: screens.count,
            screensOrdered: screensOrdered
        )
    }

    // MARK: - Screen Containment

    /// Finds which screen contains a given rectangle (window frame).
    ///
    /// If the rectangle spans multiple screens, returns the screen that
    /// contains the largest portion of the rectangle.
    ///
    /// - Parameters:
    ///   - rect: The rectangle to find (typically a window frame, in CG coordinates).
    ///   - screens: The list of screens to search.
    /// - Returns: The screen containing the most of the rectangle, or main screen as fallback.
    func screenContaining(_ rect: CGRect, screens: [NSScreen]) -> NSScreen? {
        var result: NSScreen? = NSScreen.main
        var largestPercentageOfRectWithinFrameOfScreen: CGFloat = 0.0

        for currentScreen in screens {
            let currentFrameOfScreen = NSRectToCGRect(currentScreen.frame)

            // Convert rect to screen (AppKit) coordinates for comparison
            let normalizedRect = rect.screenFlipped

            // Best case: screen completely contains the rectangle
            if currentFrameOfScreen.contains(normalizedRect) {
                result = currentScreen
                break
            }

            // Otherwise: find screen with largest overlap
            let percentageOfRectWithinCurrentScreen = percentageOf(normalizedRect, withinFrameOfScreen: currentFrameOfScreen)
            if percentageOfRectWithinCurrentScreen > largestPercentageOfRectWithinFrameOfScreen {
                largestPercentageOfRectWithinFrameOfScreen = percentageOfRectWithinCurrentScreen
                result = currentScreen
            }
        }

        return result
    }

    /// Calculates what percentage of a rectangle is within a screen's frame.
    ///
    /// - Parameters:
    ///   - rect: The rectangle to measure.
    ///   - frameOfScreen: The screen's frame.
    /// - Returns: A value from 0.0 (no overlap) to 1.0 (fully contained).
    func percentageOf(_ rect: CGRect, withinFrameOfScreen frameOfScreen: CGRect) -> CGFloat {
        let intersection = rect.intersection(frameOfScreen)

        // If no overlap, return 0
        if intersection.isNull {
            return 0.0
        }

        // Calculate: (area of overlap) / (total area of rect)
        return computeAreaOfRect(rect: intersection) / computeAreaOfRect(rect: rect)
    }

    // MARK: - Adjacent Screen Detection

    /// Finds the previous and next screens relative to a given screen.
    ///
    /// The screens form a circular list:
    /// - Screen 1's "prev" is the last screen
    /// - Last screen's "next" is Screen 1
    ///
    /// With exactly 2 screens, both prev and next point to the other screen.
    ///
    /// - Parameters:
    ///   - frameOfScreen: The frame of the current screen.
    ///   - screens: All screens in their navigation order.
    /// - Returns: AdjacentScreens with prev/next, or nil if navigation isn't possible.
    func adjacent(toFrameOfScreen frameOfScreen: CGRect, screens: [NSScreen]) -> AdjacentScreens? {

        // TWO SCREENS: simple case - the other screen is both prev and next
        if screens.count == 2 {
            let otherScreen = screens.first { screen in
                let frame = NSRectToCGRect(screen.frame)
                return !frame.equalTo(frameOfScreen)
            }
            if let otherScreen = otherScreen {
                return AdjacentScreens(prev: otherScreen, next: otherScreen)
            }
        }

        // THREE OR MORE SCREENS: circular navigation
        else if screens.count > 2 {
            // Find index of current screen
            let currentScreenIndex = screens.firstIndex { screen in
                let frame = NSRectToCGRect(screen.frame)
                return frame.equalTo(frameOfScreen)
            }

            if let currentScreenIndex = currentScreenIndex {
                // Calculate next index (wrap to 0 if at end)
                let nextIndex = currentScreenIndex == screens.count - 1
                    ? 0
                    : currentScreenIndex + 1

                // Calculate prev index (wrap to end if at 0)
                let prevIndex = currentScreenIndex == 0
                    ? screens.count - 1
                    : currentScreenIndex - 1

                return AdjacentScreens(prev: screens[prevIndex], next: screens[nextIndex])
            }
        }

        return nil
    }

    // MARK: - Screen Ordering

    /// Orders screens for consistent navigation.
    ///
    /// Two ordering modes are supported:
    ///
    /// 1. **X-coordinate ordering** (user preference):
    ///    Simply sorts screens left-to-right by their X position.
    ///    Best for horizontal monitor arrangements.
    ///
    /// 2. **Default ordering** (top-to-bottom, then left-to-right):
    ///    Screens higher on the desk come first, then within the same
    ///    vertical position, left-to-right.
    ///    Better for mixed arrangements (e.g., laptop below external monitor).
    ///
    /// - Parameter screens: The screens to order.
    /// - Returns: Screens in navigation order.
    func order(screens: [NSScreen]) -> [NSScreen] {

        // Option 1: Simple left-to-right ordering
        if Defaults.screensOrderedByX.userEnabled {
            return screens.sorted { $0.frame.origin.x < $1.frame.origin.x }
        }

        // Option 2: Top-to-bottom, then left-to-right
        // This is more complex because we need to handle overlapping vertical positions
        return screens.sorted { screen1, screen2 in
            // If screen2 is completely BELOW screen1, screen1 comes first
            if screen2.frame.maxY <= screen1.frame.minY {
                return true
            }

            // If screen1 is completely BELOW screen2, screen2 comes first
            if screen1.frame.maxY <= screen2.frame.minY {
                return false
            }

            // Screens overlap vertically: sort by X position (left-to-right)
            return screen1.frame.minX < screen2.frame.minX
        }
    }

    // MARK: - Helper Methods

    /// Calculates the area of a rectangle.
    private func computeAreaOfRect(rect: CGRect) -> CGFloat {
        return rect.size.width * rect.size.height
    }
}

// MARK: - UsableScreens Struct

/// Contains information about available screens for a window action.
///
/// This is the result of screen detection - it tells the window manager:
/// - Which screen the window is currently on
/// - Which screens to use for "next/previous display" commands
/// - How many total screens are connected
struct UsableScreens {

    /// The screen that currently contains the window (or cursor).
    let currentScreen: NSScreen

    /// The screens for next/prev navigation, or nil if not available.
    let adjacentScreens: AdjacentScreens?

    /// The frame of the current screen (convenience property).
    let frameOfCurrentScreen: CGRect

    /// Total number of connected screens.
    let numScreens: Int

    /// All screens in navigation order.
    let screensOrdered: [NSScreen]

    init(currentScreen: NSScreen, adjacentScreens: AdjacentScreens? = nil, numScreens: Int, screensOrdered: [NSScreen]? = nil) {
        self.currentScreen = currentScreen
        self.adjacentScreens = adjacentScreens
        self.frameOfCurrentScreen = currentScreen.frame
        self.numScreens = numScreens
        self.screensOrdered = screensOrdered ?? [currentScreen]
    }
}

// MARK: - AdjacentScreens Struct

/// Holds references to the previous and next screens for navigation.
///
/// Used by "move to next display" and "move to previous display" actions.
struct AdjacentScreens {
    /// The screen to move to when pressing "previous display".
    let prev: NSScreen

    /// The screen to move to when pressing "next display".
    let next: NSScreen
}

// MARK: - NSScreen Extension

extension NSScreen {

    /// Returns the visible frame adjusted for Stage Manager, Todo sidebar, and screen edge gaps.
    ///
    /// The standard `visibleFrame` already accounts for menu bar and Dock.
    /// This method further adjusts for:
    /// 1. Stage Manager strip (if enabled on macOS Ventura+)
    /// 2. Todo sidebar (if Todo Mode is active)
    /// 3. User-configured screen edge gaps
    ///
    /// - Parameters:
    ///   - ignoreTodo: If true, don't subtract space for Todo sidebar.
    ///   - ignoreStage: If true, don't subtract space for Stage Manager.
    /// - Returns: The adjusted frame where windows can be placed.
    func adjustedVisibleFrame(_ ignoreTodo: Bool = false, _ ignoreStage: Bool = false) -> CGRect {
        var newFrame = visibleFrame

        // STAGE MANAGER ADJUSTMENT (macOS Ventura+)
        // Stage Manager shows a strip of window thumbnails on the left side
        if !ignoreStage && Defaults.stageSize.value > 0 {
            let stageManagerActive = StageUtil.stageCapable
                && StageUtil.stageEnabled
                && StageUtil.stageStripShow
                && StageUtil.isStageStripVisible(self)

            if stageManagerActive {
                // Stage size can be pixels (>= 1) or fraction of screen width (< 1)
                let stageSize = Defaults.stageSize.value < 1
                    ? newFrame.size.width * Defaults.stageSize.cgFloat
                    : Defaults.stageSize.cgFloat

                // Adjust origin if Stage Manager is on the left
                if StageUtil.stageStripPosition == .left {
                    newFrame.origin.x += stageSize
                }
                newFrame.size.width -= stageSize
            }
        }

        // TODO SIDEBAR ADJUSTMENT
        // When Todo Mode is active, one side of the screen is reserved for the todo app
        if !ignoreTodo,
           Defaults.todo.userEnabled,
           Defaults.todoMode.enabled,
           TodoManager.todoScreen == self,
           TodoManager.hasTodoWindow() {

            let sidebarWidth = TodoManager.getSidebarWidth(visibleFrameWidth: visibleFrame.width)
            newFrame.size.width -= sidebarWidth

            // Adjust origin if sidebar is on the left
            if Defaults.todoSidebarSide.value == .left {
                newFrame.origin.x += sidebarWidth
            }
        }

        // SCREEN EDGE GAPS
        // User-configured gaps from screen edges (for aesthetics or avoiding screen edges)

        // Option: only apply gaps on main screen
        if Defaults.screenEdgeGapsOnMainScreenOnly.enabled, self != NSScreen.screens.first {
            return newFrame
        }

        // Apply gaps from each edge
        newFrame.origin.x += Defaults.screenEdgeGapLeft.cgFloat
        newFrame.origin.y += Defaults.screenEdgeGapBottom.cgFloat
        newFrame.size.width -= (Defaults.screenEdgeGapLeft.cgFloat + Defaults.screenEdgeGapRight.cgFloat)

        // Top gap: use special "notch" gap for MacBooks with notch displays
        if #available(macOS 12.0, *), self.safeAreaInsets.top != 0, Defaults.screenEdgeGapTopNotch.value != 0 {
            newFrame.size.height -= (Defaults.screenEdgeGapTopNotch.cgFloat + Defaults.screenEdgeGapBottom.cgFloat)
        } else {
            newFrame.size.height -= (Defaults.screenEdgeGapTop.cgFloat + Defaults.screenEdgeGapBottom.cgFloat)
        }

        return newFrame
    }

    /// Returns true if any connected display is in portrait orientation.
    ///
    /// Used to determine whether to show portrait-specific snap areas.
    static var portraitDisplayConnected: Bool {
        NSScreen.screens.contains { !$0.frame.isLandscape }
    }
}
