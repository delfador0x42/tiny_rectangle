//
//  MultiWindowManager.swift
//  tiny_window_manager
//
//

import Cocoa
import MASShortcut

/// Manages operations that affect multiple windows at once.
///
/// This class provides functionality to arrange multiple windows on screen:
/// - **Tile**: Arranges windows in a grid pattern (like tiles on a floor)
/// - **Cascade**: Stacks windows diagonally with offsets (like a cascade of cards)
/// - **Reverse**: Reverses the order/positions of windows
///
/// All operations work on the current screen where the frontmost window is located.
class MultiWindowManager {

    // MARK: - Public Methods

    /// Executes a multi-window action based on the provided parameters.
    ///
    /// This is the main entry point for multi-window operations.
    /// It dispatches to the appropriate handler based on the action type.
    ///
    /// - Parameter parameters: Contains the action type and optional window element
    /// - Returns: `true` if the action was handled, `false` for unsupported actions
    static func execute(parameters: ExecutionParameters) -> Bool {
        print(#function, "called")
        // TODO: Protocol and factory for all multi-window positioning algorithms
        switch parameters.action {
        case .reverseAll:
            ReverseAllManager.reverseAll(windowElement: parameters.windowElement)
            return true
        case .tileAll:
            tileAllWindowsOnScreen(windowElement: parameters.windowElement)
            return true
        case .cascadeAll:
            cascadeAllWindowsOnScreen(windowElement: parameters.windowElement)
            return true
        case .cascadeActiveApp:
            cascadeActiveAppWindowsOnScreen(windowElement: parameters.windowElement)
            return true
        default:
            return false
        }
    }

    /// Arranges all windows on the current screen in a grid pattern.
    ///
    /// Windows are laid out in rows and columns to fill the screen evenly.
    /// The grid size is calculated to be as square as possible based on window count.
    ///
    /// Example: 6 windows → 3 columns × 2 rows
    ///
    /// - Parameter windowElement: Optional window to use for determining the current screen.
    ///                            If nil, uses the frontmost window.
    static func tileAllWindowsOnScreen(windowElement: AccessibilityElement? = nil) {
        print(#function, "called")
        guard let (screens, windows) = allWindowsOnScreen(windowElement: windowElement, sortByPID: true) else {
            return
        }

        let screenFrame = screens.currentScreen.adjustedVisibleFrame().screenFlipped
        let windowCount = windows.count

        // Calculate grid dimensions to be as square as possible
        // Example: 6 windows → sqrt(6) ≈ 2.45 → ceil = 3 columns
        let columns = Int(ceil(sqrt(CGFloat(windowCount))))
        // Example: 6 windows, 3 columns → 6/3 = 2 rows
        let rows = Int(ceil(CGFloat(windowCount) / CGFloat(columns)))

        // Calculate the size of each tile
        let tileWidth = screenFrame.width / CGFloat(columns)
        let tileHeight = screenFrame.height / CGFloat(rows)
        let tileSize = CGSize(width: tileWidth, height: tileHeight)

        // Position each window in its grid cell
        for (index, window) in windows.enumerated() {
            let column = index % columns  // 0, 1, 2, 0, 1, 2, ...
            let row = index / columns     // 0, 0, 0, 1, 1, 1, ...
            tileWindow(window, screenFrame: screenFrame, size: tileSize, column: column, row: row)
        }
    }

    /// Arranges all windows on the current screen in a cascading diagonal pattern.
    ///
    /// Each window is offset slightly from the previous one, creating a
    /// "fanned out" effect like a deck of cards. Windows keep their original sizes.
    ///
    /// - Parameter windowElement: Optional window to use for determining the current screen.
    ///                            If nil, uses the frontmost window.
    static func cascadeAllWindowsOnScreen(windowElement: AccessibilityElement? = nil) {
        print(#function, "called")
        guard let (screens, windows) = allWindowsOnScreen(windowElement: windowElement, sortByPID: true) else {
            return
        }

        let screenFrame = screens.currentScreen.adjustedVisibleFrame().screenFlipped

        // Delta is the offset between each cascaded window (both X and Y)
        let delta = CGFloat(Defaults.cascadeAllDeltaSize.value)

        for (index, window) in windows.enumerated() {
            cascadeWindow(window, screenFrame: screenFrame, delta: delta, index: index)
        }
    }

    /// Cascades only the windows belonging to the currently active application.
    ///
    /// This is smarter than `cascadeAllWindowsOnScreen`:
    /// - Only affects windows from the frontmost app
    /// - Cascades from the corner nearest to the front window's current position
    /// - Resizes windows to fit within the screen while cascaded
    /// - Cycles the front window to the top of the stack
    ///
    /// - Parameter windowElement: Optional window to use for determining the current screen.
    ///                            If nil, uses the frontmost window.
    static func cascadeActiveAppWindowsOnScreen(windowElement: AccessibilityElement? = nil) {
        print(#function, "called")
        guard let (screens, windows) = allWindowsOnScreen(windowElement: windowElement, sortByPID: true),
              let frontWindowElement = AccessibilityElement.getFrontWindowElement()
        else {
            return
        }

        let screenFrame = screens.currentScreen.adjustedVisibleFrame().screenFlipped
        let delta = CGFloat(Defaults.cascadeAllDeltaSize.value)

        // Filter to only windows belonging to the same app as the front window
        var appWindows = windows.filter { window in
            window.pid == frontWindowElement.pid
        }

        // Set up cascade parameters based on the front window's position
        var cascadeParameters: CascadeActiveAppParameters?

        if let firstWindow = appWindows.first {
            // Cycle the front window to become the topmost in the cascade
            // by moving it from the front to the back of our array
            appWindows.append(appWindows.removeFirst())

            // Calculate cascade parameters based on the first window's position
            cascadeParameters = CascadeActiveAppParameters(
                windowFrame: firstWindow.frame,
                screenFrame: screenFrame,
                numWindows: appWindows.count,
                size: firstWindow.size!,
                delta: delta
            )
        }

        // Apply the cascade to each window
        for (index, window) in appWindows.enumerated() {
            cascadeWindow(window, screenFrame: screenFrame, delta: delta, index: index, cascadeParameters: cascadeParameters)
        }
    }

    // MARK: - Private Helpers

    /// Gathers all valid windows on the same screen as the reference window.
    ///
    /// This method:
    /// 1. Detects which screen the reference window is on
    /// 2. Gets all windows from all apps
    /// 3. Filters to only windows on the same screen
    /// 4. Excludes special windows (sheets, minimized, hidden, system dialogs, todo windows)
    ///
    /// - Parameters:
    ///   - windowElement: The reference window for screen detection. Uses front window if nil.
    ///   - sortByPID: If true, sorts windows by process ID (groups windows by app)
    /// - Returns: A tuple of (screen info, filtered windows), or nil if detection fails
    private static func allWindowsOnScreen(windowElement: AccessibilityElement? = nil, sortByPID: Bool = false) -> (screens: UsableScreens, windows: [AccessibilityElement])? {
        print(#function, "called")
        let screenDetection = ScreenDetection()

        // Get the reference window (provided or frontmost)
        guard let windowElement = windowElement ?? AccessibilityElement.getFrontWindowElement(),
              let screens = screenDetection.detectScreens(using: windowElement)
        else {
            NSSound.beep()
            Logger.log("Can't detect screen for multiple windows")
            return nil
        }

        let currentScreen = screens.currentScreen

        // Get all windows from all applications
        var windows = AccessibilityElement.getAllWindowElements()

        // Optionally sort by process ID to group windows from the same app together
        if sortByPID {
            windows.sort { window1, window2 in
                let pid1 = window1.pid ?? pid_t(0)
                let pid2 = window2.pid ?? pid_t(0)
                return pid1 > pid2
            }
        }

        // Filter to only "real" windows on the current screen
        var validWindows = [AccessibilityElement]()
        for window in windows {
            // Skip the todo window if todo mode is enabled
            if Defaults.todo.userEnabled, TodoManager.isTodoWindow(window) {
                continue
            }

            // Check if this window is on the current screen
            let windowScreen = screenDetection.detectScreens(using: window)?.currentScreen
            guard windowScreen == currentScreen else { continue }

            // Exclude special window types that shouldn't be arranged
            let isValidWindow = window.isWindow == true
                && window.isSheet != true       // Sheets are attached to parent windows
                && window.isMinimized != true   // Minimized windows aren't visible
                && window.isHidden != true      // Hidden windows aren't visible
                && window.isSystemDialog != true // System dialogs shouldn't be moved

            if isValidWindow {
                validWindows.append(window)
            }
        }

        return (screens, validWindows)
    }

    /// Positions a single window in a tile grid.
    ///
    /// - Parameters:
    ///   - w: The window to position
    ///   - screenFrame: The usable area of the screen
    ///   - size: The size of each tile in the grid
    ///   - column: Which column (0-based) this window belongs in
    ///   - row: Which row (0-based) this window belongs in
    private static func tileWindow(_ w: AccessibilityElement, screenFrame: CGRect, size: CGSize, column: Int, row: Int) {
        print(#function, "called")
        var rect = w.frame

        // TODO: save previous position in history

        // Calculate position based on grid cell
        rect.origin.x = screenFrame.origin.x + size.width * CGFloat(column)
        rect.origin.y = screenFrame.origin.y + size.height * CGFloat(row)
        rect.size = size

        w.setFrame(rect)
    }

    /// Positions a single window in a cascade arrangement.
    ///
    /// In a basic cascade, each window is offset diagonally from the top-left.
    /// With `cascadeParameters`, the cascade direction and window size are adjusted
    /// based on where the front window was located.
    ///
    /// - Parameters:
    ///   - w: The window to position
    ///   - screenFrame: The usable area of the screen
    ///   - delta: The offset (in points) between each window
    ///   - index: This window's position in the cascade (0 = bottom, higher = more on top)
    ///   - cascadeParameters: Optional parameters for smart cascading (used by cascadeActiveApp)
    private static func cascadeWindow(_ w: AccessibilityElement, screenFrame: CGRect, delta: CGFloat, index: Int, cascadeParameters: CascadeActiveAppParameters? = nil) {
        print(#function, "called")
        var rect = w.frame

        // TODO: save previous position in history

        // Default cascade: start from top-left corner, offset each window diagonally
        rect.origin.x = screenFrame.origin.x + delta * CGFloat(index)
        rect.origin.y = screenFrame.origin.y + delta * CGFloat(index)

        // Smart cascade: adjust direction and size based on front window position
        if let cascadeParameters {
            rect.size.width = cascadeParameters.size.width
            rect.size.height = cascadeParameters.size.height

            // If front window was on the right side, cascade from the right
            if cascadeParameters.right {
                rect.origin.x = screenFrame.origin.x + screenFrame.size.width - cascadeParameters.size.width - delta * CGFloat(index)
            }

            // If front window was on the bottom, cascade from the bottom
            if cascadeParameters.bottom {
                // Reverse the index so the topmost window is at the bottom of the screen
                let reversedIndex = cascadeParameters.numWindows - 1 - index
                rect.origin.y = screenFrame.origin.y + screenFrame.size.height - cascadeParameters.size.height - delta * CGFloat(reversedIndex)
            }
        }

        w.setFrame(rect)
        w.bringToFront()
    }
}

// MARK: - CascadeActiveAppParameters

/// Parameters for the "smart" cascade used by `cascadeActiveAppWindowsOnScreen`.
///
/// This struct calculates:
/// - Which corner to cascade from (based on where the front window is)
/// - The maximum size windows can be while still fitting when cascaded
private struct CascadeActiveAppParameters {

    /// Whether to cascade from the right side of the screen
    let right: Bool

    /// Whether to cascade from the bottom of the screen
    let bottom: Bool

    /// Total number of windows being cascaded
    let numWindows: Int

    /// The size to use for each cascaded window (may be smaller than original)
    let size: CGSize

    /// Creates cascade parameters based on the front window's position.
    ///
    /// - Parameters:
    ///   - windowFrame: The frame of the front window (determines cascade direction)
    ///   - screenFrame: The usable screen area
    ///   - numWindows: How many windows will be cascaded
    ///   - size: The desired window size (will be clamped to fit)
    ///   - delta: The offset between cascaded windows
    init(windowFrame: CGRect, screenFrame: CGRect, numWindows: Int, size: CGSize, delta: CGFloat) {
        print(#function, "called")
        // Determine cascade direction based on which half of the screen the window is in
        self.right = windowFrame.midX > screenFrame.midX
        self.bottom = windowFrame.midY > screenFrame.midY
        self.numWindows = numWindows

        // Calculate the maximum size that allows all windows to fit when cascaded
        // We need room for (numWindows - 1) delta offsets
        let totalDeltaSpace = CGFloat(numWindows - 1) * delta
        let maxWidth = screenFrame.width - totalDeltaSpace
        let maxHeight = screenFrame.height - totalDeltaSpace

        // Use the smaller of the desired size and maximum size
        self.size = CGSize(
            width: min(size.width, maxWidth),
            height: min(size.height, maxHeight)
        )
    }
}
