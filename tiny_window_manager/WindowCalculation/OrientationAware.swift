//
//  OrientationAware.swift
//  tiny_window_manager
//
//

import Foundation

// MARK: - Type Alias

/// A simple calculation function that takes a screen's visible frame and returns a window rectangle.
/// Used as a shorthand for functions that compute window positions.
typealias SimpleCalc = (_ visibleFrameOfScreen: CGRect) -> RectResult

// MARK: - OrientationAware Protocol

/// A protocol for window calculations that behave differently based on screen orientation.
///
/// Some window layouts make more sense in landscape (wide) vs portrait (tall) orientations.
/// For example, a "left third" layout might become a "top third" on a portrait monitor.
///
/// Conforming types provide separate implementations for each orientation, and the
/// `orientationBasedRect` method automatically picks the right one based on the screen's shape.
///
/// ## Example Usage
/// ```swift
/// class MyCalculation: WindowCalculation, OrientationAware {
///     func landscapeRect(_ visibleFrameOfScreen: CGRect) -> RectResult {
///         // Return left-third of screen for wide monitors
///     }
///
///     func portraitRect(_ visibleFrameOfScreen: CGRect) -> RectResult {
///         // Return top-third of screen for tall monitors
///     }
/// }
/// ```
protocol OrientationAware {

    /// Calculates the window rectangle for landscape (wide) screens.
    /// Called when the screen's width is greater than its height.
    func landscapeRect(_ visibleFrameOfScreen: CGRect) -> RectResult

    /// Calculates the window rectangle for portrait (tall) screens.
    /// Called when the screen's height is greater than or equal to its width.
    func portraitRect(_ visibleFrameOfScreen: CGRect) -> RectResult

    /// Automatically selects and calls either `landscapeRect` or `portraitRect`
    /// based on the screen's orientation.
    func orientationBasedRect(_ visibleFrameOfScreen: CGRect) -> RectResult
}

// MARK: - Default Implementation

extension OrientationAware {

    /// Default implementation that checks the screen orientation and delegates
    /// to the appropriate method.
    func orientationBasedRect(_ visibleFrameOfScreen: CGRect) -> RectResult {
        let isLandscape = visibleFrameOfScreen.isLandscape

        if isLandscape {
            return landscapeRect(visibleFrameOfScreen)
        } else {
            return portraitRect(visibleFrameOfScreen)
        }
    }
}
