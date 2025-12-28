//
//  WindowMover.swift
//  tiny_window_manager, Ported from Spectacle
//
//  This file defines the protocol (interface) that all window movers must follow.
//  Think of a protocol like a contract - any class that "conforms" to this protocol
//  promises to implement the required methods.
//
//  The window manager uses multiple movers in sequence to handle different edge cases:
//  1. StandardWindowMover     - Does the basic move/resize
//  2. QuantizedWindowMover    - Handles apps that resize in steps (like Terminal)
//  3. CenteringFixedSizedWindowMover - Centers windows that can't resize
//  4. BestEffortWindowMover   - Fixes windows that overflow off-screen
//

import Foundation

// MARK: - WindowMover Protocol

/// A protocol that defines how to move and resize windows.
///
/// This uses the "Strategy Pattern" - instead of having one giant class with
/// lots of if/else statements for different window types, we have multiple
/// small classes that each handle one specific case. The window manager runs
/// them in sequence, and each one makes small adjustments as needed.
///
/// ## How It Works
///
/// When the user triggers a window action (like "snap to left half"):
/// 1. The system calculates the target rectangle
/// 2. Each WindowMover gets a chance to adjust the window
/// 3. The movers run in order, each one potentially tweaking the position/size
///
/// ## Implementing a New Mover
///
/// To create a new window mover, make a class that conforms to this protocol:
///
/// ```swift
/// class MyCustomMover: WindowMover {
///     func moveWindowRect(_ windowRect: CGRect, ...) {
///         // Your custom logic here
///     }
/// }
/// ```
///
/// ## Existing Movers
///
/// - `StandardWindowMover`: Basic implementation that just sets the frame
/// - `QuantizedWindowMover`: Handles windows that snap to grid sizes
/// - `CenteringFixedSizedWindowMover`: Centers windows that can't resize
/// - `BestEffortWindowMover`: Keeps windows from going off-screen
protocol WindowMover {

    /// Moves and/or resizes a window based on the target rectangle.
    ///
    /// Each mover implementation decides what adjustments (if any) to make.
    /// Some movers might do nothing if their special case doesn't apply.
    ///
    /// - Parameters:
    ///   - windowRect: The target rectangle where we want the window to go.
    ///                 This is the "ideal" position calculated by the window action.
    ///
    ///   - frameOfScreen: The full bounds of the screen, including areas covered
    ///                    by the menu bar. Origin is at bottom-left (Cocoa coordinates).
    ///
    ///   - visibleFrameOfScreen: The usable area of the screen, excluding the menu bar
    ///                           and Dock. This is where windows should typically stay.
    ///
    ///   - frontmostWindowElement: The window to move/resize. This is an accessibility
    ///                             element that lets us control the window programmatically.
    ///                             May be nil if no window is available.
    ///
    ///   - action: The window action being performed (e.g., "leftHalf", "maximize").
    ///             Some movers use this to decide whether to apply their logic.
    ///             May be nil for generic move operations.
    func moveWindowRect(
        _ windowRect: CGRect,
        frameOfScreen: CGRect,
        visibleFrameOfScreen: CGRect,
        frontmostWindowElement: AccessibilityElement?,
        action: WindowAction?
    )
}
