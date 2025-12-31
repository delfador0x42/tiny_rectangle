//
//  CycleSize.swift
//  WindowCalculationKit
//
//  Defines the different sizes a window can cycle through when pressing
//  the same keyboard shortcut repeatedly.
//

import Foundation

/// Represents a fraction of the screen width/height that a window can occupy.
///
/// When the user presses a window action shortcut repeatedly, the window
/// cycles through these sizes (if cycling is enabled).
///
/// ## Cycle Order
/// The default cycle order is designed to feel natural:
/// 1. Start with 1/2 (most common)
/// 2. Go larger (2/3, 3/4)
/// 3. Wrap to smaller (1/4, 1/3)
///
/// So: 1/2 → 2/3 → 3/4 → 1/4 → 1/3 → (repeat)
public enum CycleSize: Int, CaseIterable, Sendable, Codable {

    /// Two-thirds (⅔) of the screen
    case twoThirds = 0

    /// One-half (½) of the screen
    case oneHalf = 1

    /// One-third (⅓) of the screen
    case oneThird = 2

    /// One-quarter (¼) of the screen
    case oneQuarter = 3

    /// Three-quarters (¾) of the screen
    case threeQuarters = 4

    // MARK: - Properties

    /// A Unicode fraction character for display in the UI.
    public var title: String {
        switch self {
        case .twoThirds: "⅔"
        case .oneHalf: "½"
        case .oneThird: "⅓"
        case .oneQuarter: "¼"
        case .threeQuarters: "¾"
        }
    }

    /// The numeric fraction value (for calculations).
    public var fraction: Float {
        switch self {
        case .twoThirds: 2.0 / 3.0
        case .oneHalf: 1.0 / 2.0
        case .oneThird: 1.0 / 3.0
        case .oneQuarter: 1.0 / 4.0
        case .threeQuarters: 3.0 / 4.0
        }
    }

    /// Whether this is the default "first" size in the cycle.
    public var isFirstSize: Bool {
        self == .oneHalf
    }

    // MARK: - Bitwise Conversion

    /// Converts a bitmask integer back into a Set of CycleSizes.
    ///
    /// Each size has a "bit position" (its rawValue):
    /// - twoThirds    = bit 0 (value 1)
    /// - oneHalf      = bit 1 (value 2)
    /// - oneThird     = bit 2 (value 4)
    /// - oneQuarter   = bit 3 (value 8)
    /// - threeQuarters = bit 4 (value 16)
    ///
    /// - Parameter bits: An integer where each bit represents whether a size is selected.
    /// - Returns: A Set containing all the sizes whose bits are set to 1.
    public static func fromBits(_ bits: Int) -> Set<CycleSize> {
        Set(
            Self.allCases.filter { cycleSize in
                let bitPosition = cycleSize.rawValue
                let bitIsSet = (bits >> bitPosition) & 1 == 1
                return bitIsSet
            }
        )
    }

    /// The default set of sizes for cycling.
    public static let defaultSizes: Set<CycleSize> = [.oneHalf, .twoThirds, .oneThird]

    /// All sizes sorted in cycle order (1/2 first, then larger, then smaller).
    public static let sortedForCycle: [CycleSize] = {
        let sortedByFraction = Self.allCases.sorted { $0.fraction < $1.fraction }
        guard let firstSizeIndex = sortedByFraction.firstIndex(of: .oneHalf) else {
            return sortedByFraction
        }
        let smallerSizes = sortedByFraction[0..<firstSizeIndex]
        let largerSizes = sortedByFraction[(firstSizeIndex + 1)..<sortedByFraction.count]
        return [.oneHalf] + largerSizes + smallerSizes
    }()
}

// MARK: - Set Extension

extension Set where Element == CycleSize {

    /// Converts this Set of CycleSizes into a bitmask integer for storage.
    public func toBits() -> Int {
        var bits = 0
        for cycleSize in self {
            bits |= 1 << cycleSize.rawValue
        }
        return bits
    }

    /// Returns sizes in the order they should be cycled through.
    public var sortedForCycle: [CycleSize] {
        CycleSize.sortedForCycle.filter { self.contains($0) }
    }
}
