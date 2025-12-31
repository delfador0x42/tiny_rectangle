//
//  RectResult.swift
//  WindowCalculationKit
//
//  The result of a window calculation - a rectangle with metadata.
//

import CoreGraphics

/// The result of a window position calculation.
///
/// Contains the calculated rectangle and metadata about what was calculated.
public struct RectResult: Sendable {

    /// The calculated window rectangle in screen coordinates.
    ///
    /// Uses macOS coordinate system where y=0 is at the bottom of the screen.
    public let rect: CGRect

    /// The action that was performed (may differ from input for cycling).
    public let resultingAction: ActionIdentifier?

    /// More granular sub-action (e.g., leftThird vs topThird).
    public let subAction: SubActionIdentifier?

    /// For cycling: suggests the next action to perform.
    public let nextAction: ActionIdentifier?

    // MARK: - Initialization

    public init(
        _ rect: CGRect,
        resultingAction: ActionIdentifier? = nil,
        subAction: SubActionIdentifier? = nil,
        nextAction: ActionIdentifier? = nil
    ) {
        self.rect = rect
        self.resultingAction = resultingAction
        self.subAction = subAction
        self.nextAction = nextAction
    }

    /// Convenience initializer for simple rectangle results.
    public init(_ rect: CGRect, subAction: SubActionIdentifier?) {
        self.rect = rect
        self.resultingAction = nil
        self.subAction = subAction
        self.nextAction = nil
    }
}

// MARK: - Dimension

/// Specifies which dimension(s) an operation applies to.
public enum Dimension: Sendable {
    case horizontal
    case vertical
    case both
}

// MARK: - Edge

/// Represents edges of a rectangle for gap and alignment calculations.
public struct Edge: OptionSet, Sendable {

    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let top = Edge(rawValue: 1 << 0)
    public static let bottom = Edge(rawValue: 1 << 1)
    public static let left = Edge(rawValue: 1 << 2)
    public static let right = Edge(rawValue: 1 << 3)

    public static let none: Edge = []
    public static let all: Edge = [.top, .bottom, .left, .right]

    public static let horizontal: Edge = [.left, .right]
    public static let vertical: Edge = [.top, .bottom]
}
