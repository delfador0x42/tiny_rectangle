//
//  CycleSize.swift
//  tiny_window_manager
//
//  This file defines the different sizes a window can cycle through when pressing
//  the same keyboard shortcut repeatedly.
//
//  WHAT IS SIZE CYCLING?
//  ---------------------
//  When you press a shortcut like "Left Half" multiple times, the window can
//  cycle through different widths instead of staying at exactly 1/2:
//
//      Press 1: Window becomes left 1/2 of screen
//      Press 2: Window becomes left 2/3 of screen
//      Press 3: Window becomes left 1/3 of screen
//      Press 4: Window becomes left 1/2 again (cycle repeats)
//
//  Users can customize WHICH sizes are included in the cycle. Some users only
//  want 1/2 and 2/3. Others want all five sizes. This file handles that.
//
//  HOW SIZES ARE STORED:
//  ---------------------
//  Instead of storing an array of sizes, we use BITWISE encoding to pack
//  multiple boolean flags into a single integer. This is efficient and
//  works well with UserDefaults.
//
//  Each size has a "bit position" (its rawValue):
//    - twoThirds    = bit 0 (value 1)
//    - oneHalf      = bit 1 (value 2)
//    - oneThird     = bit 2 (value 4)
//    - oneQuarter   = bit 3 (value 8)
//    - threeQuarters = bit 4 (value 16)
//
//  So if the user has selected 1/2 and 2/3, we store: 2 + 1 = 3
//  If they selected 1/2, 1/3, and 2/3, we store: 2 + 4 + 1 = 7
//
//  CYCLE ORDER:
//  ------------
//  The cycle doesn't go in simple order (1/4 → 1/3 → 1/2 → 2/3 → 3/4).
//  Instead, it starts at 1/2 (the most common size), goes UP to larger sizes,
//  then wraps around to smaller sizes:
//
//      1/2 → 2/3 → 3/4 → 1/4 → 1/3 → (back to 1/2)
//
//  This feels more natural because 1/2 is the "default" and users usually
//  want slightly larger (2/3) before going to smaller sizes.
//

import Foundation

// MARK: - Cycle Size Enum

/// Represents a fraction of the screen width/height that a window can occupy.
///
/// When the user presses a window action shortcut repeatedly, the window
/// cycles through these sizes (if cycling is enabled).
enum CycleSize: Int, CaseIterable {

    // IMPORTANT: The rawValue determines the BIT POSITION for storage.
    // Don't change these values or you'll break existing user preferences!

    /// Two-thirds (⅔) of the screen - stored in bit 0
    case twoThirds = 0

    /// One-half (½) of the screen - stored in bit 1
    case oneHalf = 1

    /// One-third (⅓) of the screen - stored in bit 2
    case oneThird = 2

    /// One-quarter (¼) of the screen - stored in bit 3
    case oneQuarter = 3

    /// Three-quarters (¾) of the screen - stored in bit 4
    case threeQuarters = 4

    // MARK: - Bitwise Conversion

    /// Converts a bitmask integer back into a Set of CycleSizes.
    ///
    /// Example:
    /// ```swift
    /// let bits = 7  // Binary: 00111
    /// let sizes = CycleSize.fromBits(bits: bits)
    /// // sizes = {.twoThirds, .oneHalf, .oneThird}
    /// ```
    ///
    /// - Parameter bits: An integer where each bit represents whether a size is selected.
    /// - Returns: A Set containing all the sizes whose bits are set to 1.
    static func fromBits(bits: Int) -> Set<CycleSize> {
        print(#function, "called")
        return Set(
            Self.allCases.filter { cycleSize in
                // Check if the bit at position `rawValue` is set to 1
                // Example: for oneHalf (rawValue=1), we check if bit 1 is set
                // (bits >> 1) shifts right by 1, then & 1 checks the lowest bit
                let bitPosition = cycleSize.rawValue
                let bitIsSet = (bits >> bitPosition) & 1 == 1
                return bitIsSet
            }
        )
    }

    // MARK: - Defaults and Ordering

    /// The size that appears first in the cycle and cannot be disabled.
    /// One-half (½) is the most commonly used size.
    static var firstSize = CycleSize.oneHalf

    /// The default set of sizes for new users who haven't customized anything.
    static var defaultSizes: Set<CycleSize> = [.oneHalf, .twoThirds, .oneThird]

    /// All sizes sorted in the order they should cycle through.
    ///
    /// The order is designed to feel natural:
    /// 1. Start with the "first size" (1/2 - the most common)
    /// 2. Then larger sizes (2/3, 3/4)
    /// 3. Then wrap to smaller sizes (1/4, 1/3)
    ///
    /// So the full cycle order is: 1/2 → 2/3 → 3/4 → 1/4 → 1/3 → (repeat)
    ///
    /// This feels intuitive because pressing the shortcut again usually means
    /// "I want a bit more space", so we go larger first before wrapping to smaller.
    static var sortedSizes: [CycleSize] = {
        // First, sort all sizes by their fraction value (smallest to largest)
        // Result: [1/4, 1/3, 1/2, 2/3, 3/4]
        let sortedByFraction = Self.allCases.sorted { $0.fraction < $1.fraction }

        // Find where our "first size" (1/2) is in this sorted list
        guard let firstSizeIndex = sortedByFraction.firstIndex(of: firstSize) else {
            return sortedByFraction
        }

        // Split into sizes smaller than 1/2 and sizes larger than 1/2
        let smallerSizes = sortedByFraction[0..<firstSizeIndex]           // [1/4, 1/3]
        let largerSizes = sortedByFraction[(firstSizeIndex + 1)..<sortedByFraction.count]  // [2/3, 3/4]

        // Reorder: first size, then larger, then smaller (wrap around)
        // Result: [1/2, 2/3, 3/4, 1/4, 1/3]
        return [firstSize] + largerSizes + smallerSizes
    }()
}

// MARK: - Display and Value Properties

extension CycleSize {

    /// A Unicode fraction character for display in the UI.
    var title: String {
        switch self {
        case .twoThirds:
            "⅔"
        case .oneHalf:
            "½"
        case .oneThird:
            "⅓"
        case .oneQuarter:
            "¼"
        case .threeQuarters:
            "¾"
        }
    }

    /// The numeric fraction value (for calculations and sorting).
    var fraction: Float {
        switch self {
        case .twoThirds:
            2.0 / 3.0
        case .oneHalf:
            1.0 / 2.0
        case .oneThird:
            1.0 / 3.0
        case .oneQuarter:
            1.0 / 4.0
        case .threeQuarters:
            3.0 / 4.0
        }
    }

    /// Whether this size is always enabled and cannot be turned off.
    ///
    /// The "first size" (1/2) is always enabled because the cycle needs
    /// at least one size to work. Without this, the user could disable
    /// all sizes and break the cycling feature.
    var isAlwaysEnabled: Bool {
        return self == CycleSize.firstSize
    }
}

// MARK: - Set Extension for Bitwise Storage

extension Set where Element == CycleSize {

    /// Converts this Set of CycleSizes into a bitmask integer for storage.
    ///
    /// Example:
    /// ```swift
    /// let sizes: Set<CycleSize> = [.oneHalf, .oneThird]
    /// let bits = sizes.toBits()
    /// // bits = 6 (binary: 00110)
    /// // Bit 1 (oneHalf) = 1, Bit 2 (oneThird) = 1
    /// ```
    ///
    /// This is the inverse of `CycleSize.fromBits(bits:)`.
    func toBits() -> Int {
        print(#function, "called")
        var bits = 0
        for cycleSize in self {
            // Set the bit at position `rawValue` to 1
            // Example: for oneHalf (rawValue=1), we set bit 1
            // 1 << 1 = 2 (binary: 010)
            bits |= 1 << cycleSize.rawValue
        }
        return bits
    }
}

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
        print(#function, "called")
        let storedBits = UserDefaults.standard.integer(forKey: key)
        value = CycleSize.fromBits(bits: storedBits)
        initialized = true
    }

    /// Load a value from an imported settings file.
    func load(from codable: CodableDefault) {
        print(#function, "called")
        if let bits = codable.int {
            value = CycleSize.fromBits(bits: bits)
        }
    }

    /// Convert the current value to a format suitable for export.
    func toCodable() -> CodableDefault {
        print(#function, "called")
        return CodableDefault(int: value.toBits())
    }
}
