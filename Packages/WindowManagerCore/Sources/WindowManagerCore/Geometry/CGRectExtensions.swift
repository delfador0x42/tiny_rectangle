//  CGRectExtensions.swift - Pure CGRect extensions
//
//  Geometry helper extensions for window calculations.
//  No AppKit/Cocoa dependencies.

import CoreGraphics

// MARK: - CGRect Extensions

public extension CGRect {

    /// Returns true if this rect is centered within the given rect (within 1pt tolerance).
    func isCentered(within container: CGRect) -> Bool {
        let centeredMidX = abs(container.midX - midX) <= 1.0
        let centeredMidY = abs(container.midY - midY) <= 1.0
        return container.contains(self) && centeredMidX && centeredMidY
    }

    /// Returns true if this rect fits within the given rect.
    func fits(within container: CGRect) -> Bool {
        return width <= container.width && height <= container.height
    }

    /// Returns this rect flipped vertically within a screen of the given height.
    /// macOS uses bottom-left origin for screen coordinates but top-left for some APIs.
    func flipped(in screenHeight: CGFloat) -> CGRect {
        CGRect(
            x: origin.x,
            y: screenHeight - origin.y - height,
            width: width,
            height: height
        )
    }

    /// Returns a grid cell rectangle within this rect.
    /// - Parameters:
    ///   - cols: Number of columns in the grid
    ///   - rows: Number of rows in the grid
    ///   - col: Column index (0-based, from left)
    ///   - row: Row index (0-based, from top)
    func gridCell(cols: Int, rows: Int, col: Int, row: Int) -> CGRect {
        let cellWidth = floor(width / CGFloat(cols))
        let cellHeight = floor(height / CGFloat(rows))
        // Row 0 is top, so we flip the y calculation
        let yPos = maxY - cellHeight * CGFloat(row + 1)
        return CGRect(
            x: minX + cellWidth * CGFloat(col),
            y: yPos,
            width: cellWidth,
            height: cellHeight
        )
    }

    /// Returns a rect representing a horizontal slice (column) of this rect.
    /// - Parameters:
    ///   - index: The slice index (0-based from left)
    ///   - of: Total number of slices
    func horizontalSlice(index: Int, of total: Int) -> CGRect {
        let sliceWidth = floor(width / CGFloat(total))
        return CGRect(
            x: minX + sliceWidth * CGFloat(index),
            y: minY,
            width: sliceWidth,
            height: height
        )
    }

    /// Returns a rect representing a vertical slice (row) of this rect.
    /// - Parameters:
    ///   - index: The slice index (0-based from top)
    ///   - of: Total number of slices
    func verticalSlice(index: Int, of total: Int) -> CGRect {
        let sliceHeight = floor(height / CGFloat(total))
        // Index 0 is top, so we flip the y calculation
        let yPos = maxY - sliceHeight * CGFloat(index + 1)
        return CGRect(
            x: minX,
            y: yPos,
            width: width,
            height: sliceHeight
        )
    }

    /// Whether this rect is in landscape orientation.
    var isLandscape: Bool {
        width >= height
    }
}

// MARK: - CGSize Extensions

public extension CGSize {

    /// Whether this size is in landscape orientation.
    var isLandscape: Bool {
        width >= height
    }
}

// MARK: - CGPoint Extensions

public extension CGPoint {

    /// Returns the distance to another point.
    func distance(to other: CGPoint) -> CGFloat {
        let dx = other.x - x
        let dy = other.y - y
        return sqrt(dx * dx + dy * dy)
    }
}
