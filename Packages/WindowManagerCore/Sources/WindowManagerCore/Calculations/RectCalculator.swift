//  RectCalculator.swift - Pure window rectangle calculations
//
//  All calculations are side-effect free and work purely with CGRect.
//  No AppKit/Cocoa dependencies.

import CoreGraphics

// MARK: - RectCalculator

/// Pure functions for calculating window rectangles.
///
/// All methods are static and side-effect free. They compute the resulting
/// rectangle for a given window action within a screen frame.
public enum RectCalculator {

    // MARK: - Main Calculation Entry Point

    /// Calculate the window rect for a given action.
    /// - Parameters:
    ///   - action: The window action to apply
    ///   - screen: The screen's visible frame
    ///   - window: The current window frame (required for relative actions)
    ///   - settings: Settings for action-specific values
    /// - Returns: The calculated rect, or nil if action requires window but none provided
    public static func calculateRect(
        for action: WindowActionType,
        in screen: CGRect,
        window: CGRect? = nil,
        settings: SettingsProtocol = DefaultSettings()
    ) -> CGRect? {
        let w = screen.width
        let h = screen.height
        let x = screen.minX
        let y = screen.minY

        switch action {

        // MARK: Halves
        case .leftHalf:
            return CGRect(x: x, y: y, width: floor(w / 2), height: h)
        case .rightHalf:
            return CGRect(x: x + ceil(w / 2), y: y, width: floor(w / 2), height: h)
        case .topHalf:
            return CGRect(x: x, y: y + ceil(h / 2), width: w, height: floor(h / 2))
        case .bottomHalf:
            return CGRect(x: x, y: y, width: w, height: floor(h / 2))
        case .centerHalf:
            return CGRect(x: x + floor(w / 4), y: y, width: floor(w / 2), height: h)

        // MARK: Corners (Quarters)
        case .topLeft:
            return CGRect(x: x, y: y + ceil(h / 2), width: floor(w / 2), height: floor(h / 2))
        case .topRight:
            return CGRect(x: x + ceil(w / 2), y: y + ceil(h / 2), width: floor(w / 2), height: floor(h / 2))
        case .bottomLeft:
            return CGRect(x: x, y: y, width: floor(w / 2), height: floor(h / 2))
        case .bottomRight:
            return CGRect(x: x + ceil(w / 2), y: y, width: floor(w / 2), height: floor(h / 2))

        // MARK: Thirds (Vertical)
        case .firstThird:
            return CGRect(x: x, y: y, width: floor(w / 3), height: h)
        case .centerThird:
            return CGRect(x: x + floor(w / 3), y: y, width: floor(w / 3), height: h)
        case .lastThird:
            return CGRect(x: x + floor(w * 2 / 3), y: y, width: floor(w / 3), height: h)
        case .firstTwoThirds:
            return CGRect(x: x, y: y, width: floor(w * 2 / 3), height: h)
        case .centerTwoThirds:
            return CGRect(x: x + floor(w / 6), y: y, width: floor(w * 2 / 3), height: h)
        case .lastTwoThirds:
            return CGRect(x: x + floor(w / 3), y: y, width: floor(w * 2 / 3), height: h)

        // MARK: Fourths (Vertical)
        case .firstFourth:
            return CGRect(x: x, y: y, width: floor(w / 4), height: h)
        case .secondFourth:
            return CGRect(x: x + floor(w / 4), y: y, width: floor(w / 4), height: h)
        case .thirdFourth:
            return CGRect(x: x + floor(w * 2 / 4), y: y, width: floor(w / 4), height: h)
        case .lastFourth:
            return CGRect(x: x + floor(w * 3 / 4), y: y, width: floor(w / 4), height: h)
        case .firstThreeFourths:
            return CGRect(x: x, y: y, width: floor(w * 3 / 4), height: h)
        case .centerThreeFourths:
            return CGRect(x: x + floor(w / 8), y: y, width: floor(w * 3 / 4), height: h)
        case .lastThreeFourths:
            return CGRect(x: x + floor(w / 4), y: y, width: floor(w * 3 / 4), height: h)

        // MARK: Sixths (3x2 grid)
        case .topLeftSixth:
            return CGRect(x: x, y: y + ceil(h / 2), width: floor(w / 3), height: floor(h / 2))
        case .topCenterSixth:
            return CGRect(x: x + floor(w / 3), y: y + ceil(h / 2), width: floor(w / 3), height: floor(h / 2))
        case .topRightSixth:
            return CGRect(x: x + floor(w * 2 / 3), y: y + ceil(h / 2), width: floor(w / 3), height: floor(h / 2))
        case .bottomLeftSixth:
            return CGRect(x: x, y: y, width: floor(w / 3), height: floor(h / 2))
        case .bottomCenterSixth:
            return CGRect(x: x + floor(w / 3), y: y, width: floor(w / 3), height: floor(h / 2))
        case .bottomRightSixth:
            return CGRect(x: x + floor(w * 2 / 3), y: y, width: floor(w / 3), height: floor(h / 2))

        // MARK: Ninths (3x3 grid)
        case .topLeftNinth:
            return screen.gridCell(cols: 3, rows: 3, col: 0, row: 0)
        case .topCenterNinth:
            return screen.gridCell(cols: 3, rows: 3, col: 1, row: 0)
        case .topRightNinth:
            return screen.gridCell(cols: 3, rows: 3, col: 2, row: 0)
        case .middleLeftNinth:
            return screen.gridCell(cols: 3, rows: 3, col: 0, row: 1)
        case .middleCenterNinth:
            return screen.gridCell(cols: 3, rows: 3, col: 1, row: 1)
        case .middleRightNinth:
            return screen.gridCell(cols: 3, rows: 3, col: 2, row: 1)
        case .bottomLeftNinth:
            return screen.gridCell(cols: 3, rows: 3, col: 0, row: 2)
        case .bottomCenterNinth:
            return screen.gridCell(cols: 3, rows: 3, col: 1, row: 2)
        case .bottomRightNinth:
            return screen.gridCell(cols: 3, rows: 3, col: 2, row: 2)

        // MARK: Corner Thirds (2x2, each cell 2/3 size)
        case .topLeftThird:
            return CGRect(x: x, y: y + ceil(h / 3), width: floor(w * 2 / 3), height: floor(h * 2 / 3))
        case .topRightThird:
            return CGRect(x: x + ceil(w / 3), y: y + ceil(h / 3), width: floor(w * 2 / 3), height: floor(h * 2 / 3))
        case .bottomLeftThird:
            return CGRect(x: x, y: y, width: floor(w * 2 / 3), height: floor(h * 2 / 3))
        case .bottomRightThird:
            return CGRect(x: x + ceil(w / 3), y: y, width: floor(w * 2 / 3), height: floor(h * 2 / 3))

        // MARK: Eighths (4x2 grid)
        case .topLeftEighth:
            return screen.gridCell(cols: 4, rows: 2, col: 0, row: 0)
        case .topCenterLeftEighth:
            return screen.gridCell(cols: 4, rows: 2, col: 1, row: 0)
        case .topCenterRightEighth:
            return screen.gridCell(cols: 4, rows: 2, col: 2, row: 0)
        case .topRightEighth:
            return screen.gridCell(cols: 4, rows: 2, col: 3, row: 0)
        case .bottomLeftEighth:
            return screen.gridCell(cols: 4, rows: 2, col: 0, row: 1)
        case .bottomCenterLeftEighth:
            return screen.gridCell(cols: 4, rows: 2, col: 1, row: 1)
        case .bottomCenterRightEighth:
            return screen.gridCell(cols: 4, rows: 2, col: 2, row: 1)
        case .bottomRightEighth:
            return screen.gridCell(cols: 4, rows: 2, col: 3, row: 1)

        // MARK: Maximize
        case .maximize:
            return screen
        case .almostMaximize:
            let inset = floor(min(w, h) * 0.03)
            return screen.insetBy(dx: inset, dy: inset)
        case .maximizeHeight:
            guard let win = window else { return nil }
            return CGRect(x: win.minX, y: y, width: win.width, height: h)

        // MARK: Center (keep current size)
        case .center:
            guard let win = window else { return nil }
            return CGRect(
                x: x + floor((w - win.width) / 2),
                y: y + floor((h - win.height) / 2),
                width: win.width,
                height: win.height
            )
        case .centerProminently:
            let newW = floor(w * 0.8)
            let newH = floor(h * 0.8)
            return CGRect(
                x: x + floor((w - newW) / 2),
                y: y + floor((h - newH) / 2),
                width: newW,
                height: newH
            )

        // MARK: Movement (keep size, shift position)
        case .moveLeft:
            guard let win = window else { return nil }
            return CGRect(x: x, y: win.minY, width: win.width, height: win.height)
        case .moveRight:
            guard let win = window else { return nil }
            return CGRect(x: x + w - win.width, y: win.minY, width: win.width, height: win.height)
        case .moveUp:
            guard let win = window else { return nil }
            return CGRect(x: win.minX, y: y + h - win.height, width: win.width, height: win.height)
        case .moveDown:
            guard let win = window else { return nil }
            return CGRect(x: win.minX, y: y, width: win.width, height: win.height)

        // MARK: Resize (relative to current)
        case .larger:
            guard let win = window else { return nil }
            return win.insetBy(dx: -settings.sizeOffset, dy: -settings.sizeOffset)
        case .smaller:
            guard let win = window else { return nil }
            return win.insetBy(dx: settings.sizeOffset, dy: settings.sizeOffset)
        case .largerWidth:
            guard let win = window else { return nil }
            return CGRect(
                x: win.minX - settings.sizeOffset,
                y: win.minY,
                width: win.width + settings.sizeOffset * 2,
                height: win.height
            )
        case .smallerWidth:
            guard let win = window else { return nil }
            return CGRect(
                x: win.minX + settings.sizeOffset,
                y: win.minY,
                width: win.width - settings.sizeOffset * 2,
                height: win.height
            )
        case .largerHeight:
            guard let win = window else { return nil }
            return CGRect(
                x: win.minX,
                y: win.minY - settings.sizeOffset,
                width: win.width,
                height: win.height + settings.sizeOffset * 2
            )
        case .smallerHeight:
            guard let win = window else { return nil }
            return CGRect(
                x: win.minX,
                y: win.minY + settings.sizeOffset,
                width: win.width,
                height: win.height - settings.sizeOffset * 2
            )

        // MARK: Halve/Double
        case .halveWidthLeft:
            guard let win = window else { return nil }
            return CGRect(x: win.minX, y: win.minY, width: floor(win.width / 2), height: win.height)
        case .halveWidthRight:
            guard let win = window else { return nil }
            let newW = floor(win.width / 2)
            return CGRect(x: win.maxX - newW, y: win.minY, width: newW, height: win.height)
        case .halveHeightUp:
            guard let win = window else { return nil }
            let newH = floor(win.height / 2)
            return CGRect(x: win.minX, y: win.maxY - newH, width: win.width, height: newH)
        case .halveHeightDown:
            guard let win = window else { return nil }
            return CGRect(x: win.minX, y: win.minY, width: win.width, height: floor(win.height / 2))
        case .doubleWidthLeft:
            guard let win = window else { return nil }
            return CGRect(x: win.minX - win.width, y: win.minY, width: win.width * 2, height: win.height)
        case .doubleWidthRight:
            guard let win = window else { return nil }
            return CGRect(x: win.minX, y: win.minY, width: win.width * 2, height: win.height)
        case .doubleHeightUp:
            guard let win = window else { return nil }
            return CGRect(x: win.minX, y: win.minY, width: win.width, height: win.height * 2)
        case .doubleHeightDown:
            guard let win = window else { return nil }
            return CGRect(x: win.minX, y: win.minY - win.height, width: win.width, height: win.height * 2)

        // MARK: Todo Layouts
        case .leftTodo:
            let todoWidth = settings.todoSidebarWidth
            return CGRect(x: x, y: y, width: todoWidth, height: h)
        case .rightTodo:
            let todoWidth = settings.todoSidebarWidth
            return CGRect(x: x + w - todoWidth, y: y, width: todoWidth, height: h)

        // MARK: Special Actions (handled elsewhere)
        case .restore, .nextDisplay, .previousDisplay,
             .tileAll, .cascadeAll, .cascadeActiveApp, .reverseAll, .specified:
            return nil
        }
    }
}
