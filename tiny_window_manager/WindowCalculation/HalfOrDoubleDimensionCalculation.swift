//
//  HalfOrDoubleDimensionCalculation.swift
//  tiny_window_manager
//

import Foundation

/// Handles resizing windows by halving or doubling their width or height.
///
/// Actions are named by their resize direction:
/// - `halveHeightUp`: Cut height in half, keep top edge fixed (bottom moves up)
/// - `halveHeightDown`: Cut height in half, keep bottom edge fixed (top moves down)
/// - `halveWidthLeft`: Cut width in half, keep left edge fixed (right moves left)
/// - `halveWidthRight`: Cut width in half, keep right edge fixed (left moves right)
/// - `doubleHeightUp`: Double height, expanding upward
/// - `doubleHeightDown`: Double height, expanding downward
/// - `doubleWidthLeft`: Double width, expanding leftward
/// - `doubleWidthRight`: Double width, expanding rightward
///
/// The class also enforces minimum window size when shrinking.
class HalfOrDoubleDimensionCalculation: WindowCalculation, ChangeWindowDimensionCalculation {

    // MARK: - Main Calculation

    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        print(#function, "called")
        let originalRect = params.window.rect
        let action = params.action

        // Step 1: Resize the window (halve or double the appropriate dimension)
        let resizedRect = applyResize(to: originalRect, action: action)

        // Step 2: Reposition if needed (some actions require moving the window)
        var finalRect = applyRepositioning(original: originalRect, resized: resizedRect, action: action)

        // Step 3: If we're shrinking, make sure the result isn't too small
        let isShrinking = isSizeReducingAction(action)
        if isShrinking {
            let isTooSmall = resizedWindowRectIsTooSmall(
                windowRect: finalRect,
                visibleFrameOfScreen: params.visibleFrameOfScreen
            )
            if isTooSmall {
                // Reject the resize - keep the original size
                finalRect = originalRect
            }
        }

        return RectResult(finalRect)
    }

    // MARK: - Action Classification

    /// Returns true if the action makes the window smaller.
    private func isSizeReducingAction(_ action: WindowAction) -> Bool {
        print(#function, "called")
        switch action {
        case .halveHeightUp, .halveHeightDown, .halveWidthLeft, .halveWidthRight:
            return true
        default:
            return false
        }
    }

    // MARK: - Resize Logic

    /// Applies the size change (halve or double) to the window rect.
    ///
    /// This only changes the size, not the position. Position is handled separately.
    private func applyResize(to windowRect: CGRect, action: WindowAction) -> CGRect {
        print(#function, "called")
        var resized = windowRect

        switch action {
        // Halve height (cut in half vertically)
        case .halveHeightUp, .halveHeightDown:
            resized.size.height = resized.height * 0.5

        // Halve width (cut in half horizontally)
        case .halveWidthLeft, .halveWidthRight:
            resized.size.width = resized.width * 0.5

        // Double height (grow vertically)
        case .doubleHeightUp, .doubleHeightDown:
            resized.size.height = resized.height * 2.0

        // Double width (grow horizontally)
        case .doubleWidthLeft, .doubleWidthRight:
            resized.size.width = resized.width * 2.0

        default:
            break
        }

        return resized
    }

    // MARK: - Repositioning Logic

    /// Moves the window if needed after resizing.
    ///
    /// Some actions need to reposition the window to create the effect of a fixed edge.
    /// For example, "halve height up" keeps the top edge fixed, which means we need to
    /// move the window up after shrinking it.
    ///
    /// In macOS coordinates:
    /// - Y increases upward (higher Y = higher on screen)
    /// - X increases rightward (higher X = further right)
    private func applyRepositioning(original originalRect: CGRect, resized resizedRect: CGRect, action: WindowAction) -> CGRect {
        print(#function, "called")
        switch action {

        // "Halve up" = keep top edge fixed
        // After halving, move window up by the new height to keep top aligned
        case .halveHeightUp:
            return resizedRect.offsetBy(dx: 0, dy: resizedRect.height)

        // "Halve right" = keep right edge fixed
        // After halving, move window right by the new width to keep right edge aligned
        case .halveWidthRight:
            return resizedRect.offsetBy(dx: resizedRect.width, dy: 0)

        // "Double down" = expand downward (top edge stays fixed)
        // Move down by original height to expand below
        case .doubleHeightDown:
            return resizedRect.offsetBy(dx: 0, dy: -originalRect.height)

        // "Double left" = expand leftward (right edge stays fixed)
        // Move left by original width to expand to the left
        case .doubleWidthLeft:
            return resizedRect.offsetBy(dx: -originalRect.width, dy: 0)

        // These actions don't need repositioning:
        // - halveHeightDown: bottom edge naturally stays fixed
        // - halveWidthLeft: left edge naturally stays fixed
        // - doubleHeightUp: expanding upward from bottom edge
        // - doubleWidthRight: expanding rightward from left edge
        default:
            return resizedRect
        }
    }
}
