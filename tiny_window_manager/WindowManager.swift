//
//  WindowManager.swift
//  tiny_window_manager, Ported from Spectacle
//
//

import Cocoa

// ============================================================================
// MARK: - WindowManager
// ============================================================================
// This is the CORE CLASS of the entire app - the "brain" that orchestrates
// all window positioning operations.
//
// When you press a keyboard shortcut (like Ctrl+Opt+Left for "left half"),
// eventually this class's execute() method gets called to actually move
// and resize the window.
//
// Key responsibilities:
// 1. Detect which screen(s) are available
// 2. Get the frontmost window that needs to be moved
// 3. Calculate where the window should go (using WindowCalculation classes)
// 4. Actually move/resize the window (using WindowMover classes)
// 5. Keep track of history for undo/restore functionality
// ============================================================================

class WindowManager {

    // ------------------------------------------------------------------------
    // MARK: - Properties
    // ------------------------------------------------------------------------

    // Detects which monitors/screens are connected and which one the window is on
    private let screenDetection = ScreenDetection()

    // "Chain of Responsibility" pattern for moving windows.
    // We try the first mover, and if it fails, fall back to the next one.
    // This handles edge cases where some windows don't respond to standard APIs.

    // For normal, resizable windows: try StandardWindowMover first, then BestEffort as fallback
    private let standardWindowMoverChain: [WindowMover]

    // For fixed-size windows (like dialogs): use a special centering mover
    private let fixedSizeWindowMoverChain: [WindowMover]

    // ------------------------------------------------------------------------
    // MARK: - Initialization
    // ------------------------------------------------------------------------

    init() {
        print(#function, "called")
        // Set up the chain of window movers for normal windows
        standardWindowMoverChain = [
            StandardWindowMover(),      // Primary: uses standard Accessibility APIs
            BestEffortWindowMover()     // Fallback: tries alternative approaches
        ]

        // Set up the chain for fixed-size windows (can't be resized, only moved)
        fixedSizeWindowMoverChain = [
            CenteringFixedSizedWindowMover(),  // Centers fixed-size windows in the target area
            BestEffortWindowMover()            // Fallback
        ]
    }

    // ------------------------------------------------------------------------
    // MARK: - Action History Recording
    // ------------------------------------------------------------------------
    // This method saves what action was just performed on a window.
    // This history is used for:
    // 1. "Restore" functionality - undo to previous position
    // 2. "Cycling" behavior - pressing same shortcut repeatedly cycles through options
    //    (e.g., left-half -> left-third -> left-two-thirds -> left-half...)
    // ------------------------------------------------------------------------

    private func recordAction(windowId: CGWindowID, resultingRect: CGRect, action: WindowAction, subAction: SubWindowAction?) {
        print(#function, "called")
        // Check if this is the same action being repeated
        let newCount: Int
        if let lasttiny_window_managerAction = AppDelegate.windowHistory.lasttiny_window_managerActions[windowId], lasttiny_window_managerAction.action == action {
            // Same action repeated - increment the count (used for cycling)
            newCount = lasttiny_window_managerAction.count + 1
        } else {
            // Different action - start fresh
            newCount = 1
        }

        // Store this action in history, keyed by the window's unique ID
        AppDelegate.windowHistory.lasttiny_window_managerActions[windowId] = tiny_window_managerAction(
            action: action,
            subAction: subAction,
            rect: resultingRect,  // Save resulting position so we can detect if user moved it manually
            count: newCount
        )
    }

    // ------------------------------------------------------------------------
    // MARK: - Main Execute Method (THE BIG ONE!)
    // ------------------------------------------------------------------------
    // This is the main entry point - called whenever a window action is triggered.
    // It coordinates the entire process of moving/resizing a window.
    //
    // Parameters contains:
    // - action: What to do (leftHalf, maximize, center, etc.)
    // - windowElement: Optional specific window (if nil, uses frontmost)
    // - screen: Optional specific screen (if nil, auto-detects)
    // - source: How was this triggered (keyboard, menu, drag-to-snap, etc.)
    // ------------------------------------------------------------------------

    func execute(_ parameters: ExecutionParameters) {
        print(#function, "called")

        // ====================================================================
        // STEP 1: Get the window we're going to manipulate
        // ====================================================================
        // Try to get the window from parameters, or fall back to frontmost window.
        // Also get the window's unique ID (CGWindowID) for tracking in history.

        guard let frontmostWindowElement = parameters.windowElement ?? AccessibilityElement.getFrontWindowElement(),
              let windowId = parameters.windowId ?? frontmostWindowElement.getWindowId()
        else {
            // No window found - play error sound and bail out
            NSSound.beep()
            return
        }

        let action = parameters.action

        // ====================================================================
        // STEP 2: Handle "Restore" action specially
        // ====================================================================
        // "Restore" reverts a window to its position before any tiny_window_manager actions.
        // This is different from other actions - it just looks up saved position and applies it.

        if action == .restore {
            if let restoreRect = AppDelegate.windowHistory.restoreRects[windowId] {
                // Found saved position - restore it
                frontmostWindowElement.setFrame(restoreRect)
            }
            // Clear the action history for this window
            AppDelegate.windowHistory.lasttiny_window_managerActions.removeValue(forKey: windowId)
            return
        }

        // ====================================================================
        // STEP 3: Detect available screens/monitors
        // ====================================================================
        // We need to know what screens are available and which one the window is on.
        // User can choose cursor-based detection (which screen has the mouse)
        // or window-based detection (which screen has the window).

        var screens: UsableScreens?
        if let screen = parameters.screen {
            // Specific screen was provided - use it
            screens = UsableScreens(currentScreen: screen, numScreens: 1)
        } else {
            // Auto-detect based on user preference
            screens = Defaults.useCursorScreenDetection.enabled
            ? screenDetection.detectScreensAtCursor()      // Use screen where mouse cursor is
            : screenDetection.detectScreens(using: frontmostWindowElement)  // Use screen where window is
        }

        guard let usableScreens = screens else {
            NSSound.beep()
            Logger.log("Unable to obtain usable screens")
            return
        }

        // ====================================================================
        // STEP 4: Get current window position and check history
        // ====================================================================

        let currentWindowRect: CGRect = frontmostWindowElement.frame

        // Look up what action was last performed on this window
        var lasttiny_window_managerAction = AppDelegate.windowHistory.lasttiny_window_managerActions[windowId]

        // Check if the user manually moved/resized the window since our last action.
        // If the current position doesn't match what we recorded, the user moved it.
        let windowMovedExternally = currentWindowRect != lasttiny_window_managerAction?.rect

        if windowMovedExternally {
            // User moved the window manually - clear our history
            // This resets cycling behavior and updates the "restore" position
            lasttiny_window_managerAction = nil
            AppDelegate.windowHistory.lasttiny_window_managerActions.removeValue(forKey: windowId)
        }

        // ====================================================================
        // STEP 5: Save current position for "Restore" feature
        // ====================================================================
        // Before we move the window, save its current position so user can restore it later.
        // Only save if we don't already have a saved position, or if user moved it manually.

        if parameters.updateRestoreRect {
            if AppDelegate.windowHistory.restoreRects[windowId] == nil
                || windowMovedExternally {
                AppDelegate.windowHistory.restoreRects[windowId] = currentWindowRect
            }
        }

        // ====================================================================
        // STEP 6: Validate the window can be snapped
        // ====================================================================
        // Some windows can't be moved/resized (sheets, invalid frames, etc.)

        let ignoreTodo = TodoManager.isTodoWindow(windowId)

        if frontmostWindowElement.isSheet == true           // Sheets are attached to parent windows
            || currentWindowRect.isNull                      // Invalid window frame
            || usableScreens.frameOfCurrentScreen.isNull     // Invalid screen frame
            || usableScreens.currentScreen.adjustedVisibleFrame(ignoreTodo).isNull {
            NSSound.beep()
            Logger.log("Window is not snappable or usable screen is not valid")
            return
        }

        // ====================================================================
        // STEP 7: Calculate the new window position
        // ====================================================================
        // This is where the magic happens! Each action (leftHalf, maximize, etc.)
        // has a corresponding calculation class that figures out the target rectangle.

        // Normalize the rect - macOS has flipped coordinates (0,0 at bottom-left)
        // but some calculations expect 0,0 at top-left
        let currentNormalizedRect = currentWindowRect.screenFlipped
        let currentWindow = Window(id: windowId, rect: currentNormalizedRect)

        // Look up the calculation class for this action (e.g., LeftHalfCalculation)
        let windowCalculation = WindowCalculationFactory.calculationsByAction[action]

        // Package up all the info the calculation needs
        let calculationParams = WindowCalculationParameters(window: currentWindow, usableScreens: usableScreens, action: action, lastAction: lasttiny_window_managerAction, ignoreTodo: ignoreTodo)

        // Run the calculation to get the target rectangle
        guard var calcResult = windowCalculation?.calculate(calculationParams) else {
            NSSound.beep()
            Logger.log("Nil calculation result")
            return
        }

        // ====================================================================
        // STEP 8: Apply gaps (spacing between windows and screen edges)
        // ====================================================================
        // User can configure gaps so windows don't touch each other or screen edges.

        let gapsApplicable = calcResult.resultingAction.gapsApplicable

        if Defaults.gapSize.value > 0, gapsApplicable != .none {
            let gapSharedEdges = calcResult.resultingSubAction?.gapSharedEdge ?? calcResult.resultingAction.gapSharedEdge

            // Shrink the rectangle to account for gaps
            calcResult.rect = GapCalculation.applyGaps(calcResult.rect, dimension: gapsApplicable, sharedEdges: gapSharedEdges, gapSize: Defaults.gapSize.value)
        }

        // ====================================================================
        // STEP 9: Check if window is already in the target position
        // ====================================================================
        // If window is already where we want it, don't do anything
        // (but still record the action for cycling purposes)

        if currentNormalizedRect.equalTo(calcResult.rect) {
            Logger.log("Current frame is equal to new frame")

            recordAction(windowId: windowId, resultingRect: currentWindowRect, action: calcResult.resultingAction, subAction: calcResult.resultingSubAction)

            return
        }

        // ====================================================================
        // STEP 10: Prepare and apply the window move/resize
        // ====================================================================

        let visibleFrameOfDestinationScreen = calcResult.resultingScreenFrame ?? calcResult.screen.adjustedVisibleFrame(ignoreTodo)

        // Check if window can be resized, or if it's a fixed-size window/dialog
        let isFixedSize = (!frontmostWindowElement.isResizable() && action.resizes) || frontmostWindowElement.isSystemDialog == true

        // Package up all the result parameters
        let resultParameters = ResultParameters(windowId: windowId,
                                                action: action,
                                                windowElement: frontmostWindowElement,
                                                calcResult: calcResult,
                                                usableScreens: usableScreens,
                                                visibleFrameOfScreen: visibleFrameOfDestinationScreen,
                                                source: parameters.source,
                                                isFixedSize: isFixedSize)

        // Actually move/resize the window!
        var resultingRect = apply(result: resultParameters)

        // ====================================================================
        // STEP 11: Handle cross-display moves (moving window to another monitor)
        // ====================================================================
        // Moving windows between displays can be tricky - sometimes macOS doesn't
        // apply the size correctly on the first try, so we may need multiple attempts.

        let isMovedAcrossDisplays = usableScreens.currentScreen != calcResult.screen
        if isMovedAcrossDisplays {
            if calcResult.rect.height != resultingRect.height {
                Logger.log("Window size wasn't applied perfectly across displays. Trying again.")
                resultingRect = apply(result: resultParameters)

                if calcResult.rect.height != resultingRect.height {
                    Logger.log("Final attempt to adjust across displays.")
                    // Last resort: wait a bit and try again asynchronously
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(25)) { [weak self] in
                        guard let self else { return }
                        let finalRect = self.apply(result: resultParameters)
                        self.windowMovedAcrossDisplays(windowElement: frontmostWindowElement, resultingRect: finalRect)
                        self.postProcess(result: resultParameters, resultingRect: finalRect)
                    }
                    return
                }
            }
            // Bring window to front and optionally move cursor to new display
            windowMovedAcrossDisplays(windowElement: frontmostWindowElement, resultingRect: resultingRect)
        }

        // Record the action and do any cleanup
        postProcess(result: resultParameters, resultingRect: resultingRect)
    }

    // ------------------------------------------------------------------------
    // MARK: - Apply Window Move/Resize
    // ------------------------------------------------------------------------
    // This method actually moves and resizes the window using the mover chain.
    // Returns: The window's actual rect after the move (may differ from target
    //          if window has minimum size constraints, etc.)
    // ------------------------------------------------------------------------

    func apply(result: ResultParameters) -> CGRect {
        print(#function, "called")
        // Choose the appropriate mover chain based on whether window is fixed-size
        let windowMoverChain = result.isFixedSize
        ? fixedSizeWindowMoverChain
        : standardWindowMoverChain

        // Convert back to screen coordinates (flip Y axis back)
        let newRect = result.calcResult.rect.screenFlipped

        // Try each mover in the chain until one succeeds
        for windowMover in windowMoverChain {
            windowMover.moveWindowRect(newRect,
                                       frameOfScreen: result.usableScreens.frameOfCurrentScreen,
                                       visibleFrameOfScreen: result.visibleFrameOfScreen,
                                       frontmostWindowElement: result.windowElement,
                                       action: result.action)
        }

        // Return the window's actual frame after moving
        return result.windowElement.frame
    }

    // ------------------------------------------------------------------------
    // MARK: - Cross-Display Handling
    // ------------------------------------------------------------------------
    // Called when a window is moved to a different monitor.
    // Brings the window to front and optionally moves the mouse cursor too.
    // ------------------------------------------------------------------------

    func windowMovedAcrossDisplays(windowElement: AccessibilityElement, resultingRect: CGRect) {
        print(#function, "called")
        // Bring the window to the front on the new display
        windowElement.bringToFront(force: true)

        // If user enabled "move cursor with window", warp the mouse to the new display
        if Defaults.moveCursorAcrossDisplays.userEnabled {
            CGWarpMouseCursorPosition(resultingRect.centerPoint)
        }
    }

    // ------------------------------------------------------------------------
    // MARK: - Post-Processing
    // ------------------------------------------------------------------------
    // Called after a window action completes successfully.
    // Handles cursor movement and action recording.
    // ------------------------------------------------------------------------

    func postProcess(result: ResultParameters, resultingRect: CGRect) {
        print(#function, "called")
        let calcResult = result.calcResult

        // Optionally move cursor to center of window (only for keyboard shortcuts)
        if Defaults.moveCursor.userEnabled, result.source == .keyboardShortcut {
            CGWarpMouseCursorPosition(resultingRect.centerPoint)
        }

        // Record this action in history (for cycling and restore functionality)
        recordAction(windowId: result.windowId, resultingRect: resultingRect, action: calcResult.resultingAction, subAction: calcResult.resultingSubAction)

        // Logging for debugging (only if logging is enabled)
        if Logger.logging {
            var logItems = ["\(result.action.name)",
                            "display: \(result.visibleFrameOfScreen.debugDescription)",
                            "calculatedRect: \(result.calcResult.rect.screenFlipped.debugDescription)",
                            "resultRect: \(resultingRect.debugDescription)",
                            "srcScreen: \(result.usableScreens.currentScreen.localizedName)",
                            "destScreen: \(calcResult.screen.localizedName)"]
            if let resultScreens = screenDetection.detectScreens(using: result.windowElement) {
                logItems.append("resultScreen: \(resultScreens.currentScreen.localizedName)")
            }
            Logger.log(logItems.joined(separator: ", "))
        }
    }

    // ------------------------------------------------------------------------
    // MARK: - ResultParameters Struct
    // ------------------------------------------------------------------------
    // A container for all the data needed when applying a window action.
    // Bundles together window info, calculation results, and screen info.
    // ------------------------------------------------------------------------

    struct ResultParameters {
        let windowId: CGWindowID              // Unique identifier for the window
        let action: WindowAction              // The action being performed (leftHalf, etc.)
        let windowElement: AccessibilityElement  // The window we're manipulating
        let calcResult: WindowCalculationResult  // Results from the calculation
        let usableScreens: UsableScreens      // Info about available screens
        let visibleFrameOfScreen: CGRect      // Usable area of target screen (minus dock, menubar)
        let source: ExecutionSource           // How was this triggered (keyboard, menu, etc.)
        let isFixedSize: Bool                 // Is this a non-resizable window?
    }
}

// ============================================================================
// MARK: - tiny_window_managerAction Struct
// ============================================================================
// Represents a window action that was performed.
// Stored in history to enable:
// 1. Detecting if user manually moved the window (by comparing rect)
// 2. Cycling through variations when same action is repeated
// 3. Restore/undo functionality
// ============================================================================

struct tiny_window_managerAction {
    let action: WindowAction      // What action was performed
    let subAction: SubWindowAction?  // More specific variation (e.g., which third)
    let rect: CGRect              // The resulting window position
    let count: Int                // How many times this action was repeated
}

// ============================================================================
// MARK: - ExecutionParameters Struct
// ============================================================================
// Input parameters for executing a window action.
// This is what gets passed to execute() when a shortcut is pressed.
// ============================================================================

struct ExecutionParameters {
    let action: WindowAction           // What to do (leftHalf, maximize, etc.)
    let updateRestoreRect: Bool        // Should we save current position for restore?
    let screen: NSScreen?              // Optional: specific screen to use
    let windowElement: AccessibilityElement?  // Optional: specific window to manipulate
    let windowId: CGWindowID?          // Optional: window ID if already known
    let source: ExecutionSource        // How was this triggered?

    init(_ action: WindowAction, updateRestoreRect: Bool = true, screen: NSScreen? = nil, windowElement: AccessibilityElement? = nil, windowId: CGWindowID? = nil, source: ExecutionSource = .keyboardShortcut) {
        print(#function, "called")
        self.action = action
        self.updateRestoreRect = updateRestoreRect
        self.screen = screen
        self.windowElement = windowElement
        self.windowId = windowId
        self.source = source
    }
}

// ============================================================================
// MARK: - ExecutionSource Enum
// ============================================================================
// Tracks HOW a window action was triggered.
// This affects behavior - e.g., cursor only moves for keyboard shortcuts,
// not for drag-to-snap operations.
// ============================================================================

enum ExecutionSource {
    case keyboardShortcut  // User pressed a keyboard shortcut
    case dragToSnap        // User dragged window to screen edge
    case menuItem          // User clicked a menu item
    case url               // Triggered via URL scheme (external automation)
    case titleBar          // User double-clicked the title bar
}
