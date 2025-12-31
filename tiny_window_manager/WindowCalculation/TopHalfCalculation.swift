import Foundation

/// Positions a window in the top portion of the screen, spanning the full width.
///
/// By default, the window takes up the top half (1/2) of the screen.
/// When repeatedly triggered, cycles through sizes: 1/2 → 2/3 → 1/3 → (repeat)
///
/// Visual representation (showing top half):
/// ┌─────────────────┐
/// │   Window        │  ← Top portion (1/2, 2/3, or 1/3 of height)
/// ├─────────────────┤
/// │                 │  ← Remaining screen space
/// └─────────────────┘
class TopHalfCalculation: WindowCalculation, RepeatedExecutionsInThirdsCalculation {

    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        print(#function, "called")
        let isFirstExecution = params.lastAction == nil
        let cyclingDisabled = !Defaults.subsequentExecutionMode.resizes

        if isFirstExecution || cyclingDisabled {
            // First time: use default size (typically 1/2)
            return calculateFirstRect(params)
        }

        // Repeated execution: cycle to next size (1/2 → 2/3 → 1/3 → ...)
        return calculateRepeatedRect(params)
    }

    /// Positions the window at the top of the screen with the given height fraction.
    ///
    /// - Parameter fraction: The portion of screen height to use (e.g., 0.5 for half, 0.67 for two-thirds)
    func calculateFractionalRect(_ params: RectCalculationParameters, fraction: Float) -> RectResult {
        print(#function, "called")
        let screen = params.visibleFrameOfScreen

        // Calculate the window height based on the fraction
        let windowHeight = floor(screen.height * CGFloat(fraction))

        // Position at top of screen (macOS y=0 is at bottom, so top = maxY - height)
        let yPosition = screen.maxY - windowHeight

        let rect = CGRect(
            x: screen.minX,
            y: yPosition,
            width: screen.width,
            height: windowHeight
        )

        return RectResult(rect)
    }
}
