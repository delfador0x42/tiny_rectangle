//
//  SubsequentExecutionMode.swift
//  WindowManagerCore
//
//  Defines what happens when the user presses the same window action shortcut repeatedly.
//

import Foundation

// MARK: - Subsequent Execution Mode Enum

/// Defines what happens when the user presses the same window action shortcut repeatedly.
///
/// For example, if a window is already snapped to the left half and the user
/// presses the "left half" shortcut again, this mode determines the behavior.
public enum SubsequentExecutionMode: Int, Sendable {

    /// Cycle through different window sizes.
    ///
    /// Example: left 1/2 → left 1/3 → left 2/3 → left 1/2...
    case resize = 0

    /// Move the window to the same position on the next monitor.
    ///
    /// Example: Left half on Monitor 1 → Left half on Monitor 2
    case acrossMonitor = 1

    /// Do nothing - the window stays exactly where it is.
    case none = 2

    /// Hybrid mode: move across monitors for left/right, resize for everything else.
    ///
    /// - Left/Right actions: Move to next/previous monitor
    /// - Top/Bottom/Other actions: Cycle through sizes
    case acrossAndResize = 3

    /// Cycle the window through all monitors in order.
    ///
    /// Example: Monitor 1 → Monitor 2 → Monitor 3 → Monitor 1...
    case cycleMonitor = 4

    // MARK: - Convenience Properties

    /// Returns true if this mode includes window size cycling.
    public var resizes: Bool {
        switch self {
        case .resize, .acrossAndResize:
            return true
        default:
            return false
        }
    }

    /// Returns true if this mode includes moving windows across displays.
    public var traversesDisplays: Bool {
        switch self {
        case .acrossMonitor, .acrossAndResize:
            return true
        default:
            return false
        }
    }
}
