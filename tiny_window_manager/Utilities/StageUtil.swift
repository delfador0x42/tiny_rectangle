//
//  StageUtil.swift
//  tiny_window_manager
//
//  Utilities for interacting with macOS Stage Manager feature.
//  Stage Manager organizes windows into groups shown in a strip on the side of the screen.
//

import Foundation

// MARK: - Stage Strip Position

/// The side of the screen where the Stage Manager strip appears
enum StageStripPosition {
    case left
    case right
}

// MARK: - Stage Utility

/// Provides utilities for detecting and interacting with macOS Stage Manager
class StageUtil {

    // MARK: - User Defaults Access

    /// Access to Window Manager preferences (Stage Manager settings)
    private static let windowManagerDefaults = UserDefaults(suiteName: "com.apple.WindowManager")

    /// Access to Dock preferences (determines strip position)
    private static let dockDefaults = UserDefaults(suiteName: "com.apple.dock")

    // MARK: - Stage Manager Status

    /// Returns true if this Mac supports Stage Manager (requires macOS 13+)
    static var stageCapable: Bool {
        if #available(macOS 13, *) {
            return true
        }
        return false
    }

    /// Returns true if Stage Manager is currently enabled in System Settings
    static var stageEnabled: Bool {
        let isEnabled = windowManagerDefaults?.object(forKey: "GloballyEnabled") as? Bool
        return isEnabled ?? false
    }

    /// Returns true if the Stage Manager strip is visible (not auto-hidden)
    static var stageStripShow: Bool {
        let isAutoHidden = windowManagerDefaults?.object(forKey: "AutoHide") as? Bool
        return !(isAutoHidden ?? false)
    }

    // MARK: - Strip Position

    /// Returns which side of the screen the Stage Manager strip appears on.
    /// The strip appears on the opposite side of the Dock.
    static var stageStripPosition: StageStripPosition {
        let dockPosition = dockDefaults?.string(forKey: "orientation")

        switch dockPosition {
        case "left":
            return .right
        case "right":
            return .left
        default:
            // Dock is at the bottom, so strip position depends on language direction
            return positionForBottomDock()
        }
    }

    /// Determines strip position when Dock is at the bottom.
    /// For right-to-left languages, strip goes on the right; otherwise left.
    private static func positionForBottomDock() -> StageStripPosition {
        if #available(macOS 13, *) {
            let isRightToLeft = Locale.current.language.characterDirection == .rightToLeft
            return isRightToLeft ? .right : .left
        }
        return .left
    }

    // MARK: - Strip Visibility Detection

    /// Checks if the Stage Manager strip is currently visible on the given screen
    /// - Parameter screen: The screen to check (defaults to main screen)
    /// - Returns: true if the strip is visible with at least 2 window groups
    static func isStageStripVisible(_ screen: NSScreen? = .main) -> Bool {
        guard let screen else {
            return false
        }

        let windowManagerWindows = findWindowManagerWindows(on: screen)

        // Need at least 2 windows - a single window could just be for a dragged window
        return windowManagerWindows.count >= 2
    }

    /// Finds all WindowManager process windows that belong to the given screen
    private static func findWindowManagerWindows(on screen: NSScreen) -> [WindowInfo] {
        return WindowUtil.getWindowList().filter { windowInfo in
            isWindowManagerWindow(windowInfo, on: screen)
        }
    }

    /// Checks if a window belongs to the WindowManager process and is on the given screen
    private static func isWindowManagerWindow(_ windowInfo: WindowInfo, on targetScreen: NSScreen) -> Bool {
        guard windowInfo.processName == "WindowManager" else {
            return false
        }

        let windowScreen = findScreenForWindow(windowInfo)
        return windowScreen == targetScreen
    }

    /// Determines which screen a window belongs to based on its position
    private static func findScreenForWindow(_ windowInfo: WindowInfo) -> NSScreen? {
        let windowFrame = windowInfo.frame.screenFlipped

        // Find screens that vertically contain this window
        let candidateScreens = NSScreen.screens.filter { screen in
            let verticallyContained = screen.frame.minY <= windowFrame.minY
                                   && windowFrame.maxY <= screen.frame.maxY
            return verticallyContained
        }

        // Pick the screen closest to the window horizontally
        if stageStripPosition == .left {
            // Strip is on the left, so match by left edge
            return candidateScreens.min { screenA, screenB in
                let distanceA = abs(windowFrame.minX - screenA.frame.minX)
                let distanceB = abs(windowFrame.minX - screenB.frame.minX)
                return distanceA < distanceB
            }
        } else {
            // Strip is on the right, so match by right edge
            return candidateScreens.min { screenA, screenB in
                let distanceA = abs(screenA.frame.maxX - windowFrame.maxX)
                let distanceB = abs(screenB.frame.maxX - windowFrame.maxX)
                return distanceA < distanceB
            }
        }
    }

    // MARK: - Window Group Access

    /// Gets all window groups shown in the Stage Manager strip for a screen
    /// - Parameter screen: The screen to check (defaults to main screen)
    /// - Returns: Array of window ID arrays, where each inner array is a group
    private static func getStageStripWindowGroups(_ screen: NSScreen? = .main) -> [[CGWindowID]] {
        guard let screen else {
            return []
        }

        // Get the WindowManager app's accessibility element
        guard let appElement = AccessibilityElement("com.apple.WindowManager") else {
            return []
        }

        // Find the strip element for this screen
        guard let stripElement = findStripElement(for: screen, in: appElement) else {
            return []
        }

        // Get the button elements representing each window group
        guard let groupButtons = stripElement.getChildElement(.list)?.getChildElements(.button) else {
            return []
        }

        // Extract window IDs from each group button
        return groupButtons.compactMap { $0.windowIds }
    }

    /// Finds the Stage Manager strip accessibility element for a given screen
    private static func findStripElement(
        for screen: NSScreen,
        in appElement: AccessibilityElement
    ) -> AccessibilityElement? {
        guard let stripElements = appElement.getChildElements(.group) else {
            return nil
        }

        return stripElements.first { element in
            let elementFrame = element.frame.screenFlipped
            let isValidFrame = !elementFrame.isNull
            let isOnScreen = screen.frame.contains(elementFrame)
            return isValidFrame && isOnScreen
        }
    }

    /// Gets the window group containing a specific window ID
    /// - Parameters:
    ///   - windowId: The window ID to search for
    ///   - screen: The screen to check (defaults to main screen)
    /// - Returns: Array of window IDs in the same group, or nil if not found
    static func getStageStripWindowGroup(_ windowId: CGWindowID, _ screen: NSScreen? = .main) -> [CGWindowID]? {
        let allGroups = getStageStripWindowGroups(screen)
        return allGroups.first { group in
            group.contains(windowId)
        }
    }
}
