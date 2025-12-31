//
//  CenterThreeFourthsCalculation.swift
//  tiny_window_manager
//
//

import Foundation

/// Centers a window that takes up 3/4 (75%) of the screen.
///
/// The remaining 1/4 is split evenly on both sides (1/8 margin on each side):
/// - Landscape screens: Window is 3/4 of width, centered horizontally (full height)
///   ```
///   [ 1/8 |   3/4 window   | 1/8 ]
///   ```
/// - Portrait screens: Window is 3/4 of height, centered vertically (full width)
///   ```
///   [ 1/8 margin ]
///   [  3/4 window ]
///   [ 1/8 margin ]
///   ```
class CenterThreeFourthsCalculation: WindowCalculation, OrientationAware {

    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        print(#function, "called")
        let screenFrame = params.visibleFrameOfScreen
        return orientationBasedRect(screenFrame)
    }

    // MARK: - Landscape Mode (Wide Screens)

    /// For landscape: window takes 3/4 of width, centered horizontally, full height
    func landscapeRect(_ screenFrame: CGRect) -> RectResult {
        print(#function, "called")
        // Window takes 3/4 of the screen width
        let windowWidth = screenFrame.width * 3.0 / 4.0

        // Remaining 1/4 is split into two margins (1/8 on each side)
        // So the window starts at 1/8 from the left edge
        let marginWidth = screenFrame.width / 4.0
        let leftMargin = floor(marginWidth / 2.0)

        let rect = CGRect(
            x: screenFrame.minX + leftMargin,
            y: screenFrame.minY,
            width: windowWidth,
            height: screenFrame.height
        )

        return RectResult(rect, subAction: .centerVerticalThreeFourths)
    }

    // MARK: - Portrait Mode (Tall Screens)

    /// For portrait: window takes 3/4 of height, centered vertically, full width
    func portraitRect(_ screenFrame: CGRect) -> RectResult {
        print(#function, "called")
        // Window takes 3/4 of the screen height
        let windowHeight = screenFrame.height * 3.0 / 4.0

        // Remaining 1/4 is split into two margins (1/8 on each side)
        // So the window starts at 1/8 from the bottom edge
        let marginHeight = screenFrame.height / 4.0
        let bottomMargin = floor(marginHeight / 2.0)

        let rect = CGRect(
            x: screenFrame.minX,
            y: screenFrame.minY + bottomMargin,
            width: screenFrame.width,
            height: windowHeight
        )

        return RectResult(rect, subAction: .centerHorizontalThreeFourths)
    }

}

