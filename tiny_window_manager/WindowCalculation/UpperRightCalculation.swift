import Foundation

/// Positions a window in the upper-right corner of the screen.
///
/// The window always takes up half the screen height, anchored to the top.
/// By default, the window takes up half the screen width.
/// When repeatedly triggered, cycles through widths: 1/2 → 2/3 → 1/3 → (repeat)
///
/// Visual representation (showing default 1/2 width):
/// ┌─────────┬─────────┐
/// │         │ Window  │  ← Top half of screen
/// ├─────────┼─────────┤
/// │         │         │  ← Bottom half (empty)
/// └─────────┴─────────┘
///             ↑ 1/2, 2/3, or 1/3 of width (right-aligned)
class UpperRightCalculation: WindowCalculation, RepeatedExecutionsInThirdsCalculation {

    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        let isFirstExecution = params.lastAction == nil
        let cyclingDisabled = !Defaults.subsequentExecutionMode.resizes

        if isFirstExecution || cyclingDisabled {
            // First time: use default size (typically 1/2 width)
            return calculateFirstRect(params)
        }

        // Repeated execution: cycle to next width (1/2 → 2/3 → 1/3 → ...)
        return calculateRepeatedRect(params)
    }

    /// Positions the window in the upper-right with the given width fraction.
    ///
    /// - Parameter fraction: The portion of screen width to use (e.g., 0.5 for half, 0.67 for two-thirds)
    func calculateFractionalRect(_ params: RectCalculationParameters, fraction: Float) -> RectResult {
        let screen = params.visibleFrameOfScreen

        // Width is variable based on the fraction; height is always half the screen
        let windowWidth = floor(screen.width * CGFloat(fraction))
        let windowHeight = floor(screen.height / 2.0)

        // Position: right edge (right-aligned), top half
        let xPosition = screen.maxX - windowWidth  // Right-aligned
        let yPosition = screen.maxY - windowHeight // Top row (macOS y=0 is at bottom)

        let rect = CGRect(
            x: xPosition,
            y: yPosition,
            width: windowWidth,
            height: windowHeight
        )

        return RectResult(rect)
    }
}
