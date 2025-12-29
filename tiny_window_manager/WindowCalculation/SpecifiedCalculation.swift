import Foundation

/// Calculates a window rectangle with a user-specified size, centered on the screen.
/// The size can be specified as either:
/// - A percentage (0.0 to 1.0) of the screen size
/// - An absolute pixel value (greater than 1)
final class SpecifiedCalculation: WindowCalculation {

    private let specifiedHeight: CGFloat
    private let specifiedWidth: CGFloat

    override init() {
        specifiedHeight = CGFloat(Defaults.specifiedHeight.value)
        specifiedWidth = CGFloat(Defaults.specifiedWidth.value)
    }

    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        let screen = params.visibleFrameOfScreen

        let windowWidth = calculateWidth(for: screen)
        let windowHeight = calculateHeight(for: screen)

        let centeredX = centerHorizontally(windowWidth: windowWidth, in: screen)
        let centeredY = centerVertically(windowHeight: windowHeight, in: screen)

        let windowRect = CGRect(
            x: centeredX,
            y: centeredY,
            width: windowWidth,
            height: windowHeight
        )

        return RectResult(windowRect)
    }

    // MARK: - Size Calculations

    private func calculateWidth(for screen: CGRect) -> CGFloat {
        if specifiedWidth <= 1 {
            // Value is a percentage (e.g., 0.5 = 50% of screen width)
            return screen.width * specifiedWidth
        } else {
            // Value is an absolute pixel size, but don't exceed screen width
            return min(screen.width, round(specifiedWidth))
        }
    }

    private func calculateHeight(for screen: CGRect) -> CGFloat {
        if specifiedHeight <= 1 {
            // Value is a percentage (e.g., 0.5 = 50% of screen height)
            return screen.height * specifiedHeight
        } else {
            // Value is an absolute pixel size
            return round(specifiedHeight)
        }
    }

    // MARK: - Centering Calculations

    private func centerHorizontally(windowWidth: CGFloat, in screen: CGRect) -> CGFloat {
        let extraSpace = screen.width - windowWidth
        let offsetFromLeft = round(extraSpace / 2.0)
        return screen.minX + offsetFromLeft
    }

    private func centerVertically(windowHeight: CGFloat, in screen: CGRect) -> CGFloat {
        let extraSpace = screen.height - windowHeight
        let offsetFromBottom = round(extraSpace / 2.0)
        return screen.minY + offsetFromBottom
    }
}
