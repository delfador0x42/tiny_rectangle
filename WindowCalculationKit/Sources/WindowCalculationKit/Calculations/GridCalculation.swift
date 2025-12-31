//
//  GridCalculation.swift
//  WindowCalculationKit
//
//  A flexible window calculator that positions windows in a grid layout.
//

import CoreGraphics

/// A window calculator that positions windows in a grid layout.
///
/// Grids divide the screen into cells. This class handles different grid types
/// (sixths, ninths, eighths, corner thirds) and calculates which cell the window
/// should occupy.
///
/// ## Example
/// A 3×3 grid (ninths) with column=1, row=0 would be the top-center cell:
/// ```
/// ┌───┬───┬───┐
/// │0,0│1,0│2,0│  ← row 0 (top)
/// ├───┼───┼───┤
/// │0,1│1,1│2,1│  ← row 1 (middle)
/// ├───┼───┼───┤
/// │0,2│1,2│2,2│  ← row 2 (bottom)
/// └───┴───┴───┘
///   ^   ^   ^
///  col col col
///   0   1   2
/// ```
///
/// ## Usage
/// ```swift
/// // Create a calculation for top-left ninth
/// let calc = GridCalculation(
///     gridType: .ninths,
///     column: 0,
///     row: 0,
///     subAction: .topLeftNinth
/// )
///
/// let result = calc.calculateRect(params)
/// ```
public struct GridCalculation: Calculation, OrientationAware, Sendable {

    // MARK: - Properties

    /// The type of grid (determines number of columns/rows and cell sizing).
    public let gridType: GridType

    /// Column position when screen is in landscape orientation (0 = leftmost).
    public let landscapeColumn: Int

    /// Row position when screen is in landscape orientation (0 = topmost).
    public let landscapeRow: Int

    /// Column position when screen is in portrait orientation (0 = leftmost).
    public let portraitColumn: Int

    /// Row position when screen is in portrait orientation (0 = topmost).
    public let portraitRow: Int

    /// The sub-action identifier for this specific grid position.
    public let subAction: SubActionIdentifier

    // MARK: - Initialization

    /// Creates a grid calculation with different positions for landscape and portrait orientations.
    ///
    /// Use this when the grid position should change based on screen orientation.
    ///
    /// - Parameters:
    ///   - gridType: The type of grid layout.
    ///   - landscapeColumn: Column index in landscape (0 = leftmost).
    ///   - landscapeRow: Row index in landscape (0 = topmost).
    ///   - portraitColumn: Column index in portrait (0 = leftmost).
    ///   - portraitRow: Row index in portrait (0 = topmost).
    ///   - subAction: The sub-action identifier for this position.
    public init(
        gridType: GridType,
        landscapeColumn: Int,
        landscapeRow: Int,
        portraitColumn: Int,
        portraitRow: Int,
        subAction: SubActionIdentifier
    ) {
        self.gridType = gridType
        self.landscapeColumn = landscapeColumn
        self.landscapeRow = landscapeRow
        self.portraitColumn = portraitColumn
        self.portraitRow = portraitRow
        self.subAction = subAction
    }

    /// Creates a grid calculation where position stays the same regardless of orientation.
    ///
    /// Use this for grids like ninths or corner thirds where the grid cell
    /// doesn't change between landscape and portrait modes.
    ///
    /// - Parameters:
    ///   - gridType: The type of grid layout.
    ///   - column: Column index (0 = leftmost).
    ///   - row: Row index (0 = topmost).
    ///   - subAction: The sub-action identifier for this position.
    public init(
        gridType: GridType,
        column: Int,
        row: Int,
        subAction: SubActionIdentifier
    ) {
        self.init(
            gridType: gridType,
            landscapeColumn: column,
            landscapeRow: row,
            portraitColumn: column,
            portraitRow: row,
            subAction: subAction
        )
    }

    // MARK: - OrientationAware

    /// Returns the grid cell rectangle for landscape orientation.
    public func landscapeRect(_ frame: CGRect, _ params: CalculationParams) -> RectResult {
        calculateGridRect(frame, column: landscapeColumn, row: landscapeRow, isLandscape: true)
    }

    /// Returns the grid cell rectangle for portrait orientation.
    public func portraitRect(_ frame: CGRect, _ params: CalculationParams) -> RectResult {
        calculateGridRect(frame, column: portraitColumn, row: portraitRow, isLandscape: false)
    }

    // MARK: - Private Helpers

    /// Calculates the actual rectangle for a specific grid cell.
    ///
    /// - Parameters:
    ///   - frame: The visible screen area to divide into a grid.
    ///   - column: Which column (0 = leftmost).
    ///   - row: Which row (0 = topmost).
    ///   - isLandscape: Whether the screen is in landscape orientation.
    /// - Returns: The rectangle for the specified grid cell.
    private func calculateGridRect(
        _ frame: CGRect,
        column: Int,
        row: Int,
        isLandscape: Bool
    ) -> RectResult {
        // Calculate the size of each cell in the grid
        let cellWidth = gridType.cellWidth(screenWidth: frame.width, isLandscape: isLandscape)
        let cellHeight = gridType.cellHeight(screenHeight: frame.height, isLandscape: isLandscape)

        // Calculate horizontal position: offset by column number × cell width
        let xPosition = frame.minX + cellWidth * CGFloat(column)

        // Calculate vertical position
        // In macOS coordinates, Y increases upward, so row 0 (top) has the highest Y value
        // We subtract (row + 1) × cellHeight from maxY to get the correct position
        let yPosition = frame.maxY - cellHeight * CGFloat(row + 1)

        // Build the final rectangle
        let rect = CGRect(
            x: xPosition,
            y: yPosition,
            width: cellWidth,
            height: cellHeight
        )

        return RectResult(rect, subAction: subAction)
    }
}

// MARK: - Factory Methods

extension GridCalculation {

    // MARK: - Ninths (3×3)

    /// Top-left ninth of the screen.
    public static let topLeftNinth = GridCalculation(
        gridType: .ninths, column: 0, row: 0, subAction: .topLeftNinth
    )

    /// Top-center ninth of the screen.
    public static let topCenterNinth = GridCalculation(
        gridType: .ninths, column: 1, row: 0, subAction: .topCenterNinth
    )

    /// Top-right ninth of the screen.
    public static let topRightNinth = GridCalculation(
        gridType: .ninths, column: 2, row: 0, subAction: .topRightNinth
    )

    /// Middle-left ninth of the screen.
    public static let middleLeftNinth = GridCalculation(
        gridType: .ninths, column: 0, row: 1, subAction: .middleLeftNinth
    )

    /// Middle-center ninth of the screen.
    public static let middleCenterNinth = GridCalculation(
        gridType: .ninths, column: 1, row: 1, subAction: .middleCenterNinth
    )

    /// Middle-right ninth of the screen.
    public static let middleRightNinth = GridCalculation(
        gridType: .ninths, column: 2, row: 1, subAction: .middleRightNinth
    )

    /// Bottom-left ninth of the screen.
    public static let bottomLeftNinth = GridCalculation(
        gridType: .ninths, column: 0, row: 2, subAction: .bottomLeftNinth
    )

    /// Bottom-center ninth of the screen.
    public static let bottomCenterNinth = GridCalculation(
        gridType: .ninths, column: 1, row: 2, subAction: .bottomCenterNinth
    )

    /// Bottom-right ninth of the screen.
    public static let bottomRightNinth = GridCalculation(
        gridType: .ninths, column: 2, row: 2, subAction: .bottomRightNinth
    )

    // MARK: - Eighths (4×2 landscape, 2×4 portrait)

    /// Top-left eighth of the screen.
    public static let topLeftEighth = GridCalculation(
        gridType: .eighths,
        landscapeColumn: 0, landscapeRow: 0,
        portraitColumn: 0, portraitRow: 0,
        subAction: .topLeftEighth
    )

    /// Top-center-left eighth of the screen.
    public static let topCenterLeftEighth = GridCalculation(
        gridType: .eighths,
        landscapeColumn: 1, landscapeRow: 0,
        portraitColumn: 0, portraitRow: 1,
        subAction: .topCenterLeftEighth
    )

    /// Top-center-right eighth of the screen.
    public static let topCenterRightEighth = GridCalculation(
        gridType: .eighths,
        landscapeColumn: 2, landscapeRow: 0,
        portraitColumn: 0, portraitRow: 2,
        subAction: .topCenterRightEighth
    )

    /// Top-right eighth of the screen.
    public static let topRightEighth = GridCalculation(
        gridType: .eighths,
        landscapeColumn: 3, landscapeRow: 0,
        portraitColumn: 0, portraitRow: 3,
        subAction: .topRightEighth
    )

    /// Bottom-left eighth of the screen.
    public static let bottomLeftEighth = GridCalculation(
        gridType: .eighths,
        landscapeColumn: 0, landscapeRow: 1,
        portraitColumn: 1, portraitRow: 0,
        subAction: .bottomLeftEighth
    )

    /// Bottom-center-left eighth of the screen.
    public static let bottomCenterLeftEighth = GridCalculation(
        gridType: .eighths,
        landscapeColumn: 1, landscapeRow: 1,
        portraitColumn: 1, portraitRow: 1,
        subAction: .bottomCenterLeftEighth
    )

    /// Bottom-center-right eighth of the screen.
    public static let bottomCenterRightEighth = GridCalculation(
        gridType: .eighths,
        landscapeColumn: 2, landscapeRow: 1,
        portraitColumn: 1, portraitRow: 2,
        subAction: .bottomCenterRightEighth
    )

    /// Bottom-right eighth of the screen.
    public static let bottomRightEighth = GridCalculation(
        gridType: .eighths,
        landscapeColumn: 3, landscapeRow: 1,
        portraitColumn: 1, portraitRow: 3,
        subAction: .bottomRightEighth
    )

    // MARK: - Corner Thirds (2×2 with 2/3 sizing)

    /// Top-left corner third of the screen.
    public static let topLeftThird = GridCalculation(
        gridType: .cornerThirds, column: 0, row: 0, subAction: .topLeftThird
    )

    /// Top-right corner third of the screen.
    public static let topRightThird = GridCalculation(
        gridType: .cornerThirds, column: 1, row: 0, subAction: .topRightThird
    )

    /// Bottom-left corner third of the screen.
    public static let bottomLeftThird = GridCalculation(
        gridType: .cornerThirds, column: 0, row: 1, subAction: .bottomLeftThird
    )

    /// Bottom-right corner third of the screen.
    public static let bottomRightThird = GridCalculation(
        gridType: .cornerThirds, column: 1, row: 1, subAction: .bottomRightThird
    )
}
