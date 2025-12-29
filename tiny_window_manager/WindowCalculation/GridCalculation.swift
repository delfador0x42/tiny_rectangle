//
//  GridCalculation.swift
//  tiny_window_manager
//
//

import Foundation

class GridCalculation: WindowCalculation, OrientationAware {

    let gridType: GridType
    let landscapeColumn: Int
    let landscapeRow: Int
    let portraitColumn: Int
    let portraitRow: Int
    let action: WindowAction
    let subAction: SubWindowAction

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

    // Convenience for grids where position doesn't change with orientation (ninths, cornerThirds)
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

    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        let visibleFrameOfScreen = params.visibleFrameOfScreen

        guard Defaults.subsequentExecutionMode.value != .none,
              let last = params.lastAction,
              let lastSubAction = last.subAction
        else {
            return orientationBasedRect(visibleFrameOfScreen)
        }

        if last.action != action {
            return orientationBasedRect(visibleFrameOfScreen)
        }

        if let calculation = GridCycling.nextCalculation(for: gridType, currentSubAction: lastSubAction, direction: .right) {
            return calculation(visibleFrameOfScreen)
        }

        return orientationBasedRect(visibleFrameOfScreen)
    }

    func landscapeRect(_ visibleFrameOfScreen: CGRect) -> RectResult {
        calculateGridRect(visibleFrameOfScreen, column: landscapeColumn, row: landscapeRow, isLandscape: true)
    }

    func portraitRect(_ visibleFrameOfScreen: CGRect) -> RectResult {
        calculateGridRect(visibleFrameOfScreen, column: portraitColumn, row: portraitRow, isLandscape: false)
    }

    private func calculateGridRect(_ frame: CGRect, column: Int, row: Int, isLandscape: Bool) -> RectResult {
        var rect = frame

        rect.size.width = gridType.cellWidth(screenWidth: frame.width, isLandscape: isLandscape)
        rect.size.height = gridType.cellHeight(screenHeight: frame.height, isLandscape: isLandscape)

        // x position: offset by column * cellWidth
        rect.origin.x = frame.minX + rect.width * CGFloat(column)

        // y position: row 0 is top (maxY - height), row increases downward
        rect.origin.y = frame.maxY - rect.height * CGFloat(row + 1)

        return RectResult(rect, subAction: subAction)
    }
}
