//  ScreenProtocol.swift - Abstraction for screen/display information
//
//  This protocol abstracts screen detection, allowing calculations
//  to work with mock screens for testing.

import Foundation
import CoreGraphics

// MARK: - Screen Protocol

/// Represents a display/screen that windows can be positioned on.
///
/// This abstraction allows window calculations to be tested without
/// requiring actual NSScreen instances.
public protocol ScreenProtocol {
    /// The full frame of the screen in screen coordinates
    var frame: CGRect { get }

    /// The visible frame (excluding menu bar, dock) in screen coordinates
    var visibleFrame: CGRect { get }

    /// Whether this screen is in landscape orientation (wider than tall)
    var isLandscape: Bool { get }
}

// MARK: - Screen Data (Value Type)

/// A simple value type representing screen data for calculations.
public struct ScreenData: ScreenProtocol, Equatable {
    public let frame: CGRect
    public let visibleFrame: CGRect

    public var isLandscape: Bool {
        frame.width > frame.height
    }

    public init(frame: CGRect, visibleFrame: CGRect) {
        self.frame = frame
        self.visibleFrame = visibleFrame
    }

    /// Creates a screen with the visible frame equal to the full frame.
    public init(frame: CGRect) {
        self.frame = frame
        self.visibleFrame = frame
    }
}

// MARK: - Screen Provider Protocol

/// Provides access to available screens.
///
/// Implement this to provide real screens (via NSScreen) or mock screens for testing.
public protocol ScreenProviderProtocol {
    /// All available screens
    var screens: [ScreenProtocol] { get }

    /// The main (primary) screen
    var mainScreen: ScreenProtocol? { get }

    /// Finds the screen containing the given point
    func screen(containing point: CGPoint) -> ScreenProtocol?

    /// Finds the screen containing the given window
    func screen(for window: WindowProtocol) -> ScreenProtocol?
}
