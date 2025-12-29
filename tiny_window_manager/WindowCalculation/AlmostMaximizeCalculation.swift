//
//  AlmostMaximizeCalculation.swift
//  tiny_window_manager
//
//

import Foundation

/// Calculates a window size that fills most (but not all) of the screen, centered.
/// By default, the window takes up 90% of both width and height.
class AlmostMaximizeCalculation: WindowCalculation {

    private static let defaultScale: CGFloat = 0.9

    let almostMaximizeHeight: CGFloat
    let almostMaximizeWidth: CGFloat

    override init() {
        almostMaximizeHeight = Self.validatedScale(from: Defaults.almostMaximizeHeight.value)
        almostMaximizeWidth = Self.validatedScale(from: Defaults.almostMaximizeWidth.value)
    }

    /// Ensures the scale value is between 0 and 1 (exclusive of 0, inclusive of 1).
    /// Returns the default scale (0.9) if the value is invalid.
    private static func validatedScale(from value: Float) -> CGFloat {
        let isValid = value > 0 && value <= 1
        return isValid ? CGFloat(value) : defaultScale
    }

    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        let screenFrame = params.visibleFrameOfScreen

        let newSize = calculateSize(for: screenFrame)
        let centeredOrigin = calculateCenteredOrigin(for: newSize, in: screenFrame)

        let windowRect = CGRect(origin: centeredOrigin, size: newSize)
        return RectResult(windowRect)
    }

    /// Calculates the window size as a percentage of the screen size.
    private func calculateSize(for screenFrame: CGRect) -> CGSize {
        let width = round(screenFrame.width * almostMaximizeWidth)
        let height = round(screenFrame.height * almostMaximizeHeight)
        return CGSize(width: width, height: height)
    }

    /// Calculates the origin point that centers the window on screen.
    private func calculateCenteredOrigin(for windowSize: CGSize, in screenFrame: CGRect) -> CGPoint {
        let horizontalPadding = screenFrame.width - windowSize.width
        let verticalPadding = screenFrame.height - windowSize.height

        let x = screenFrame.minX + round(horizontalPadding / 2.0)
        let y = screenFrame.minY + round(verticalPadding / 2.0)

        return CGPoint(x: x, y: y)
    }
}

