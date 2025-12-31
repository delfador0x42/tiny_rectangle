//
//  TodoManager.swift
//  tiny_window_manager
//
//  "Todo Mode" lets you pin a designated app (like Reminders, Things, or Todoist)
//  as a persistent sidebar on the left or right edge of your screen.
//
//  When Todo Mode is enabled:
//  ┌──────────────────────────────────┐
//  │                         │ TODO  │  ← Todo app pinned to the right
//  │      Main workspace     │  APP  │    (or left, user configurable)
//  │                         │       │
//  │  Other windows resize   │ Always│
//  │  to avoid overlapping   │ Visible
//  │                         │       │
//  └──────────────────────────────────┘
//
//  Features:
//  - Toggle shortcut (default: Ctrl+Option+B) to enable/disable
//  - Reflow shortcut (default: Ctrl+Option+N) to re-arrange all windows
//  - Configurable sidebar width (pixels or percentage)
//  - Configurable sidebar side (left or right)
//  - Automatically moves other windows out of the sidebar area
//

import Cocoa

// MARK: - Todo Manager

/// Manages the "Todo Mode" feature - a persistent sidebar for a designated todo app.
/// This is a static-only class (all methods and properties are static).
class TodoManager {

    // MARK: - Window Tracking

    /// The window ID of the current todo window.
    /// This is cached to avoid repeatedly querying for the same window.
    private static var todoWindowId: CGWindowID?

    /// The screen where the todo sidebar is displayed
    static var todoScreen: NSScreen?

    // MARK: - Enable/Disable Todo Mode

    /// Enables or disables todo mode.
    static func setTodoMode(_ enabled: Bool, _ bringToFront: Bool = true) {
        print(#function, "called")
        Defaults.todoMode.enabled = enabled
        moveAllIfNeeded(bringToFront)
    }

    // MARK: - Stub methods for compatibility

    static func registerUnregisterToggleShortcut() {
        // Shortcuts removed - no-op
    }

    static func registerUnregisterReflowShortcut() {
        // Shortcuts removed - no-op
    }

    static func getToggleKeyDisplay() -> (String?, NSEvent.ModifierFlags)? {
        return nil
    }

    static func getReflowKeyDisplay() -> (String?, NSEvent.ModifierFlags)? {
        return nil
    }

    // MARK: - Todo Window Detection

    /// Gets the accessibility element for the todo window.
    /// Caches the window ID to avoid repeated lookups.
    private static func getTodoWindowElement() -> AccessibilityElement? {
        print(#function, "called")
        // Get the bundle ID of the configured todo app
        guard let bundleId = Defaults.todoApplication.value,
              let windowElements = AccessibilityElement(bundleId)?.windowElements
        else {
            todoWindowId = nil
            return nil
        }

        // Check if our cached window ID is still valid
        if let windowId = todoWindowId {
            let windowStillExists = windowElements.contains { $0.windowId == windowId }
            if !windowStillExists {
                todoWindowId = nil
            }
        }

        // If no cached window, use the first window
        if todoWindowId == nil {
            todoWindowId = windowElements.first?.windowId
        }

        // Find and return the window element with our cached ID
        if let windowId = todoWindowId,
           let windowElement = windowElements.first(where: { $0.windowId == windowId }) {
            return windowElement
        }

        todoWindowId = nil
        return nil
    }

    /// Returns true if a todo window exists (the todo app is running with a window open)
    static func hasTodoWindow() -> Bool {
        print(#function, "called")
        return getTodoWindowElement() != nil
    }

    /// Returns true if the frontmost window is the todo window
    static func isTodoWindowFront() -> Bool {
        print(#function, "called")
        guard let windowElement = AccessibilityElement.getFrontWindowElement() else {
            return false
        }
        return isTodoWindow(windowElement)
    }

    /// Checks if the given accessibility element is the todo window
    static func isTodoWindow(_ windowElement: AccessibilityElement) -> Bool {
        print(#function, "called")
        guard let windowId = windowElement.windowId else {
            return false
        }
        return isTodoWindow(windowId)
    }

    /// Checks if the given window ID is the todo window
    static func isTodoWindow(_ windowId: CGWindowID) -> Bool {
        print(#function, "called")
        return getTodoWindowElement()?.windowId == windowId
    }

    /// Resets the cached todo window ID.
    /// Call this when the todo app changes or when windows may have changed.
    static func resetTodoWindow() {
        print(#function, "called")
        todoWindowId = nil
        _ = getTodoWindowElement()  // Re-detect
    }

    // MARK: - Window Arrangement

    /// Moves all windows to accommodate the todo sidebar.
    /// This is the main "reflow" operation.
    ///
    /// - Parameter bringToFront: Whether to bring the todo window to the front (default: true)
    static func moveAll(_ bringToFront: Bool = true) {
        print(#function, "called")
        // Update which screen the todo window is on
        TodoManager.refreshTodoScreen()

        // Get all windows except our own (to avoid the footprint window)
        let ourPid = ProcessInfo.processInfo.processIdentifier
        let allWindows = AccessibilityElement.getAllWindowElements().filter { $0.pid != ourPid }

        // Get the todo window
        guard let todoWindow = getTodoWindowElement(),
              let screen = TodoManager.todoScreen
        else {
            return
        }

        // First pass: Move other windows out of the sidebar area
        let screenDetector = ScreenDetection()
        let adjustedVisibleFrame = screen.adjustedVisibleFrame()

        for window in allWindows {
            let windowScreen = screenDetector.detectScreens(using: window)?.currentScreen
            let isOnTodoScreen = windowScreen == TodoManager.todoScreen
            let isNotTodoWindow = window.getWindowId() != todoWindow.getWindowId()

            if isOnTodoScreen && isNotTodoWindow {
                shiftWindowOffSidebar(window, screenVisibleFrame: adjustedVisibleFrame)
            }
        }

        // Second pass: Position the todo window in the sidebar
        positionTodoWindow(todoWindow, on: screen)

        // Optionally bring the todo window to front
        if bringToFront {
            todoWindow.bringToFront()
        }
    }

    /// Positions the todo window in its sidebar location
    private static func positionTodoWindow(_ todoWindow: AccessibilityElement, on screen: NSScreen) {
        print(#function, "called")
        let adjustedVisibleFrame = screen.adjustedVisibleFrame(true)
        let sidebarWidth = getSidebarWidth(visibleFrameWidth: adjustedVisibleFrame.width)
        let isRightSide = Defaults.todoSidebarSide.value == .right

        // Calculate the sidebar rectangle
        var rect = adjustedVisibleFrame
        rect.size.width = sidebarWidth

        if isRightSide {
            rect.origin.x = adjustedVisibleFrame.maxX - sidebarWidth
        }

        // Convert to screen-flipped coordinates (macOS uses bottom-left origin)
        rect = rect.screenFlipped

        // Apply gaps if configured
        if Defaults.gapSize.value > 0 {
            let sharedEdge: Edge = isRightSide ? .left : .right
            rect = GapCalculation.applyGaps(rect, sharedEdges: sharedEdge, gapSize: Defaults.gapSize.value)
        }

        todoWindow.setFrame(rect)
    }

    // MARK: - Sidebar Width Calculation

    /// Calculates the sidebar width in pixels.
    /// Handles both pixel values and percentage values.
    ///
    /// - Parameter visibleFrameWidth: The width of the visible screen area
    /// - Returns: The sidebar width in pixels
    static func getSidebarWidth(visibleFrameWidth: CGFloat) -> CGFloat {
        print(#function, "called")
        var sidebarWidth = Defaults.todoSidebarWidth.cgFloat

        // Handle percentage values stored as decimals (0.0 - 1.0)
        if sidebarWidth > 0 && sidebarWidth <= 1 {
            sidebarWidth = sidebarWidth * visibleFrameWidth
        }
        // Handle percentage values stored as whole numbers (e.g., 25 for 25%)
        else if Defaults.todoSidebarWidthUnit.value == .pct {
            sidebarWidth = convert(width: sidebarWidth, toUnit: .pixels, visibleFrameWidth: visibleFrameWidth)
        }

        return sidebarWidth
    }

    /// Converts a width value between pixels and percentage.
    ///
    /// - Parameters:
    ///   - width: The width value to convert
    ///   - unit: The target unit (.pixels or .pct)
    ///   - visibleFrameWidth: The width of the visible screen area
    /// - Returns: The converted width value
    static func convert(width: CGFloat, toUnit unit: TodoSidebarWidthUnit, visibleFrameWidth: CGFloat) -> CGFloat {
        print(#function, "called")
        switch unit {
        case .pixels:
            // Convert percentage to pixels: (25% of 1000px = 250px)
            return ((width * 0.01) * visibleFrameWidth).rounded()
        case .pct:
            // Convert pixels to percentage: (250px of 1000px = 25%)
            return ((width / visibleFrameWidth) * 100).rounded()
        }
    }

    /// Moves all windows if todo mode is enabled.
    /// This is a conditional wrapper around moveAll().
    static func moveAllIfNeeded(_ bringToFront: Bool = true) {
        print(#function, "called")
        guard Defaults.todo.userEnabled && Defaults.todoMode.enabled else {
            return
        }
        moveAll(bringToFront)
    }

    /// Updates the todoScreen property based on where the todo window currently is
    static func refreshTodoScreen() {
        print(#function, "called")
        let todoWindow = getTodoWindowElement()
        let screens = ScreenDetection().detectScreens(using: todoWindow)
        TodoManager.todoScreen = screens?.currentScreen
    }

    // MARK: - Window Shifting

    /// Shifts a window to avoid overlapping the todo sidebar.
    /// If the window is too wide, it will be resized to fit.
    private static func shiftWindowOffSidebar(_ window: AccessibilityElement, screenVisibleFrame: CGRect) {
        print(#function, "called")
        var rect = window.frame
        let halfGapWidth = CGFloat(Defaults.gapSize.value) / 2

        // Calculate the "safe zone" boundaries (area not occupied by sidebar)
        let safeMinX = screenVisibleFrame.minX + halfGapWidth
        let safeMaxX = screenVisibleFrame.maxX - halfGapWidth

        let sidebarOnLeft = Defaults.todoSidebarSide.value == .left
        let sidebarOnRight = Defaults.todoSidebarSide.value == .right

        if sidebarOnLeft && rect.minX < safeMinX {
            // Window overlaps left sidebar - shift it right
            shiftWindowRight(&rect, safeMinX: safeMinX, screenMaxX: screenVisibleFrame.maxX)
            window.setFrame(rect)
        } else if sidebarOnRight && rect.maxX > safeMaxX {
            // Window overlaps right sidebar - shift it left
            shiftWindowLeft(&rect, safeMaxX: safeMaxX, screenMinX: screenVisibleFrame.minX)
            window.setFrame(rect)
        }
    }

    /// Shifts a window to the right to avoid the left sidebar
    private static func shiftWindowRight(_ rect: inout CGRect, safeMinX: CGFloat, screenMaxX: CGFloat) {
        print(#function, "called")
        let overlap = safeMinX - rect.minX

        // Try to shift the window right
        rect.origin.x = min(screenMaxX - rect.width, rect.origin.x + overlap)

        // If window is still overlapping (too wide), resize it
        if rect.minX < safeMinX {
            let widthDiff = safeMinX - rect.minX
            rect.origin.x += widthDiff
            rect.size.width -= widthDiff
        }
    }

    /// Shifts a window to the left to avoid the right sidebar
    private static func shiftWindowLeft(_ rect: inout CGRect, safeMaxX: CGFloat, screenMinX: CGFloat) {
        print(#function, "called")
        let overlap = rect.maxX - safeMaxX

        // Try to shift the window left
        rect.origin.x = max(screenMinX, rect.origin.x - overlap)

        // If window is still overlapping (too wide), resize it
        if rect.maxX > safeMaxX {
            rect.size.width -= rect.maxX - safeMaxX
        }
    }

    // MARK: - Action Execution

    /// Executes a todo-related action.
    /// Called when the user triggers .leftTodo or .rightTodo actions.
    ///
    /// - Parameter parameters: The execution parameters containing the action
    /// - Returns: true if a todo action was executed, false otherwise
    static func execute(parameters: ExecutionParameters) -> Bool {
        print(#function, "called")
        let todoActions: [WindowAction] = [.leftTodo, .rightTodo]

        if todoActions.contains(parameters.action) {
            moveAll()
            return true
        }

        return false
    }
}

// MARK: - Supporting Types

/// Which side of the screen the todo sidebar appears on
enum TodoSidebarSide: Int {
    case right = 1  // Sidebar on the right edge
    case left = 2   // Sidebar on the left edge
}

/// Unit for specifying the todo sidebar width
enum TodoSidebarWidthUnit: Int, CustomStringConvertible {
    case pixels = 1  // Absolute width in pixels
    case pct = 2     // Percentage of screen width

    /// Human-readable unit suffix for display
    var description: String {
        switch self {
        case .pixels:
            return "px"
        case .pct:
            return "%"
        }
    }
}
