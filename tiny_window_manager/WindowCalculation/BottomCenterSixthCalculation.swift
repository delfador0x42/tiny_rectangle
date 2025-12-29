//
//  BottomCenterSixthCalculation.swift
//  tiny_window_manager
//
//

import Foundation

// MARK: - Screen Division Constants

/// Constants for dividing the screen into fractions.
/// "Sixths" means a 3x2 grid in landscape, or 2x3 grid in portrait.
private enum ScreenFraction {
    static let oneThird: CGFloat = 1.0 / 3.0
    static let twoThirds: CGFloat = 2.0 / 3.0
    static let oneHalf: CGFloat = 1.0 / 2.0
}

// MARK: - BottomCenterSixthCalculation

/// Positions a window in the bottom-center sixth of the screen.
/// Supports cycling through related positions when triggered repeatedly.
class BottomCenterSixthCalculation: WindowCalculation, OrientationAware {

    // Calculators for cycling to adjacent positions
    private let bottomRightTwoSixths = BottomRightTwoSixthsCalculation()
    private let bottomLeftTwoSixths = BottomLeftTwoSixthsCalculation()
    private let topRightTwoSixths = TopRightTwoSixthsCalculation()

    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        let screenFrame = params.visibleFrameOfScreen

        // If cycling is disabled or this is the first action, use default position
        guard let nextCalculation = nextCalculationInCycle(for: params) else {
            return orientationBasedRect(screenFrame)
        }

        return nextCalculation(screenFrame)
    }

    /// Determines the next calculator in the cycle based on the last action.
    /// Returns nil if cycling should not occur.
    private func nextCalculationInCycle(for params: RectCalculationParameters) -> SimpleCalc? {
        let isCyclingEnabled = Defaults.subsequentExecutionMode.value != .none
        let isRepeatedAction = params.action == .bottomCenterSixth

        guard isCyclingEnabled,
              isRepeatedAction,
              let lastSubAction = params.lastAction?.subAction else {
            return nil
        }

        switch lastSubAction {
        case .bottomCenterSixthLandscape, .rightCenterSixthPortrait:
            return bottomRightTwoSixths.orientationBasedRect
        case .bottomRightTwoSixthsLandscape:
            return bottomLeftTwoSixths.orientationBasedRect
        case .bottomRightTwoSixthsPortrait:
            return topRightTwoSixths.orientationBasedRect
        default:
            return orientationBasedRect
        }
    }

    /// Landscape: Bottom row, center column (1/3 width, 1/2 height).
    func landscapeRect(_ screenFrame: CGRect) -> RectResult {
        let width = floor(screenFrame.width * ScreenFraction.oneThird)
        let height = floor(screenFrame.height * ScreenFraction.oneHalf)

        // Position in center column (offset by one column width)
        let x = screenFrame.origin.x + width
        let y = screenFrame.origin.y

        let rect = CGRect(x: x, y: y, width: width, height: height)
        return RectResult(rect, subAction: .bottomCenterSixthLandscape)
    }

    /// Portrait: Right column, center row (1/2 width, 1/3 height).
    func portraitRect(_ screenFrame: CGRect) -> RectResult {
        let width = floor(screenFrame.width * ScreenFraction.oneHalf)
        let height = floor(screenFrame.height * ScreenFraction.oneThird)

        // Position in right column, center row
        let x = screenFrame.origin.x + width
        let y = screenFrame.origin.y + height

        let rect = CGRect(x: x, y: y, width: width, height: height)
        return RectResult(rect, subAction: .rightCenterSixthPortrait)
    }
}

// MARK: - BottomRightTwoSixthsCalculation

/// Positions a window to cover the bottom-right two-sixths of the screen.
class BottomRightTwoSixthsCalculation: WindowCalculation, OrientationAware {

    /// Landscape: Bottom row, right two columns (2/3 width, 1/2 height).
    func landscapeRect(_ screenFrame: CGRect) -> RectResult {
        let width = floor(screenFrame.width * ScreenFraction.twoThirds)
        let height = floor(screenFrame.height * ScreenFraction.oneHalf)

        // Align to right edge
        let x = screenFrame.maxX - width
        let y = screenFrame.origin.y

        let rect = CGRect(x: x, y: y, width: width, height: height)
        return RectResult(rect, subAction: .bottomRightTwoSixthsLandscape)
    }

    /// Portrait: Right column, bottom two rows (1/2 width, 2/3 height).
    func portraitRect(_ screenFrame: CGRect) -> RectResult {
        let width = floor(screenFrame.width * ScreenFraction.oneHalf)
        let height = floor(screenFrame.height * ScreenFraction.twoThirds)

        // Align to right edge
        let x = screenFrame.maxX - width
        let y = screenFrame.origin.y

        let rect = CGRect(x: x, y: y, width: width, height: height)
        return RectResult(rect, subAction: .bottomRightTwoSixthsPortrait)
    }
}

// MARK: - BottomLeftTwoSixthsCalculation

/// Positions a window to cover the bottom-left two-sixths of the screen.
class BottomLeftTwoSixthsCalculation: WindowCalculation, OrientationAware {

    /// Landscape: Bottom row, left two columns (2/3 width, 1/2 height).
    func landscapeRect(_ screenFrame: CGRect) -> RectResult {
        let width = floor(screenFrame.width * ScreenFraction.twoThirds)
        let height = floor(screenFrame.height * ScreenFraction.oneHalf)

        // Align to left edge (use screen origin)
        let rect = CGRect(
            x: screenFrame.origin.x,
            y: screenFrame.origin.y,
            width: width,
            height: height
        )
        return RectResult(rect, subAction: .bottomLeftTwoSixthsLandscape)
    }

    /// Portrait: Left column, bottom two rows (1/2 width, 2/3 height).
    func portraitRect(_ screenFrame: CGRect) -> RectResult {
        let width = floor(screenFrame.width * ScreenFraction.oneHalf)
        let height = floor(screenFrame.height * ScreenFraction.twoThirds)

        // Align to left edge (use screen origin)
        let rect = CGRect(
            x: screenFrame.origin.x,
            y: screenFrame.origin.y,
            width: width,
            height: height
        )
        return RectResult(rect, subAction: .bottomLeftTwoSixthsPortrait)
    }
}
