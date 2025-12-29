//
//  ChangeSizeCalculation.swift
//  tiny_window_manager, Ported from Spectacle
//
//

import Foundation

/// Handles growing or shrinking a window by a fixed step size.
///
/// Supports these actions:
/// - `larger` / `smaller`: Resize both width AND height
/// - `largerWidth` / `smallerWidth`: Resize only width
/// - `largerHeight` / `smallerHeight`: Resize only height
///
/// When resizing, the window grows/shrinks from its CENTER (equal amounts on each side).
///
/// **Curtain Mode**: When enabled, if a window edge is against the screen edge,
/// it stays pinned there while the opposite edge moves. This lets you "pull"
/// a window away from an edge like opening a curtain.
class ChangeSizeCalculation: WindowCalculation, ChangeWindowDimensionCalculation {

    // MARK: - Configuration

    /// How close (in pixels) a window must be to a screen edge to count as "against" it
    let screenEdgeGapSize: CGFloat

    /// How many pixels to grow/shrink by for general resize (default: 30)
    let sizeOffsetAbs: CGFloat

    /// Whether to use "curtain" mode (pin edges that are against screen edges)
    let curtainChangeSize: Bool

    /// How many pixels to grow/shrink for width-only changes
    var widthOffsetAbs: CGFloat {
        CGFloat(Defaults.widthStepSize.value)
    }

    override init() {
        // Use gap size setting, or default to 5 pixels
        let windowGapSize = Defaults.gapSize.value
        screenEdgeGapSize = windowGapSize > 0 ? CGFloat(windowGapSize) : 5.0

        // Use size offset setting, or default to 30 pixels
        let defaultSizeOffset = Defaults.sizeOffset.value
        sizeOffsetAbs = defaultSizeOffset > 0 ? CGFloat(defaultSizeOffset) : 30.0

        curtainChangeSize = Defaults.curtainChangeSize.enabled != false
    }

    // MARK: - Main Calculation

    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        let screenFrame = params.visibleFrameOfScreen
        let originalWindowRect = params.window.rect

        // Step 1: Determine how much to resize (positive = grow, negative = shrink)
        let sizeOffset = calculateSizeOffset(for: params.action)

        // Step 2: Start with the original window
        var resizedRect = originalWindowRect

        // Step 3: Apply width changes if needed
        let widthActions: [WindowAction] = [.larger, .smaller, .largerWidth, .smallerWidth]
        if widthActions.contains(params.action) {
            resizedRect = applyWidthChange(
                to: resizedRect,
                originalRect: originalWindowRect,
                screenFrame: screenFrame,
                offset: sizeOffset
            )
        }

        // Step 4: Apply height changes if needed
        let heightActions: [WindowAction] = [.larger, .smaller, .largerHeight, .smallerHeight]
        if heightActions.contains(params.action) {
            resizedRect = applyHeightChange(
                to: resizedRect,
                originalRect: originalWindowRect,
                screenFrame: screenFrame,
                offset: sizeOffset,
                action: params.action
            )
        }

        // Step 5: Special case - when window fills the entire screen and we're shrinking,
        // shrink equally from all sides to keep it centered
        let isAgainstAllEdges = againstAllScreenEdges(windowRect: originalWindowRect, visibleFrameOfScreen: screenFrame)
        let isShrinking = sizeOffset < 0

        if isAgainstAllEdges && isShrinking {
            resizedRect = shrinkFromCenter(originalWindowRect, by: sizeOffset)
        }

        // Step 6: Prevent making the window too small
        let shrinkActions: [WindowAction] = [.smaller, .smallerWidth, .smallerHeight]
        let isTooSmall = resizedWindowRectIsTooSmall(windowRect: resizedRect, visibleFrameOfScreen: screenFrame)

        if shrinkActions.contains(params.action) && isTooSmall {
            resizedRect = originalWindowRect  // Cancel the resize
        }

        return RectResult(resizedRect)
    }

    // MARK: - Size Offset Calculation

    /// Determines the pixel offset based on the action (positive = grow, negative = shrink)
    private func calculateSizeOffset(for action: WindowAction) -> CGFloat {
        switch action {
        case .larger, .largerHeight:
            return sizeOffsetAbs
        case .smaller, .smallerHeight:
            return -sizeOffsetAbs
        case .largerWidth:
            return widthOffsetAbs
        case .smallerWidth:
            return -widthOffsetAbs
        default:
            return 0
        }
    }

    // MARK: - Width Changes

    /// Applies a width change to the window, growing/shrinking from center
    private func applyWidthChange(
        to rect: CGRect,
        originalRect: CGRect,
        screenFrame: CGRect,
        offset: CGFloat
    ) -> CGRect {
        var result = rect

        // Change width and shift X to keep centered (half the offset on each side)
        result.size.width = rect.width + offset
        result.origin.x = rect.minX - floor(offset / 2.0)

        // In curtain mode, keep edges that were against screen edges pinned
        if curtainChangeSize {
            result = adjustForHorizontalScreenEdges(
                originalWindowRect: originalRect,
                resizedWindowRect: result,
                visibleFrameOfScreen: screenFrame
            )
        }

        // Don't let window exceed screen width
        if result.width >= screenFrame.width {
            result.size.width = screenFrame.width
        }

        return result
    }

    // MARK: - Height Changes

    /// Applies a height change to the window, growing/shrinking from center
    private func applyHeightChange(
        to rect: CGRect,
        originalRect: CGRect,
        screenFrame: CGRect,
        offset: CGFloat,
        action: WindowAction
    ) -> CGRect {
        var result = rect

        // Change height and shift Y to keep centered (half the offset on each side)
        result.size.height = rect.height + offset
        result.origin.y = rect.minY - floor(offset / 2.0)

        // In curtain mode, keep edges pinned (but not when shrinking height only)
        if curtainChangeSize && action != .smallerHeight {
            result = adjustForVerticalScreenEdges(
                originalWindowRect: originalRect,
                resizedWindowRect: result,
                visibleFrameOfScreen: screenFrame
            )
        }

        // Don't let window exceed screen height
        if result.height >= screenFrame.height {
            result.size.height = screenFrame.height
            result.origin.y = originalRect.minY  // Keep original Y position
        }

        return result
    }

    /// Shrinks a window equally from all sides (used when window fills screen)
    private func shrinkFromCenter(_ rect: CGRect, by offset: CGFloat) -> CGRect {
        var result = rect
        result.size.width = rect.width + offset
        result.origin.x = rect.origin.x - floor(offset / 2.0)
        result.size.height = rect.height + offset
        result.origin.y = rect.origin.y - floor(offset / 2.0)
        return result
    }

    // MARK: - Screen Edge Detection

    /// Checks if a gap is small enough to count as "against" the screen edge
    private func againstScreenEdge(_ gap: CGFloat) -> Bool {
        return abs(gap) <= screenEdgeGapSize
    }

    private func againstLeftScreenEdge(_ windowRect: CGRect, _ screenFrame: CGRect) -> Bool {
        return againstScreenEdge(windowRect.minX - screenFrame.minX)
    }

    private func againstRightScreenEdge(_ windowRect: CGRect, _ screenFrame: CGRect) -> Bool {
        return againstScreenEdge(windowRect.maxX - screenFrame.maxX)
    }

    private func againstTopScreenEdge(_ windowRect: CGRect, _ screenFrame: CGRect) -> Bool {
        return againstScreenEdge(windowRect.maxY - screenFrame.maxY)
    }

    private func againstBottomScreenEdge(_ windowRect: CGRect, _ screenFrame: CGRect) -> Bool {
        return againstScreenEdge(windowRect.minY - screenFrame.minY)
    }

    /// Checks if window is touching all four screen edges (i.e., maximized)
    private func againstAllScreenEdges(windowRect: CGRect, visibleFrameOfScreen: CGRect) -> Bool {
        return againstLeftScreenEdge(windowRect, visibleFrameOfScreen)
            && againstRightScreenEdge(windowRect, visibleFrameOfScreen)
            && againstTopScreenEdge(windowRect, visibleFrameOfScreen)
            && againstBottomScreenEdge(windowRect, visibleFrameOfScreen)
    }

    // MARK: - Curtain Mode Edge Adjustments

    /// Adjusts window position to keep horizontal edges pinned to screen edges
    /// (used in curtain mode when growing/shrinking width)
    private func adjustForHorizontalScreenEdges(
        originalWindowRect: CGRect,
        resizedWindowRect: CGRect,
        visibleFrameOfScreen screenFrame: CGRect
    ) -> CGRect {
        var result = resizedWindowRect
        let gapSize = CGFloat(Defaults.gapSize.value)

        // If right edge was against screen, keep it there
        if againstRightScreenEdge(originalWindowRect, screenFrame) {
            result.origin.x = screenFrame.maxX - result.width - gapSize

            // If BOTH edges were against screen, window spans full width (minus gaps)
            if againstLeftScreenEdge(originalWindowRect, screenFrame) {
                result.size.width = screenFrame.width - (gapSize * 2)
            }
        }

        // If left edge was against screen, keep it there
        if againstLeftScreenEdge(originalWindowRect, screenFrame) {
            result.origin.x = screenFrame.minX + gapSize
        }

        return result
    }

    /// Adjusts window position to keep vertical edges pinned to screen edges
    /// (used in curtain mode when growing/shrinking height)
    private func adjustForVerticalScreenEdges(
        originalWindowRect: CGRect,
        resizedWindowRect: CGRect,
        visibleFrameOfScreen screenFrame: CGRect
    ) -> CGRect {
        var result = resizedWindowRect
        let gapSize = CGFloat(Defaults.gapSize.value)

        // If top edge was against screen, keep it there
        if againstTopScreenEdge(originalWindowRect, screenFrame) {
            result.origin.y = screenFrame.maxY - result.height - gapSize

            // If BOTH edges were against screen, window spans full height (minus gaps)
            if againstBottomScreenEdge(originalWindowRect, screenFrame) {
                result.size.height = screenFrame.height - (gapSize * 2)
            }
        }

        // If bottom edge was against screen, keep it there
        if againstBottomScreenEdge(originalWindowRect, screenFrame) {
            result.origin.y = screenFrame.minY + gapSize
        }

        return result
    }

}
