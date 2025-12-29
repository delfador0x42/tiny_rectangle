//
//  CenterThirdCalculation.swift
//  tiny_window_manager
//
//

import Foundation

/// Positions a window in the CENTER third of the screen.
///
/// Divides the screen into three equal parts and places the window in the middle:
/// - Landscape screens: Window occupies the middle 1/3 horizontally (full height)
///   ```
///   [ left | CENTER | right ]
///   ```
/// - Portrait screens: Window occupies the middle 1/3 vertically (full width)
///   ```
///   [  top   ]
///   [ CENTER ]
///   [ bottom ]
///   ```
class CenterThirdCalculation: WindowCalculation, OrientationAware {

    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        let screenFrame = params.visibleFrameOfScreen
        return orientationBasedRect(screenFrame)
    }

    // MARK: - Landscape Mode (Wide Screens)

    /// For landscape: window takes the middle 1/3 of width, full height
    func landscapeRect(_ screenFrame: CGRect) -> RectResult {
        // Window is 1/3 of screen width
        let thirdWidth = screenFrame.width / 3.0

        // Position at the start of the middle third (skip the first third)
        let middleThirdStartX = screenFrame.minX + floor(thirdWidth)

        let rect = CGRect(
            x: middleThirdStartX,
            y: screenFrame.minY,
            width: thirdWidth,
            height: screenFrame.height
        )

        return RectResult(rect, subAction: .centerVerticalThird)
    }

    // MARK: - Portrait Mode (Tall Screens)

    /// For portrait: window takes the middle 1/3 of height, full width
    func portraitRect(_ screenFrame: CGRect) -> RectResult {
        // Window is 1/3 of screen height
        let thirdHeight = screenFrame.height / 3.0

        // Position at the start of the middle third (skip the first third)
        let middleThirdStartY = screenFrame.minY + floor(thirdHeight)

        let rect = CGRect(
            x: screenFrame.minX,
            y: middleThirdStartY,
            width: screenFrame.width,
            height: thirdHeight
        )

        return RectResult(rect, subAction: .centerHorizontalThird)
    }

}

