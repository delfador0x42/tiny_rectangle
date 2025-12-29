//
//  CenterHalfCalculation.swift
//  tiny_window_manager
//
//

import Foundation

/// Centers a window on screen at a fraction of the screen size (default: half).
///
/// Behavior depends on screen orientation:
/// - Landscape screens: Window takes a fraction of the WIDTH (full height)
/// - Portrait screens: Window takes a fraction of the HEIGHT (full width)
///
/// Supports cycling through sizes (half → two-thirds → one-third) on repeated executions.
class CenterHalfCalculation: WindowCalculation, OrientationAware, RepeatedExecutionsInThirdsCalculation {

    // MARK: - Main Calculation Entry Points

    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        // Check if we should cycle through different sizes (half → two-thirds → one-third)
        let hasRepeatedAction = params.lastAction != nil && Defaults.subsequentExecutionMode.resizes
        let cyclingEnabled = Defaults.centerHalfCycles.userEnabled

        if hasRepeatedAction || cyclingEnabled {
            return calculateRepeatedRect(params)
        }

        // Default: just center at half size based on screen orientation
        return orientationBasedRect(params.visibleFrameOfScreen)
    }

    /// Called by RepeatedExecutionsInThirdsCalculation protocol to get rect at a specific fraction
    func calculateFractionalRect(_ params: RectCalculationParameters, fraction: Float) -> RectResult {
        let screenFrame = params.visibleFrameOfScreen

        if screenFrame.isLandscape {
            return landscapeRect(screenFrame, fraction: fraction)
        } else {
            return portraitRect(screenFrame, fraction: fraction)
        }
    }

    // MARK: - Landscape Mode (Wide Screens)

    /// For landscape screens: window takes a fraction of screen WIDTH, full height, centered
    func landscapeRect(_ screenFrame: CGRect, fraction: Float) -> RectResult {
        // Calculate the new window size
        let windowWidth = round(screenFrame.width * CGFloat(fraction))
        let windowHeight = screenFrame.height

        // Calculate centered position
        let horizontalSpace = screenFrame.width - windowWidth
        let horizontalOffset = round(horizontalSpace / 2.0)
        let centeredX = screenFrame.minX + horizontalOffset

        // Height matches screen, so no vertical offset needed for centering
        let centeredY = screenFrame.minY

        let rect = CGRect(x: centeredX, y: centeredY, width: windowWidth, height: windowHeight)
        return RectResult(rect, subAction: .centerVerticalHalf)
    }

    /// Convenience: landscape rect at default 50% width
    func landscapeRect(_ screenFrame: CGRect) -> RectResult {
        return landscapeRect(screenFrame, fraction: 0.5)
    }

    // MARK: - Portrait Mode (Tall Screens)

    /// For portrait screens: window takes a fraction of screen HEIGHT, full width, centered
    func portraitRect(_ screenFrame: CGRect, fraction: Float) -> RectResult {
        // Calculate the new window size
        let windowWidth = screenFrame.width
        let windowHeight = round(screenFrame.height * CGFloat(fraction))

        // Width matches screen, so no horizontal offset needed for centering
        let centeredX = screenFrame.minX

        // Calculate centered vertical position
        let verticalSpace = screenFrame.height - windowHeight
        let verticalOffset = round(verticalSpace / 2.0)
        let centeredY = screenFrame.minY + verticalOffset

        let rect = CGRect(x: centeredX, y: centeredY, width: windowWidth, height: windowHeight)
        return RectResult(rect, subAction: .centerHorizontalHalf)
    }

    /// Convenience: portrait rect at default 50% height
    func portraitRect(_ screenFrame: CGRect) -> RectResult {
        return portraitRect(screenFrame, fraction: 0.5)
    }

}

