//
//  BottomLeftSixthCalculation.swift
//  tiny_window_manager
//
//

import Foundation

// MARK: - Screen Division Constants

private enum ScreenFraction {
    static let oneThird: CGFloat = 1.0 / 3.0
    static let oneHalf: CGFloat = 1.0 / 2.0
}

// MARK: - BottomLeftSixthCalculation

/// Positions a window in the bottom-left sixth of the screen.
/// When triggered repeatedly, cycles through positions moving rightward.
class BottomLeftSixthCalculation: WindowCalculation, OrientationAware, SixthsRepeated {

    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        print(#function, "called")
        let screenFrame = params.visibleFrameOfScreen

        // Try to get the next position in the cycle; fall back to default if cycling doesn't apply
        guard let nextCalculation = nextCalculationInCycle(for: params) else {
            return orientationBasedRect(screenFrame)
        }

        return nextCalculation(screenFrame)
    }

    /// Determines the next calculator in the cycle based on the last action.
    /// Returns nil if cycling should not occur.
    private func nextCalculationInCycle(for params: RectCalculationParameters) -> SimpleCalc? {
        print(#function, "called")
        let isCyclingEnabled = Defaults.subsequentExecutionMode.value != .none

        guard isCyclingEnabled,
              let lastAction = params.lastAction,
              let lastSubAction = lastAction.subAction else {
            return nil
        }

        // Only cycle if the last action was related to bottom-left sixth
        let isRelatedAction = lastAction.action == .bottomLeftSixth
            || lastSubAction == .bottomLeftSixthLandscape
            || lastSubAction == .bottomLeftSixthPortrait

        guard isRelatedAction else {
            return nil
        }

        // Get the next position in the cycle (moving rightward)
        return nextCalculation(subAction: lastSubAction, direction: .right)
    }

    /// Landscape: Bottom row, left column (1/3 width, 1/2 height).
    func landscapeRect(_ screenFrame: CGRect) -> RectResult {
        print(#function, "called")
        let width = floor(screenFrame.width * ScreenFraction.oneThird)
        let height = floor(screenFrame.height * ScreenFraction.oneHalf)

        // Anchored to bottom-left corner (screen origin)
        let rect = CGRect(
            x: screenFrame.origin.x,
            y: screenFrame.origin.y,
            width: width,
            height: height
        )

        return RectResult(rect, subAction: .bottomLeftSixthLandscape)
    }

    /// Portrait: Left column, bottom row (1/2 width, 1/3 height).
    func portraitRect(_ screenFrame: CGRect) -> RectResult {
        print(#function, "called")
        let width = floor(screenFrame.width * ScreenFraction.oneHalf)
        let height = floor(screenFrame.height * ScreenFraction.oneThird)

        // Anchored to bottom-left corner (screen origin)
        let rect = CGRect(
            x: screenFrame.origin.x,
            y: screenFrame.origin.y,
            width: width,
            height: height
        )

        return RectResult(rect, subAction: .bottomLeftSixthPortrait)
    }
}
