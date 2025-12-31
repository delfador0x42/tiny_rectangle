import Foundation

// MARK: - Screen Grid Layout
//
// The screen is divided into a 3×2 grid of "sixths":
//
// LANDSCAPE (3 columns × 2 rows):        PORTRAIT (2 columns × 3 rows):
// ┌─────┬─────┬─────┐                    ┌─────┬─────┐
// │ TL  │ TC  │[TR] │  (top row)         │ TL  │[TR] │  (top row)
// ├─────┼─────┼─────┤                    ├─────┼─────┤
// │ BL  │ BC  │ BR  │  (bottom row)      │ LC  │ RC  │  (center row)
// └─────┴─────┴─────┘                    ├─────┼─────┤
//                                        │ BL  │ BR  │  (bottom row)
//                                        └─────┴─────┘
// [TR] = This class positions the window here (top-right)

/// Positions a window in the top-right sixth of the screen.
///
/// In landscape: The right cell of the top row (1/3 width, 1/2 height).
/// In portrait: The right cell of the top row (1/2 width, 1/3 height).
///
/// When repeatedly triggered, cycles leftward through the top row:
/// top-right → top-center → top-left → (repeat)
class TopRightSixthCalculation: WindowCalculation, OrientationAware, SixthsRepeated {

    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        print(#function, "called")
        let screen = params.visibleFrameOfScreen

        // Check if we should cycle to the next position
        if let nextCalculation = getNextCalculationInCycle(params) {
            return nextCalculation(screen)
        }

        // Default: position based on screen orientation
        return orientationBasedRect(screen)
    }

    // MARK: - Orientation-Based Positioning

    func landscapeRect(_ visibleFrameOfScreen: CGRect) -> RectResult {
        print(#function, "called")
        let screen = visibleFrameOfScreen

        // One-sixth size: 1/3 of width, 1/2 of height
        let cellWidth = floor(screen.width / 3.0)
        let cellHeight = floor(screen.height / 2.0)

        // Position: right column, top row
        let xPosition = screen.maxX - cellWidth  // Right-aligned
        let yPosition = screen.maxY - cellHeight // Top row (macOS y=0 is at bottom)

        let rect = CGRect(x: xPosition, y: yPosition, width: cellWidth, height: cellHeight)
        return RectResult(rect, subAction: .topRightSixthLandscape)
    }

    func portraitRect(_ visibleFrameOfScreen: CGRect) -> RectResult {
        print(#function, "called")
        let screen = visibleFrameOfScreen

        // One-sixth size: 1/2 of width, 1/3 of height
        let cellWidth = floor(screen.width / 2.0)
        let cellHeight = floor(screen.height / 3.0)

        // Position: right column, top row
        let xPosition = screen.minX + cellWidth  // Skip left column
        let yPosition = screen.maxY - cellHeight // Top row (macOS y=0 is at bottom)

        let rect = CGRect(x: xPosition, y: yPosition, width: cellWidth, height: cellHeight)
        return RectResult(rect, subAction: .topRightSixthPortrait)
    }

    // MARK: - Cycle Through Positions

    private func getNextCalculationInCycle(_ params: RectCalculationParameters) -> SimpleCalc? {
        print(#function, "called")
        let cyclingEnabled = Defaults.subsequentExecutionMode.value != .none

        guard cyclingEnabled,
              let lastAction = params.lastAction,
              let lastSubAction = lastAction.subAction
        else {
            return nil
        }

        // Only cycle if we're continuing from a top-right-sixth action
        let isRelevantAction = lastAction.action == .topRightSixth
        let isRelevantSubAction = lastSubAction == .topRightSixthLandscape
                               || lastSubAction == .topRightSixthPortrait

        guard isRelevantAction || isRelevantSubAction else {
            return nil
        }

        // Cycle leftward through the top row: top-right → top-center → top-left
        return nextCalculation(subAction: lastSubAction, direction: .left)
    }
}
