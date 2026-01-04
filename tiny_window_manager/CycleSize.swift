//
//  CycleSize.swift
//  tiny_window_manager
//
//  UserDefaults wrapper for CycleSize preferences.
//  The CycleSize enum itself is defined in WindowManagerCore.
//

import Foundation
import WindowManagerCore

// MARK: - UserDefaults Wrapper

/// Stores the user's selected cycle sizes in UserDefaults.
///
/// This class handles the conversion between `Set<CycleSize>` (convenient for code)
/// and a single integer (efficient for storage).
///
/// Usage:
/// ```swift
/// // Access via Defaults class
/// let selectedSizes = Defaults.selectedCycleSizes.value
///
/// // Check if a specific size is enabled
/// if selectedSizes.contains(.twoThirds) {
///     // 2/3 size is part of the cycle
/// }
///
/// // Change the selection (automatically saved)
/// Defaults.selectedCycleSizes.value = [.oneHalf, .twoThirds]
/// ```
class CycleSizesDefault: Default {

    /// The UserDefaults key where this setting is stored.
    public private(set) var key: String = "selectedCycleSizes"

    /// Prevents saving during initialization.
    private var initialized = false

    /// The current set of selected cycle sizes.
    /// Automatically saves to UserDefaults (as a bitmask) when changed.
    var value: Set<CycleSize> {
        didSet {
            if initialized {
                UserDefaults.standard.set(value.toBits(), forKey: key)
            }
        }
    }

    /// Creates the default, loading any existing value from UserDefaults.
    init() {
        let storedBits = UserDefaults.standard.integer(forKey: key)
        value = CycleSize.fromBits(bits: storedBits)
        initialized = true
    }

    /// Load a value from an imported settings file.
    func load(from codable: CodableDefault) {
        if let bits = codable.int {
            value = CycleSize.fromBits(bits: bits)
        }
    }

    /// Convert the current value to a format suitable for export.
    func toCodable() -> CodableDefault {
        return CodableDefault(int: value.toBits())
    }
}
