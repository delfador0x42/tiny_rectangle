//  WindowMover.swift - Window movement strategy classes

import Foundation

// MARK: - WindowMover Protocol

/// Strategy pattern for moving/resizing windows. Movers run in sequence,
/// each potentially adjusting the window position.
protocol WindowMover {
    func moveWindowRect(
        _ windowRect: CGRect,
        frameOfScreen: CGRect,
        visibleFrameOfScreen: CGRect,
        frontmostWindowElement: AccessibilityElement?,
        action: WindowAction?
    )
}

// MARK: - StandardWindowMover

/// Basic mover that directly applies the requested frame.
class StandardWindowMover: WindowMover {
    func moveWindowRect(
        _ windowRect: CGRect,
        frameOfScreen: CGRect,
        visibleFrameOfScreen: CGRect,
        frontmostWindowElement: AccessibilityElement?,
        action: WindowAction?
    ) {
        let currentWindowRect = frontmostWindowElement?.frame
        let windowIsInvalid = currentWindowRect?.isNull == true
        if windowIsInvalid { return }
        frontmostWindowElement?.setFrame(windowRect)
    }
}

// MARK: - BestEffortWindowMover

/// Shifts windows back on-screen if they overflow due to minimum size constraints.
class BestEffortWindowMover: WindowMover {
    func moveWindowRect(
        _ windowRect: CGRect,
        frameOfScreen: CGRect,
        visibleFrameOfScreen: CGRect,
        frontmostWindowElement: AccessibilityElement?,
        action: WindowAction?
    ) {
        guard let currentWindowRect = frontmostWindowElement?.frame else { return }

        if action?.allowedToExtendOutsideCurrentScreenArea == true && !NSScreen.screensHaveSeparateSpaces {
            return
        }

        var adjustedRect = adjustHorizontalPosition(currentWindowRect, within: visibleFrameOfScreen)
        adjustedRect = adjustVerticalPosition(adjustedRect, within: visibleFrameOfScreen)

        if !currentWindowRect.equalTo(adjustedRect) {
            frontmostWindowElement?.setFrame(adjustedRect)
        }
    }

    private func adjustHorizontalPosition(_ rect: CGRect, within screen: CGRect) -> CGRect {
        var adjusted = rect
        if adjusted.minX < screen.minX {
            adjusted.origin.x = screen.minX
        } else if adjusted.maxX > screen.maxX {
            adjusted.origin.x = screen.maxX - adjusted.width - CGFloat(Defaults.gapSize.value)
        }
        return adjusted
    }

    private func adjustVerticalPosition(_ rect: CGRect, within screen: CGRect) -> CGRect {
        var adjusted = rect.screenFlipped
        if adjusted.minY < screen.minY {
            adjusted.origin.y = screen.minY
        } else if adjusted.maxY > screen.maxY {
            adjusted.origin.y = screen.maxY - adjusted.height - CGFloat(Defaults.gapSize.value)
        }
        return adjusted.screenFlipped
    }
}

// MARK: - CenteringFixedSizedWindowMover

/// Centers fixed-size windows (that can't resize) within the target area.
class CenteringFixedSizedWindowMover: WindowMover {
    func moveWindowRect(
        _ windowRect: CGRect,
        frameOfScreen: CGRect,
        visibleFrameOfScreen: CGRect,
        frontmostWindowElement: AccessibilityElement?,
        action: WindowAction?
    ) {
        guard let current = frontmostWindowElement?.frame else { return }
        var adjusted = current

        if current.width != windowRect.width {
            adjusted.origin.x = round((windowRect.width - current.width) / 2) + windowRect.minX
        }
        if current.height != windowRect.height {
            adjusted.origin.y = round((windowRect.height - current.height) / 2) + windowRect.minY
        }

        if !adjusted.equalTo(current) {
            frontmostWindowElement?.setFrame(adjusted)
        }
    }
}

