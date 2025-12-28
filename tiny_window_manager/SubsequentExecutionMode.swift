//
//  SubsequentExecutionMode.swift
//  tiny_window_manager
//
//  This file controls what happens when you press the SAME keyboard shortcut multiple times.
//
//  THE PROBLEM THIS SOLVES:
//  ------------------------
//  Imagine you press "Ctrl+Option+Left" to snap a window to the left half of the screen.
//  What should happen if you press it AGAIN while the window is already there?
//
//  Different users want different behaviors:
//  - Some want the window to cycle through different sizes (1/2 → 1/3 → 2/3 → 1/2...)
//  - Some want the window to move to the left half of the NEXT monitor
//  - Some want nothing to happen (the window stays put)
//  - Some want a combination of the above
//
//  This enum defines those different behaviors, and the class stores the user's preference.
//
//  EXAMPLE SCENARIOS:
//  ------------------
//  User has 2 monitors side by side. Window is on Monitor 1, left half.
//  User presses "Left Half" shortcut again.
//
//  Mode: .resize
//    → Window cycles: left 1/2 → left 1/3 → left 2/3 → left 1/2...
//
//  Mode: .acrossMonitor
//    → Window moves to Monitor 2, left half
//
//  Mode: .none
//    → Nothing happens (window stays as left 1/2 on Monitor 1)
//
//  Mode: .acrossAndResize
//    → For left/right actions: moves across monitors
//    → For other actions: cycles through sizes
//
//  Mode: .cycleMonitor
//    → Window cycles through all monitors (Monitor 1 → Monitor 2 → Monitor 1...)
//

import Foundation

// MARK: - Subsequent Execution Mode Enum

/// Defines what happens when the user presses the same window action shortcut repeatedly.
///
/// For example, if a window is already snapped to the left half and the user
/// presses the "left half" shortcut again, this mode determines the behavior.
enum SubsequentExecutionMode: Int {

    /// Cycle through different window sizes.
    ///
    /// Example: left 1/2 → left 1/3 → left 2/3 → left 1/2...
    /// This was the original behavior from the Spectacle app.
    case resize = 0

    /// Move the window to the same position on the next monitor.
    ///
    /// Example: Left half on Monitor 1 → Left half on Monitor 2
    /// Useful for multi-monitor setups where you want quick window transfer.
    case acrossMonitor = 1

    /// Do nothing - the window stays exactly where it is.
    ///
    /// Useful if you find the cycling behavior annoying or confusing.
    case none = 2

    /// Hybrid mode: move across monitors for left/right, resize for everything else.
    ///
    /// - Left/Right actions: Move to next/previous monitor (like .acrossMonitor)
    /// - Top/Bottom/Other actions: Cycle through sizes (like .resize)
    ///
    /// This is a "best of both worlds" option for users who want both behaviors.
    case acrossAndResize = 3

    /// Cycle the window through all monitors in order.
    ///
    /// Example: Monitor 1 → Monitor 2 → Monitor 3 → Monitor 1...
    /// Unlike .acrossMonitor, this creates a continuous loop through all displays.
    case cycleMonitor = 4
}

// MARK: - UserDefaults Wrapper

/// Stores the user's preference for subsequent execution mode in UserDefaults.
///
/// This class conforms to the `Default` protocol, allowing it to be included
/// in the app's settings import/export functionality.
///
/// Usage:
/// ```swift
/// // Access via Defaults class
/// let mode = Defaults.subsequentExecutionMode.value
///
/// // Check capabilities
/// if Defaults.subsequentExecutionMode.resizes {
///     // Handle size cycling
/// }
/// if Defaults.subsequentExecutionMode.traversesDisplays {
///     // Handle monitor traversal
/// }
/// ```
class SubsequentExecutionDefault: Default {

    // MARK: - Properties

    /// The UserDefaults key where this setting is stored.
    public private(set) var key: String = "subsequentExecutionMode"

    /// Prevents saving during initialization.
    /// Without this, setting the initial value would trigger an unnecessary write to UserDefaults.
    private var initialized = false

    /// The current mode. Automatically saves to UserDefaults when changed.
    var value: SubsequentExecutionMode {
        didSet {
            if initialized {
                UserDefaults.standard.set(value.rawValue, forKey: key)
            }
        }
    }

    // MARK: - Initialization

    /// Creates the default, loading any existing value from UserDefaults.
    /// Falls back to `.resize` (the Spectacle-style behavior) if no value is stored.
    init() {
        let storedIntValue = UserDefaults.standard.integer(forKey: key)
        value = SubsequentExecutionMode(rawValue: storedIntValue) ?? .resize
        initialized = true
    }

    // MARK: - Convenience Properties

    /// Returns true if this mode includes window size cycling.
    ///
    /// True for: `.resize`, `.acrossAndResize`
    /// False for: `.acrossMonitor`, `.none`, `.cycleMonitor`
    var resizes: Bool {
        switch value {
        case .resize, .acrossAndResize:
            return true
        default:
            return false
        }
    }

    /// Returns true if this mode includes moving windows across displays.
    ///
    /// True for: `.acrossMonitor`, `.acrossAndResize`
    /// False for: `.resize`, `.none`, `.cycleMonitor`
    ///
    /// Note: `.cycleMonitor` is NOT included here because it has different
    /// traversal logic (cycles through ALL monitors vs. just moving to "next").
    var traversesDisplays: Bool {
        switch value {
        case .acrossMonitor, .acrossAndResize:
            return true
        default:
            return false
        }
    }

    // MARK: - Import/Export (Default Protocol)

    /// Load a value from an imported settings file.
    func load(from codable: CodableDefault) {
        if let intValue = codable.int,
           let mode = SubsequentExecutionMode(rawValue: intValue) {
            value = mode
        }
    }

    /// Convert the current value to a format suitable for export.
    func toCodable() -> CodableDefault {
        return CodableDefault(int: value.rawValue)
    }
}
