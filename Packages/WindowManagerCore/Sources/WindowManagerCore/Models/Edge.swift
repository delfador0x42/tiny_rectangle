//  Edge.swift - Edge definitions for gap calculations
//
//  Defines which edges of a window are "shared" with adjacent windows,
//  used for calculating gaps between windows.

import Foundation

// MARK: - Edge OptionSet

/// Represents edges of a rectangle.
///
/// Used for:
/// - Calculating which edges are shared between adjacent windows
/// - Determining where to apply gaps
public struct Edge: OptionSet, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let left = Edge(rawValue: 1 << 0)
    public static let right = Edge(rawValue: 1 << 1)
    public static let top = Edge(rawValue: 1 << 2)
    public static let bottom = Edge(rawValue: 1 << 3)

    public static let all: Edge = [.left, .right, .top, .bottom]
    public static let none: Edge = []
    public static let horizontal: Edge = [.left, .right]
    public static let vertical: Edge = [.top, .bottom]
}

// MARK: - Dimension OptionSet

/// Represents dimensions (horizontal, vertical, or both).
///
/// Used for determining which dimensions should have gaps applied.
public struct Dimension: OptionSet, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let horizontal = Dimension(rawValue: 1 << 0)
    public static let vertical = Dimension(rawValue: 1 << 1)

    public static let both: Dimension = [.horizontal, .vertical]
    public static let none: Dimension = []
}

// MARK: - Directional Enum

/// Represents a direction or screen edge position.
public enum Directional: String, Codable, Sendable, CaseIterable {
    case tl  // Top-left
    case t   // Top
    case tr  // Top-right
    case l   // Left
    case r   // Right
    case bl  // Bottom-left
    case b   // Bottom
    case br  // Bottom-right
}
