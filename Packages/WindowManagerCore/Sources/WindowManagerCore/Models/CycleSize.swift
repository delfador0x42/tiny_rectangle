//
//  CycleSize.swift
//  WindowManagerCore
//
//  Represents the different sizes a window can cycle through when pressing
//  the same keyboard shortcut repeatedly.
//

import Foundation

// MARK: - Cycle Size Enum

/// Represents a fraction of the screen width/height that a window can occupy.
///
/// When the user presses a window action shortcut repeatedly, the window
/// cycles through these sizes (if cycling is enabled).
public enum CycleSize: Int, CaseIterable, Sendable {

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
    public static func fromBits(bits: Int) -> Set<CycleSize> {
        return Set(
            Self.allCases.filter { cycleSize in
                let bitPosition = cycleSize.rawValue
                let bitIsSet = (bits >> bitPosition) & 1 == 1
                return bitIsSet
            }
        )
    }

    // MARK: - Defaults and Ordering

    /// The size that appears first in the cycle and cannot be disabled.
    public static var firstSize = CycleSize.oneHalf

    /// The default set of sizes for new users who haven't customized anything.
    public static var defaultSizes: Set<CycleSize> = [.oneHalf, .twoThirds, .oneThird]

    /// All sizes sorted in the order they should cycle through.
    ///
    /// The order is: 1/2 → 2/3 → 3/4 → 1/4 → 1/3 → (repeat)
    public static var sortedSizes: [CycleSize] = {
        let sortedByFraction = Self.allCases.sorted { $0.fraction < $1.fraction }
        guard let firstSizeIndex = sortedByFraction.firstIndex(of: firstSize) else {
            return sortedByFraction
        }
        let smallerSizes = sortedByFraction[0..<firstSizeIndex]
        let largerSizes = sortedByFraction[(firstSizeIndex + 1)..<sortedByFraction.count]
        return [firstSize] + largerSizes + smallerSizes
    }()
}

// MARK: - Display and Value Properties

extension CycleSize {

    /// A Unicode fraction character for display in the UI.
    public var title: String {
        switch self {
        case .twoThirds: return "⅔"
        case .oneHalf: return "½"
        case .oneThird: return "⅓"
        case .oneQuarter: return "¼"
        case .threeQuarters: return "¾"
        }
    }

    /// The numeric fraction value (for calculations and sorting).
    public var fraction: Float {
        switch self {
        case .twoThirds: return 2.0 / 3.0
        case .oneHalf: return 1.0 / 2.0
        case .oneThird: return 1.0 / 3.0
        case .oneQuarter: return 1.0 / 4.0
        case .threeQuarters: return 3.0 / 4.0
        }
    }

    /// Whether this size is always enabled and cannot be turned off.
    public var isAlwaysEnabled: Bool {
        return self == CycleSize.firstSize
    }
}

// MARK: - Set Extension for Bitwise Storage

extension Set where Element == CycleSize {

    /// Converts this Set of CycleSizes into a bitmask integer for storage.
    public func toBits() -> Int {
        var bits = 0
        for cycleSize in self {
            bits |= 1 << cycleSize.rawValue
        }
        return bits
    }
}
