//
//  CenterTwoThirdsCalculation.swift
//  tiny_window_manager
//
//

import Foundation

/// Centers a window that takes up 2/3 (~67%) of the screen.
///
/// The remaining 1/3 is split evenly on both sides (1/6 margin on each side):
/// - Landscape screens: Window is 2/3 of width, centered horizontally (full height)
///   ```
///   [ 1/6 |   2/3 window   | 1/6 ]
///   ```
/// - Portrait screens: Window is 2/3 of height, centered vertically (full width)
///   ```
///   [ 1/6 margin ]
///   [  2/3 window ]
///   [ 1/6 margin ]
///   ```
class CenterTwoThirdsCalculation: WindowCalculation, OrientationAware {

    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        let screenFrame = params.visibleFrameOfScreen
        return orientationBasedRect(screenFrame)
    }

    // MARK: - Landscape Mode (Wide Screens)

    /// For landscape: window takes 2/3 of width, centered horizontally, full height
    func landscapeRect(_ screenFrame: CGRect) -> RectResult {
        // Window takes 2/3 of the screen width
        let windowWidth = screenFrame.width * 2.0 / 3.0

        // Remaining 1/3 is split into two margins (1/6 on each side)
        // So the window starts at 1/6 from the left edge
        let marginWidth = screenFrame.width / 3.0
        let leftMargin = floor(marginWidth / 2.0)

        let rect = CGRect(
            x: screenFrame.minX + leftMargin,
            y: screenFrame.minY,
            width: windowWidth,
            height: screenFrame.height
        )

        return RectResult(rect, subAction: .centerVerticalThird)
    }

    // MARK: - Portrait Mode (Tall Screens)

    /// For portrait: window takes 2/3 of height, centered vertically, full width
    func portraitRect(_ screenFrame: CGRect) -> RectResult {
        // Window takes 2/3 of the screen height
        let windowHeight = screenFrame.height * 2.0 / 3.0

        // Remaining 1/3 is split into two margins (1/6 on each side)
        // So the window starts at 1/6 from the bottom edge
        let marginHeight = screenFrame.height / 3.0
        let bottomMargin = floor(marginHeight / 2.0)

        let rect = CGRect(
            x: screenFrame.minX,
            y: screenFrame.minY + bottomMargin,
            width: screenFrame.width,
            height: windowHeight
        )

        return RectResult(rect, subAction: .centerHorizontalThird)
    }

}

