//
//  GapCalculation.swift
//  tiny_window_manager
//

import Foundation

// MARK: - Gap Calculation

/// Handles applying gaps (padding/margins) between windows and screen edges.
///
/// When windows are tiled side-by-side, we want consistent spacing. But if two windows
/// share an edge, we use half the gap on each side so the total gap between them
/// equals one full gap size (not double).
///
/// Example with 20px gap:
/// ```
/// Screen edge ─── 20px gap ─── [Window A] ─── 10px + 10px ─── [Window B] ─── 20px gap ─── Screen edge
/// ```
class GapCalculation {

    /// Applies gap spacing to a window rectangle.
    ///
    /// - Parameters:
    ///   - rect: The original window rectangle (before gaps)
    ///   - dimension: Which dimensions to apply gaps to (.horizontal, .vertical, or .both)
    ///   - sharedEdges: Edges where this window touches another window (use half gap)
    ///   - gapSize: The gap size in points
    /// - Returns: A new rectangle with gaps applied (smaller than the original)
    static func applyGaps(_ rect: CGRect, dimension: Dimension = .both, sharedEdges: Edge = .none, gapSize: Float) -> CGRect {
        print(#function, "called")

        let fullGap = CGFloat(gapSize)
        let halfGap = fullGap / 2

        // Start by shrinking the rect by the full gap on all sides (for the requested dimensions)
        // insetBy shrinks from both sides, so the rect gets smaller by 2x the gap value
        var result = rect.insetBy(
            dx: dimension.contains(.horizontal) ? fullGap : 0,
            dy: dimension.contains(.vertical) ? fullGap : 0
        )

        // For shared edges (where windows touch), give back half the gap
        // This ensures the total gap between adjacent windows is exactly one full gap
        result = adjustForSharedHorizontalEdges(result, sharedEdges: sharedEdges, dimension: dimension, halfGap: halfGap)
        result = adjustForSharedVerticalEdges(result, sharedEdges: sharedEdges, dimension: dimension, halfGap: halfGap)

        return result
    }

    // MARK: - Private Helpers

    /// Adjusts horizontal edges (left/right) for shared window boundaries
    private static func adjustForSharedHorizontalEdges(_ rect: CGRect, sharedEdges: Edge, dimension: Dimension, halfGap: CGFloat) -> CGRect {
        print(#function, "called")
        guard dimension.contains(.horizontal) else { return rect }

        var result = rect

        // If left edge is shared with another window, use half gap instead of full
        if sharedEdges.contains(.left) {
            result.origin.x -= halfGap      // Move left edge back (outward)
            result.size.width += halfGap    // Increase width to compensate
        }

        // If right edge is shared with another window, use half gap instead of full
        if sharedEdges.contains(.right) {
            result.size.width += halfGap    // Extend right edge outward
        }

        return result
    }

    /// Adjusts vertical edges (top/bottom) for shared window boundaries
    private static func adjustForSharedVerticalEdges(_ rect: CGRect, sharedEdges: Edge, dimension: Dimension, halfGap: CGFloat) -> CGRect {
        print(#function, "called")
        guard dimension.contains(.vertical) else { return rect }

        var result = rect

        // If bottom edge is shared with another window, use half gap instead of full
        if sharedEdges.contains(.bottom) {
            result.origin.y -= halfGap      // Move bottom edge down (outward)
            result.size.height += halfGap   // Increase height to compensate
        }

        // If top edge is shared with another window, use half gap instead of full
        if sharedEdges.contains(.top) {
            result.size.height += halfGap   // Extend top edge upward
        }

        return result
    }
}

// MARK: - Supporting Types

/// Represents which dimensions (horizontal/vertical) to apply an operation to.
/// Uses OptionSet so you can combine values: [.horizontal, .vertical]
struct Dimension: OptionSet {
    let rawValue: Int

    /// Horizontal dimension (left-right / width)
    static let horizontal = Dimension(rawValue: 1 << 0)

    /// Vertical dimension (top-bottom / height)
    static let vertical = Dimension(rawValue: 1 << 1)

    /// Both horizontal and vertical dimensions
    static let both: Dimension = [.horizontal, .vertical]

    /// Neither dimension (no-op)
    static let none: Dimension = []
}

/// Represents screen/window edges.
/// Uses OptionSet so you can combine values: [.left, .top]
struct Edge: OptionSet {
    let rawValue: Int

    static let left = Edge(rawValue: 1 << 0)
    static let right = Edge(rawValue: 1 << 1)
    static let top = Edge(rawValue: 1 << 2)
    static let bottom = Edge(rawValue: 1 << 3)

    /// All four edges
    static let all: Edge = [.left, .right, .top, .bottom]

    /// No edges
    static let none: Edge = []
}
