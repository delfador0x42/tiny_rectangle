//
//  ChangeWindowDimensionCalculation.swift
//  tiny_window_manager
//

import Foundation

/// Protocol for types that can check if a window resize would make the window too small.
/// Any class conforming to this protocol gets a default implementation of the check.
protocol ChangeWindowDimensionCalculation {
    func resizedWindowRectIsTooSmall(windowRect: CGRect, visibleFrameOfScreen: CGRect) -> Bool
}

extension ChangeWindowDimensionCalculation {

    // MARK: - Constants

    /// Default minimum size as a fraction of the screen (25%)
    private static var defaultMinimumFraction: CGFloat { 0.25 }

    // MARK: - Private Helpers

    /// Returns the minimum allowed window width as a fraction of screen width (0.0 to 1.0).
    /// Falls back to 25% if the user's setting is invalid.
    private func minimumWindowWidth() -> CGFloat {
        let userSetting = Defaults.minimumWindowWidth.value

        let isValidFraction = userSetting > 0 && userSetting <= 1
        if isValidFraction {
            return CGFloat(userSetting)
        }

        return Self.defaultMinimumFraction
    }

    /// Returns the minimum allowed window height as a fraction of screen height (0.0 to 1.0).
    /// Falls back to 25% if the user's setting is invalid.
    private func minimumWindowHeight() -> CGFloat {
        let userSetting = Defaults.minimumWindowHeight.value

        let isValidFraction = userSetting > 0 && userSetting <= 1
        if isValidFraction {
            return CGFloat(userSetting)
        }

        return Self.defaultMinimumFraction
    }

    // MARK: - Public API

    /// Checks if the given window dimensions are smaller than the allowed minimum.
    ///
    /// - Parameters:
    ///   - windowRect: The proposed window frame after resizing
    ///   - visibleFrameOfScreen: The usable area of the screen (excludes menu bar, dock, etc.)
    /// - Returns: `true` if the window would be too small, `false` if it's acceptable
    func resizedWindowRectIsTooSmall(windowRect: CGRect, visibleFrameOfScreen: CGRect) -> Bool {
        // Calculate the minimum allowed dimensions in points
        let minimumWidth = floor(visibleFrameOfScreen.width * minimumWindowWidth())
        let minimumHeight = floor(visibleFrameOfScreen.height * minimumWindowHeight())

        // Check if either dimension is too small
        let isTooNarrow = windowRect.width <= minimumWidth
        let isTooShort = windowRect.height <= minimumHeight

        return isTooNarrow || isTooShort
    }
}
