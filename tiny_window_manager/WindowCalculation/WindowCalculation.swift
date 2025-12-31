import Cocoa

// MARK: - Protocol

/// A type that can calculate window rectangles for positioning.
///
/// All window positioning logic in this app conforms to this protocol.
/// The main method is `calculateRect`, which determines where a window should be placed.
protocol Calculation {

    /// Calculates the full result including screen and action information.
    func calculate(_ params: WindowCalculationParameters) -> WindowCalculationResult?

    /// Calculates just the rectangle for window positioning.
    /// This is the method that subclasses typically override.
    func calculateRect(_ params: RectCalculationParameters) -> RectResult
}

// MARK: - Base Class

/// The base class for all window position calculations.
///
/// Subclasses override `calculateRect` to implement specific positioning logic
/// (e.g., left half, upper right, center third, etc.).
///
/// This class provides:
/// - Default implementation of `calculate` that wraps `calculateRect`
/// - Helper methods for common geometric operations
class WindowCalculation: Calculation {

    /// Main entry point: calculates window position and wraps it in a full result.
    ///
    /// Calls `calculateRect` (which subclasses override) and packages the result
    /// with screen and action information.
    func calculate(_ params: WindowCalculationParameters) -> WindowCalculationResult? {
        print(#function, "called")
        let rectResult = calculateRect(params.asRectParams())

        // A null rect means the calculation couldn't produce a valid result
        if rectResult.rect.isNull {
            return nil
        }

        return WindowCalculationResult(
            rect: rectResult.rect,
            screen: params.usableScreens.currentScreen,
            resultingAction: params.action,
            resultingSubAction: rectResult.subAction
        )
    }

    /// Override this method in subclasses to implement specific positioning logic.
    ///
    /// The default implementation returns a null rect (no positioning).
    func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        print(#function, "called")
        return RectResult(.null)
    }

    // MARK: - Helper Methods

    /// Checks if `rect2` is centered within `rect1`.
    ///
    /// Returns true if:
    /// - `rect1` fully contains `rect2`
    /// - The center points are within 1 pixel of each other (allows for rounding)
    func rectCenteredWithinRect(_ rect1: CGRect, _ rect2: CGRect) -> Bool {
        print(#function, "called")
        let centeredMidX = abs(rect2.midX - rect1.midX) <= 1.0
        let centeredMidY = abs(rect2.midY - rect1.midY) <= 1.0
        return rect1.contains(rect2) && centeredMidX && centeredMidY
    }

    /// Checks if `rect1` would fit inside `rect2` (comparing dimensions only, not position).
    func rectFitsWithinRect(rect1: CGRect, rect2: CGRect) -> Bool {
        print(#function, "called")
        let widthFits = rect1.width <= rect2.width
        let heightFits = rect1.height <= rect2.height
        return widthFits && heightFits
    }

    /// Checks if the user is repeating the same window action.
    ///
    /// This is used to implement cycling behavior (e.g., pressing "left half" multiple times
    /// cycles through 1/2 → 2/3 → 1/3 widths).
    func isRepeatedCommand(_ params: WindowCalculationParameters) -> Bool {
        print(#function, "called")
        guard let lastAction = params.lastAction,
              lastAction.action == params.action else {
            return false
        }

        // Compare the last rect (after screen coordinate normalization) with current window
        let normalizedLastRect = lastAction.rect.screenFlipped
        return normalizedLastRect == params.window.rect
    }
}

// MARK: - Data Structures

/// Represents a window with its identifier and current position/size.
struct Window {
    let id: CGWindowID
    let rect: CGRect
}

/// Input parameters for a full window calculation.
///
/// Contains all the context needed to calculate a window position:
/// - The window being positioned
/// - Available screens
/// - The action being performed (e.g., leftHalf, maximize)
/// - The last action (used for cycling behavior)
struct WindowCalculationParameters {
    let window: Window
    let usableScreens: UsableScreens
    let action: WindowAction
    let lastAction: tiny_window_managerAction?
    let ignoreTodo: Bool

    /// Converts to the simpler RectCalculationParameters used by calculateRect.
    func asRectParams(visibleFrame: CGRect? = nil, differentAction: WindowAction? = nil) -> RectCalculationParameters {
        print(#function, "called")
        return RectCalculationParameters(
            window: window,
            visibleFrameOfScreen: visibleFrame ?? usableScreens.currentScreen.adjustedVisibleFrame(ignoreTodo),
            action: differentAction ?? action,
            lastAction: lastAction
        )
    }

    /// Creates a copy with a different action (useful for delegation between calculations).
    func withDifferentAction(_ differentAction: WindowAction) -> WindowCalculationParameters {
        print(#function, "called")
        return .init(
            window: window,
            usableScreens: usableScreens,
            action: differentAction,
            lastAction: lastAction,
            ignoreTodo: ignoreTodo
        )
    }
}

/// Simplified parameters for rect-only calculations.
///
/// This is what gets passed to `calculateRect` - just the essentials needed
/// to compute the window rectangle.
struct RectCalculationParameters {
    /// The window being positioned
    let window: Window

    /// The usable area of the screen (excludes menu bar, dock, etc.)
    let visibleFrameOfScreen: CGRect

    /// The action being performed
    let action: WindowAction

    /// The last action (used for cycling behavior)
    let lastAction: tiny_window_managerAction?
}

/// The result of a rect calculation.
///
/// Contains the calculated rectangle and optional action/sub-action info
/// for tracking what was done (used by cycling logic).
struct RectResult {
    /// The calculated window rectangle
    let rect: CGRect

    /// Optional: the action that produced this result (for cycling)
    let resultingAction: WindowAction?

    /// Optional: sub-action for more granular tracking (e.g., topLeftSixthLandscape)
    let subAction: SubWindowAction?

    init(_ rect: CGRect, resultingAction: WindowAction? = nil, subAction: SubWindowAction? = nil) {
        print(#function, "called")
        self.rect = rect
        self.resultingAction = resultingAction
        self.subAction = subAction
    }
}

/// The complete result of a window calculation.
///
/// Includes the rectangle plus context about which screen and action produced it.
struct WindowCalculationResult {
    /// The calculated window rectangle
    var rect: CGRect

    /// The screen the window should be on
    let screen: NSScreen

    /// The action that was performed
    let resultingAction: WindowAction

    /// Optional sub-action for granular tracking
    let resultingSubAction: SubWindowAction?

    /// Optional: the screen frame used for the calculation
    let resultingScreenFrame: CGRect?

    init(rect: CGRect,
         screen: NSScreen,
         resultingAction: WindowAction,
         resultingSubAction: SubWindowAction? = nil,
         resultingScreenFrame: CGRect? = nil) {
        print(#function, "called")
        self.rect = rect
        self.screen = screen
        self.resultingAction = resultingAction
        self.resultingSubAction = resultingSubAction
        self.resultingScreenFrame = resultingScreenFrame
    }
}

// MARK: - Factory

/// Factory that provides calculation instances for each window action.
/// Most calculations now handled by SimpleCalculation in SimpleWindowCalculation.swift.
class WindowCalculationFactory {
    /// For moving windows between displays
    static let nextPrevDisplayCalculation = NextPrevDisplayCalculation()

    /// For specified/custom window positions
    static let specifiedCalculation = SpecifiedCalculation()
}
