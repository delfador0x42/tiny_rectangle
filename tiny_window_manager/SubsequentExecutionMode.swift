//
//  SubsequentExecutionMode.swift
//  tiny_window_manager
//
//  UserDefaults wrapper for SubsequentExecutionMode preferences.
//  The SubsequentExecutionMode enum itself is defined in WindowManagerCore.
//

import Foundation
import WindowManagerCore

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
