//
//  CGExtension.swift
//  tiny_window_manager
//
//  These extensions help with coordinate system conversions and geometry calculations.
//
//  IMPORTANT CONCEPT - Coordinate System Differences:
//  - Core Graphics (CG) uses a "flipped" coordinate system where Y=0 is at the BOTTOM of the screen
//  - AppKit/Cocoa uses a coordinate system where Y=0 is at the TOP of the screen
//  - When working with windows, we often need to convert between these two systems
//

import Foundation

// MARK: - CGPoint Extension

extension CGPoint {

    /// Converts this point from Core Graphics coordinates to screen (AppKit) coordinates.
    ///
    /// Core Graphics: Y increases upward (bottom = 0)
    /// Screen/AppKit: Y increases downward (top = 0)
    ///
    /// The formula subtracts our Y from the screen height to flip it.
    ///
    var screenFlipped: CGPoint {
        // Get the main screen's height (screens[0] is the primary display)
        let mainScreenHeight = NSScreen.screens[0].frame.maxY

        // Flip the Y coordinate: subtract from screen height
        let flippedY = mainScreenHeight - y

        return CGPoint(x: x, y: flippedY)
    }
}

// MARK: - CGRect Extension

extension CGRect {

    /// Converts this rectangle from Core Graphics coordinates to screen (AppKit) coordinates.
    ///
    /// This is trickier than flipping a point because we need to flip based on
    /// the rectangle's TOP edge (maxY), not its origin, to keep the rect in the same
    /// visual position after the coordinate system flip.
    ///
    var screenFlipped: CGRect {
        // CGRect.null is a special "invalid" rectangle - just return it unchanged
        guard !isNull else {
            return self
        }

        // Get the main screen's height
        let mainScreenHeight = NSScreen.screens[0].frame.maxY

        // Calculate the new Y origin by flipping the rectangle's top edge (maxY)
        // We use maxY (not origin.y) because after flipping, what was the top becomes the origin
        let flippedY = mainScreenHeight - maxY

        let newOrigin = CGPoint(x: origin.x, y: flippedY)

        return CGRect(origin: newOrigin, size: size)
    }

    /// Returns true if the rectangle is wider than it is tall.
    ///
    var isLandscape: Bool {
        return width > height
    }

    /// Returns the center point of this rectangle.
    ///
    var centerPoint: CGPoint {
        let centerX = NSMidX(self)  // Calculates origin.x + (width / 2)
        let centerY = NSMidY(self)  // Calculates origin.y + (height / 2)

        return NSMakePoint(centerX, centerY)
    }

    /// Counts how many edges this rectangle shares with another rectangle.
    ///
    /// Two rectangles "share an edge" when their edges are at the exact same position.
    /// This is useful for detecting adjacent windows (e.g., tiled side-by-side).
    ///
    /// - Parameter rect: The other rectangle to compare against.
    /// - Returns: A count from 0 to 4 indicating how many edges align.
    ///
    /// Example: Two windows tiled left/right would share 3 edges (top, bottom, and the middle edge).
    ///
    func numSharedEdges(withRect rect: CGRect) -> Int {
        print(#function, "called")
        var sharedEdgeCount = 0

        // Check left edges
        if minX == rect.minX {
            sharedEdgeCount += 1
        }

        // Check right edges
        if maxX == rect.maxX {
            sharedEdgeCount += 1
        }

        // Check bottom edges
        if minY == rect.minY {
            sharedEdgeCount += 1
        }

        // Check top edges
        if maxY == rect.maxY {
            sharedEdgeCount += 1
        }

        return sharedEdgeCount
    }
}
