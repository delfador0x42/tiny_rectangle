//
//  GridCalculation.swift
//  tiny_window_manager
//

import Foundation

/// A flexible window calculator that positions windows in a grid layout.
///
/// Grids divide the screen into cells. This class handles different grid types
/// (sixths, ninths, corner thirds) and calculates which cell the window should occupy.
///
/// Example: A 3x3 grid (ninths) with column=1, row=0 would be the top-center cell:
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
class GridCalculation: WindowCalculation, OrientationAware {

    // MARK: - Properties

    /// The type of grid (determines number of columns/rows)
    let gridType: GridType

    /// Column position when screen is in landscape orientation (0 = leftmost)
    let landscapeColumn: Int

    /// Row position when screen is in landscape orientation (0 = topmost)
    let landscapeRow: Int

    /// Column position when screen is in portrait orientation (0 = leftmost)
    let portraitColumn: Int

    /// Row position when screen is in portrait orientation (0 = topmost)
    let portraitRow: Int

    /// The window action this calculation is associated with
    let action: WindowAction

    /// The sub-action identifier for this specific grid position
    let subAction: SubWindowAction

    // MARK: - Initializers

    /// Creates a grid calculation with different positions for landscape and portrait orientations.
    ///
    /// Use this when the grid position should change based on screen orientation.
    /// For example, a "top-left sixth" might be column 0, row 0 in landscape
    /// but column 0, row 0 with different grid dimensions in portrait.
    init(gridType: GridType,
         landscapeColumn: Int, landscapeRow: Int,
         portraitColumn: Int, portraitRow: Int,
         action: WindowAction,
         subAction: SubWindowAction) {
        self.gridType = gridType
        self.landscapeColumn = landscapeColumn
        self.landscapeRow = landscapeRow
        self.portraitColumn = portraitColumn
        self.portraitRow = portraitRow
        self.action = action
        self.subAction = subAction
    }

    /// Creates a grid calculation where position stays the same regardless of orientation.
    ///
    /// Use this for grids like ninths or corner thirds where the grid cell
    /// doesn't change between landscape and portrait modes.
    convenience init(gridType: GridType,
                     column: Int, row: Int,
                     action: WindowAction,
                     subAction: SubWindowAction) {
        self.init(gridType: gridType,
                  landscapeColumn: column, landscapeRow: row,
                  portraitColumn: column, portraitRow: row,
                  action: action,
                  subAction: subAction)
    }

    // MARK: - Main Calculation

    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        let visibleFrameOfScreen = params.visibleFrameOfScreen

        // If cycling is disabled, just return the grid position
        let cyclingDisabled = Defaults.subsequentExecutionMode.value == .none
        if cyclingDisabled {
            return orientationBasedRect(visibleFrameOfScreen)
        }

        // Check if we have a previous action to cycle from
        guard let lastAction = params.lastAction,
              let lastSubAction = lastAction.subAction
        else {
            return orientationBasedRect(visibleFrameOfScreen)
        }

        // Only cycle if the user is repeating the same action
        let isDifferentAction = lastAction.action != action
        if isDifferentAction {
            return orientationBasedRect(visibleFrameOfScreen)
        }

        // Try to find the next grid position in the cycle
        if let nextPositionCalculation = GridCycling.nextCalculation(for: gridType, currentSubAction: lastSubAction, direction: .right) {
            return nextPositionCalculation(visibleFrameOfScreen)
        }

        return orientationBasedRect(visibleFrameOfScreen)
    }

    // MARK: - Orientation-Based Rectangles

    /// Returns the grid cell rectangle for landscape orientation
    func landscapeRect(_ visibleFrameOfScreen: CGRect) -> RectResult {
        calculateGridRect(visibleFrameOfScreen, column: landscapeColumn, row: landscapeRow, isLandscape: true)
    }

    /// Returns the grid cell rectangle for portrait orientation
    func portraitRect(_ visibleFrameOfScreen: CGRect) -> RectResult {
        calculateGridRect(visibleFrameOfScreen, column: portraitColumn, row: portraitRow, isLandscape: false)
    }

    // MARK: - Private Helpers

    /// Calculates the actual rectangle for a specific grid cell.
    ///
    /// - Parameters:
    ///   - frame: The visible screen area to divide into a grid
    ///   - column: Which column (0 = leftmost)
    ///   - row: Which row (0 = topmost)
    ///   - isLandscape: Whether the screen is in landscape orientation
    /// - Returns: The rectangle for the specified grid cell
    private func calculateGridRect(_ frame: CGRect, column: Int, row: Int, isLandscape: Bool) -> RectResult {
        // Calculate the size of each cell in the grid
        let cellWidth = gridType.cellWidth(screenWidth: frame.width, isLandscape: isLandscape)
        let cellHeight = gridType.cellHeight(screenHeight: frame.height, isLandscape: isLandscape)

        // Calculate horizontal position: offset by column number × cell width
        let xPosition = frame.minX + cellWidth * CGFloat(column)

        // Calculate vertical position
        // Note: In macOS coordinates, Y increases upward, so row 0 (top) has the highest Y value
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
