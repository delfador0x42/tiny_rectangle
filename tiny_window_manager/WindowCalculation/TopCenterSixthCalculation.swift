import Foundation

// MARK: - Screen Grid Layout
//
// The screen is divided into a 3×2 grid of "sixths":
//
// LANDSCAPE (3 columns × 2 rows):        PORTRAIT (2 columns × 3 rows):
// ┌─────┬─────┬─────┐                    ┌─────┬─────┐
// │ TL  │ TC  │ TR  │  (top row)         │ TL  │ TR  │  (top row)
// ├─────┼─────┼─────┤                    ├─────┼─────┤
// │ BL  │ BC  │ BR  │  (bottom row)      │ LC  │ RC  │  (center row)
// └─────┴─────┴─────┘                    ├─────┼─────┤
//                                        │ BL  │ BR  │  (bottom row)
//                                        └─────┴─────┘

/// Positions a window in the top-center sixth of the screen.
///
/// In landscape: The middle cell of the top row (TC in the diagram above).
/// In portrait: The left cell of the center row (LC in the diagram above).
///
/// When repeatedly triggered, cycles through: top-center → top-right-two-sixths → top-left-two-sixths → (repeat)
class TopCenterSixthCalculation: WindowCalculation, OrientationAware {

    private let topRightTwoSixths = TopRightTwoSixthsCalculation()
    private let topLeftTwoSixths = TopLeftTwoSixthsCalculation()
    private let bottomLeftTwoSixths = BottomLeftTwoSixthsCalculation()

    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {
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
        let screen = visibleFrameOfScreen

        // One-sixth size: 1/3 of width, 1/2 of height
        let cellWidth = floor(screen.width / 3.0)
        let cellHeight = floor(screen.height / 2.0)

        // Position: center column, top row
        let xPosition = screen.minX + cellWidth  // Skip first column
        let yPosition = screen.maxY - cellHeight // Top row (macOS y=0 is at bottom)

        let rect = CGRect(x: xPosition, y: yPosition, width: cellWidth, height: cellHeight)
        return RectResult(rect, subAction: .topCenterSixthLandscape)
    }

    func portraitRect(_ visibleFrameOfScreen: CGRect) -> RectResult {
        let screen = visibleFrameOfScreen

        // One-sixth size: 1/2 of width, 1/3 of height
        let cellWidth = floor(screen.width / 2.0)
        let cellHeight = floor(screen.height / 3.0)

        // Position: left column, center row
        let xPosition = screen.minX
        let yPosition = screen.minY + cellHeight  // Skip bottom row

        let rect = CGRect(x: xPosition, y: yPosition, width: cellWidth, height: cellHeight)
        return RectResult(rect, subAction: .leftCenterSixthPortrait)
    }

    // MARK: - Cycle Through Positions

    private func getNextCalculationInCycle(_ params: RectCalculationParameters) -> SimpleCalc? {
        let cyclingEnabled = Defaults.subsequentExecutionMode.value != .none

        guard cyclingEnabled,
              let lastAction = params.lastAction,
              let lastSubAction = lastAction.subAction,
              params.action == .topCenterSixth
        else {
            return nil
        }

        switch lastSubAction {
        case .topCenterSixthLandscape:
            // Landscape: after top-center, go to top-right two-sixths
            return topRightTwoSixths.orientationBasedRect

        case .leftCenterSixthPortrait:
            // Portrait: after left-center, go to bottom-left two-sixths
            return bottomLeftTwoSixths.orientationBasedRect

        case .topRightTwoSixthsLandscape, .bottomLeftTwoSixthsPortrait:
            // After top-right/bottom-left two-sixths, go to top-left two-sixths
            return topLeftTwoSixths.orientationBasedRect

        default:
            // Cycle back to top-center
            return orientationBasedRect
        }
    }
}

/// Positions a window covering the top-right two-sixths of the screen.
///
/// In landscape: The top row's center and right cells (TC + TR = 2/3 width, 1/2 height).
/// In portrait: The right column's top and center cells (TR + RC = 1/2 width, 2/3 height).
class TopRightTwoSixthsCalculation: WindowCalculation, OrientationAware {

    func landscapeRect(_ visibleFrameOfScreen: CGRect) -> RectResult {
        let screen = visibleFrameOfScreen

        // Two-sixths size: 2/3 of width, 1/2 of height
        let width = floor(screen.width * 2.0 / 3.0)
        let height = floor(screen.height / 2.0)

        // Position: right-aligned, top row
        let xPosition = screen.maxX - width
        let yPosition = screen.maxY - height

        let rect = CGRect(x: xPosition, y: yPosition, width: width, height: height)
        return RectResult(rect, subAction: .topRightTwoSixthsLandscape)
    }

    func portraitRect(_ visibleFrameOfScreen: CGRect) -> RectResult {
        let screen = visibleFrameOfScreen

        // Two-sixths size: 1/2 of width, 2/3 of height
        let width = floor(screen.width / 2.0)
        let height = floor(screen.height * 2.0 / 3.0)

        // Position: right column, top-aligned
        let xPosition = screen.maxX - width
        let yPosition = screen.maxY - height

        let rect = CGRect(x: xPosition, y: yPosition, width: width, height: height)
        return RectResult(rect, subAction: .topRightTwoSixthsPortrait)
    }
}

/// Positions a window covering the top-left two-sixths of the screen.
///
/// In landscape: The top row's left and center cells (TL + TC = 2/3 width, 1/2 height).
/// In portrait: The left column's top and center cells (TL + LC = 1/2 width, 2/3 height).
class TopLeftTwoSixthsCalculation: WindowCalculation, OrientationAware {

    func landscapeRect(_ visibleFrameOfScreen: CGRect) -> RectResult {
        let screen = visibleFrameOfScreen

        // Two-sixths size: 2/3 of width, 1/2 of height
        let width = floor(screen.width * 2.0 / 3.0)
        let height = floor(screen.height / 2.0)

        // Position: left-aligned, top row
        let xPosition = screen.minX
        let yPosition = screen.maxY - height

        let rect = CGRect(x: xPosition, y: yPosition, width: width, height: height)
        return RectResult(rect, subAction: .topLeftTwoSixthsLandscape)
    }

    func portraitRect(_ visibleFrameOfScreen: CGRect) -> RectResult {
        let screen = visibleFrameOfScreen

        // Two-sixths size: 1/2 of width, 2/3 of height
        let width = floor(screen.width / 2.0)
        let height = floor(screen.height * 2.0 / 3.0)

        // Position: left column, top-aligned
        let xPosition = screen.minX
        let yPosition = screen.maxY - height

        let rect = CGRect(x: xPosition, y: yPosition, width: width, height: height)
        return RectResult(rect, subAction: .topLeftTwoSixthsPortrait)
    }
}
