//
//  GridType.swift
//  tiny_window_manager
//

import Foundation

/// Defines the different grid layouts available for positioning windows.
///
/// Each grid type divides the screen into cells of a specific arrangement:
///
/// ```
/// NINTHS (3×3):          EIGHTHS (4×2 landscape):    CORNER THIRDS (2×2):
/// ┌───┬───┬───┐          ┌───┬───┬───┬───┐           ┌───────┬───────┐
/// │   │   │   │          │   │   │   │   │           │       │       │
/// ├───┼───┼───┤          ├───┼───┼───┼───┤           │  2/3  │  2/3  │
/// │   │   │   │          │   │   │   │   │           │       │       │
/// ├───┼───┼───┤          └───┴───┴───┴───┘           ├───────┼───────┤
/// │   │   │   │                                      │       │       │
/// └───┴───┴───┘                                      │  2/3  │  2/3  │
///                                                    │       │       │
///                                                    └───────┴───────┘
/// ```
enum GridType {

    /// 3×3 grid with 9 equal cells. Layout stays the same in both orientations.
    case ninths

    /// 4×2 grid in landscape (8 cells), becomes 2×4 in portrait.
    /// The grid "rotates" with the screen orientation.
    case eighths

    /// 2×2 grid where each cell is 2/3 of the screen in the major dimension.
    /// Cells overlap slightly because 4 × (2/3) > 2. Useful for larger windows.
    case cornerThirds

    // MARK: - Grid Dimensions

    /// Returns the number of columns for this grid type.
    ///
    /// - Parameter isLandscape: Whether the screen is in landscape orientation
    /// - Returns: Number of columns (horizontal divisions)
    func columns(isLandscape: Bool) -> Int {
        print(#function, "called")
        switch self {
        case .ninths:
            return 3  // Always 3 columns

        case .eighths:
            // More columns in landscape (wider screen), fewer in portrait
            return isLandscape ? 4 : 2

        case .cornerThirds:
            return 2  // Always 2 columns
        }
    }

    /// Returns the number of rows for this grid type.
    ///
    /// - Parameter isLandscape: Whether the screen is in landscape orientation
    /// - Returns: Number of rows (vertical divisions)
    func rows(isLandscape: Bool) -> Int {
        print(#function, "called")
        switch self {
        case .ninths:
            return 3  // Always 3 rows

        case .eighths:
            // Fewer rows in landscape, more in portrait (inverse of columns)
            return isLandscape ? 2 : 4

        case .cornerThirds:
            return 2  // Always 2 rows
        }
    }

    // MARK: - Cell Sizing

    /// Whether this grid type uses special cell sizing (not just screen ÷ columns/rows).
    ///
    /// Corner thirds use 2/3 of the screen per cell rather than 1/2,
    /// which creates overlapping regions at the center.
    var usesCustomCellSize: Bool {
        self == .cornerThirds
    }

    /// Calculates the width of a single cell in this grid.
    ///
    /// - Parameters:
    ///   - screenWidth: The total width of the visible screen area
    ///   - isLandscape: Whether the screen is in landscape orientation
    /// - Returns: The width of one cell in points
    func cellWidth(screenWidth: CGFloat, isLandscape: Bool) -> CGFloat {
        print(#function, "called")
        switch self {
        case .ninths:
            // Each cell is 1/3 of screen width
            return floor(screenWidth / 3.0)

        case .eighths:
            // 1/4 width in landscape, 1/2 width in portrait
            let divisor = CGFloat(isLandscape ? 4 : 2)
            return floor(screenWidth / divisor)

        case .cornerThirds:
            // 2/3 width in landscape (major dimension), 1/2 in portrait
            let fraction = isLandscape ? (2.0 / 3.0) : (1.0 / 2.0)
            return floor(screenWidth * fraction)
        }
    }

    /// Calculates the height of a single cell in this grid.
    ///
    /// - Parameters:
    ///   - screenHeight: The total height of the visible screen area
    ///   - isLandscape: Whether the screen is in landscape orientation
    /// - Returns: The height of one cell in points
    func cellHeight(screenHeight: CGFloat, isLandscape: Bool) -> CGFloat {
        print(#function, "called")
        switch self {
        case .ninths:
            // Each cell is 1/3 of screen height
            return floor(screenHeight / 3.0)

        case .eighths:
            // 1/2 height in landscape, 1/4 height in portrait
            let divisor = CGFloat(isLandscape ? 2 : 4)
            return floor(screenHeight / divisor)

        case .cornerThirds:
            // 1/2 height in landscape, 2/3 in portrait (major dimension)
            let fraction = isLandscape ? (1.0 / 2.0) : (2.0 / 3.0)
            return floor(screenHeight * fraction)
        }
    }
}
