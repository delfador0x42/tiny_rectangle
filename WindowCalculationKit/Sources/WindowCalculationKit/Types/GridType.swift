//
//  GridType.swift
//  WindowCalculationKit
//
//  Defines different grid layouts for positioning windows.
//

import CoreGraphics

/// Defines different grid layouts for window positioning.
///
/// Each grid type specifies how the screen is divided and the dimensions of each cell.
public enum GridType: Sendable {

    /// 3×3 grid creating 9 equal cells.
    case ninths

    /// Orientation-aware 4×2 (landscape) or 2×4 (portrait) grid creating 8 cells.
    case eighths

    /// 2×2 grid where each cell is 2/3 screen size (overlapping corners).
    case cornerThirds

    /// 3×2 (landscape) or 2×3 (portrait) grid creating 6 cells.
    case sixths

    // MARK: - Grid Dimensions

    /// Number of columns in this grid type.
    public func columns(isLandscape: Bool) -> Int {
        switch self {
        case .ninths:
            return 3
        case .eighths:
            return isLandscape ? 4 : 2
        case .cornerThirds:
            return 2
        case .sixths:
            return isLandscape ? 3 : 2
        }
    }

    /// Number of rows in this grid type.
    public func rows(isLandscape: Bool) -> Int {
        switch self {
        case .ninths:
            return 3
        case .eighths:
            return isLandscape ? 2 : 4
        case .cornerThirds:
            return 2
        case .sixths:
            return isLandscape ? 2 : 3
        }
    }

    /// Width of a single cell as a fraction of screen width.
    public func cellWidthFraction(isLandscape: Bool) -> CGFloat {
        switch self {
        case .ninths:
            return 1.0 / 3.0
        case .eighths:
            return isLandscape ? 0.25 : 0.5
        case .cornerThirds:
            return 2.0 / 3.0
        case .sixths:
            return isLandscape ? 1.0 / 3.0 : 0.5
        }
    }

    /// Height of a single cell as a fraction of screen height.
    public func cellHeightFraction(isLandscape: Bool) -> CGFloat {
        switch self {
        case .ninths:
            return 1.0 / 3.0
        case .eighths:
            return isLandscape ? 0.5 : 0.25
        case .cornerThirds:
            // In landscape, height is 1/2; in portrait, height is 2/3 (major dimension)
            return isLandscape ? 0.5 : 2.0 / 3.0
        case .sixths:
            return isLandscape ? 0.5 : 1.0 / 3.0
        }
    }

    // MARK: - Cell Sizing (Absolute)

    /// Calculates the actual width of a cell in points.
    ///
    /// - Parameters:
    ///   - screenWidth: The total width of the visible screen area.
    ///   - isLandscape: Whether the screen is in landscape orientation.
    /// - Returns: The width of one cell in points (floored to avoid fractional pixels).
    public func cellWidth(screenWidth: CGFloat, isLandscape: Bool) -> CGFloat {
        switch self {
        case .ninths:
            return floor(screenWidth / 3.0)
        case .eighths:
            let divisor: CGFloat = isLandscape ? 4.0 : 2.0
            return floor(screenWidth / divisor)
        case .cornerThirds:
            // In landscape, width is 2/3; in portrait, width is 1/2
            let fraction: CGFloat = isLandscape ? (2.0 / 3.0) : 0.5
            return floor(screenWidth * fraction)
        case .sixths:
            let divisor: CGFloat = isLandscape ? 3.0 : 2.0
            return floor(screenWidth / divisor)
        }
    }

    /// Calculates the actual height of a cell in points.
    ///
    /// - Parameters:
    ///   - screenHeight: The total height of the visible screen area.
    ///   - isLandscape: Whether the screen is in landscape orientation.
    /// - Returns: The height of one cell in points (floored to avoid fractional pixels).
    public func cellHeight(screenHeight: CGFloat, isLandscape: Bool) -> CGFloat {
        switch self {
        case .ninths:
            return floor(screenHeight / 3.0)
        case .eighths:
            let divisor: CGFloat = isLandscape ? 2.0 : 4.0
            return floor(screenHeight / divisor)
        case .cornerThirds:
            // In landscape, height is 1/2; in portrait, height is 2/3
            let fraction: CGFloat = isLandscape ? 0.5 : (2.0 / 3.0)
            return floor(screenHeight * fraction)
        case .sixths:
            let divisor: CGFloat = isLandscape ? 2.0 : 3.0
            return floor(screenHeight / divisor)
        }
    }
}

// MARK: - Grid Position

/// A position within a grid.
public struct GridPosition: Sendable, Equatable {

    /// Column index (0-based, from left).
    public let column: Int

    /// Row index (0-based, from top).
    public let row: Int

    public init(column: Int, row: Int) {
        self.column = column
        self.row = row
    }
}
