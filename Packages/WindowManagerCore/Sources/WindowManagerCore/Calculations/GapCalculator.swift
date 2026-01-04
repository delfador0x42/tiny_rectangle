//  GapCalculator.swift - Gap/padding calculations
//
//  Pure functions for applying gaps between windows and screen edges.
//  No AppKit/Cocoa dependencies.

import CoreGraphics

// MARK: - GapCalculator

/// Pure functions for calculating window gaps (padding/margins).
///
/// Gaps create visual spacing between:
/// - Windows and screen edges
/// - Adjacent windows
public enum GapCalculator {

    /// Apply gaps to a rectangle.
    /// - Parameters:
    ///   - rect: The original rectangle
    ///   - dimension: Which dimensions to apply gaps to
    ///   - sharedEdges: Edges shared with adjacent windows (use half gap)
    ///   - gapSize: The gap size in points
    /// - Returns: The rectangle with gaps applied
    public static func applyGaps(
        to rect: CGRect,
        dimension: Dimension = .both,
        sharedEdges: Edge = .none,
        gapSize: CGFloat
    ) -> CGRect {
        let halfGap = gapSize / 2

        // Start with full gap inset on requested dimensions
        var result = rect.insetBy(
            dx: dimension.contains(.horizontal) ? gapSize : 0,
            dy: dimension.contains(.vertical) ? gapSize : 0
        )

        // Adjust shared edges (internal edges between windows get half gap)
        result = adjustForSharedHorizontalEdges(result, sharedEdges: sharedEdges, dimension: dimension, halfGap: halfGap)
        result = adjustForSharedVerticalEdges(result, sharedEdges: sharedEdges, dimension: dimension, halfGap: halfGap)

        return result
    }

    /// Apply screen-edge gaps to a rectangle.
    /// - Parameters:
    ///   - rect: The original rectangle
    ///   - screenFrame: The screen's visible frame
    ///   - gapSize: The gap size in points
    /// - Returns: The rectangle with screen-edge gaps applied
    public static func applyScreenEdgeGaps(
        to rect: CGRect,
        screenFrame: CGRect,
        gapSize: CGFloat
    ) -> CGRect {
        var result = rect

        // Gap from screen edges
        if rect.minX <= screenFrame.minX {
            result.origin.x += gapSize
            result.size.width -= gapSize
        }
        if rect.maxX >= screenFrame.maxX {
            result.size.width -= gapSize
        }
        if rect.minY <= screenFrame.minY {
            result.origin.y += gapSize
            result.size.height -= gapSize
        }
        if rect.maxY >= screenFrame.maxY {
            result.size.height -= gapSize
        }

        return result
    }

    /// Determine which edges are shared with adjacent windows.
    /// - Parameters:
    ///   - action: The window action being applied
    /// - Returns: The edges that are shared with adjacent windows
    public static func sharedEdges(for action: WindowActionType) -> Edge {
        switch action {
        // Left half shares right edge
        case .leftHalf, .firstThird, .firstTwoThirds, .firstFourth, .firstThreeFourths:
            return .right

        // Right half shares left edge
        case .rightHalf, .lastThird, .lastTwoThirds, .lastFourth, .lastThreeFourths:
            return .left

        // Center shares both horizontal edges
        case .centerThird, .centerHalf, .centerTwoThirds, .secondFourth, .thirdFourth, .centerThreeFourths:
            return .horizontal

        // Top half shares bottom edge
        case .topHalf:
            return .bottom

        // Bottom half shares top edge
        case .bottomHalf:
            return .top

        // Corners share two edges
        case .topLeft:
            return [.right, .bottom]
        case .topRight:
            return [.left, .bottom]
        case .bottomLeft:
            return [.right, .top]
        case .bottomRight:
            return [.left, .top]

        // Sixths share multiple edges
        case .topLeftSixth:
            return [.right, .bottom]
        case .topCenterSixth:
            return [.left, .right, .bottom]
        case .topRightSixth:
            return [.left, .bottom]
        case .bottomLeftSixth:
            return [.right, .top]
        case .bottomCenterSixth:
            return [.left, .right, .top]
        case .bottomRightSixth:
            return [.left, .top]

        // Full-width/height actions share no edges
        case .maximize, .almostMaximize, .maximizeHeight, .center, .centerProminently:
            return .none

        default:
            return .none
        }
    }

    // MARK: - Private Helpers

    private static func adjustForSharedHorizontalEdges(
        _ rect: CGRect,
        sharedEdges: Edge,
        dimension: Dimension,
        halfGap: CGFloat
    ) -> CGRect {
        guard dimension.contains(.horizontal) else { return rect }

        var result = rect

        if sharedEdges.contains(.left) {
            result.origin.x -= halfGap
            result.size.width += halfGap
        }
        if sharedEdges.contains(.right) {
            result.size.width += halfGap
        }

        return result
    }

    private static func adjustForSharedVerticalEdges(
        _ rect: CGRect,
        sharedEdges: Edge,
        dimension: Dimension,
        halfGap: CGFloat
    ) -> CGRect {
        guard dimension.contains(.vertical) else { return rect }

        var result = rect

        if sharedEdges.contains(.bottom) {
            result.origin.y -= halfGap
            result.size.height += halfGap
        }
        if sharedEdges.contains(.top) {
            result.size.height += halfGap
        }

        return result
    }
}
