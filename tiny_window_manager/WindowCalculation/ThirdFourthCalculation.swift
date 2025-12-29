import Foundation

/// Positions a window in the "third fourth" of the screen (the third quarter).
///
/// In landscape mode: Window occupies the third quarter from the left (position 3 of 4).
/// In portrait mode: Window occupies the third quarter from the top (position 2 of 4 from bottom).
///
/// When the user repeatedly triggers this action, it cycles through related window positions.
class ThirdFourthCalculation: WindowCalculation, OrientationAware {

    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        let screen = params.visibleFrameOfScreen

        // Check if we should cycle to the next position in the sequence
        if let nextCalculation = getNextCalculationInCycle(params) {
            return nextCalculation(screen)
        }

        // Default: position window based on screen orientation
        return orientationBasedRect(screen)
    }

    // MARK: - Orientation-Based Positioning

    func landscapeRect(_ visibleFrameOfScreen: CGRect) -> RectResult {
        let screen = visibleFrameOfScreen
        let quarterWidth = floor(screen.width / 4.0)

        // Position at the third quarter (skip first two quarters)
        let xPosition = screen.minX + (quarterWidth * 2)

        let rect = CGRect(
            x: xPosition,
            y: screen.minY,
            width: quarterWidth,
            height: screen.height
        )

        return RectResult(rect, subAction: .centerRightFourth)
    }

    func portraitRect(_ visibleFrameOfScreen: CGRect) -> RectResult {
        let screen = visibleFrameOfScreen
        let quarterHeight = floor(screen.height / 4.0)

        // Position at the third quarter from the top (one quarter up from bottom)
        let yPosition = screen.minY + screen.height - (quarterHeight * 3.0)

        let rect = CGRect(
            x: screen.minX,
            y: yPosition,
            width: screen.width,
            height: quarterHeight
        )

        return RectResult(rect, subAction: .centerBottomFourth)
    }

    // MARK: - Cycle Through Positions

    /// Returns the next calculation in the cycle sequence, or nil if we should use the default.
    private func getNextCalculationInCycle(_ params: RectCalculationParameters) -> SimpleCalc? {
        // Cycling is disabled if subsequentExecutionMode is .none
        let cyclingEnabled = Defaults.subsequentExecutionMode.value != .none

        guard cyclingEnabled,
              let lastAction = params.lastAction,
              let lastSubAction = lastAction.subAction,
              lastAction.action == .thirdFourth
        else {
            return nil
        }

        // Determine the next position based on what we just did
        switch lastSubAction {
        case .centerRightFourth:
            // Landscape: after third-fourth, go to first-three-fourths
            return WindowCalculationFactory.firstThreeFourthsCalculation.landscapeRect

        case .centerBottomFourth:
            // Portrait: after third-fourth, go to first-three-fourths
            return WindowCalculationFactory.firstThreeFourthsCalculation.portraitRect

        case .leftThreeFourths:
            // Landscape: after first-three-fourths, go to center-half
            return WindowCalculationFactory.centerHalfCalculation.landscapeRect

        case .topThreeFourths:
            // Portrait: after first-three-fourths, go to center-half
            return WindowCalculationFactory.centerHalfCalculation.portraitRect

        default:
            // After center-half (or anything else), cycle back to third-fourth
            return orientationBasedRect
        }
    }
}
