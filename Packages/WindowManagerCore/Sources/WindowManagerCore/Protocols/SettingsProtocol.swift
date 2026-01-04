//  SettingsProtocol.swift - Abstraction for user settings
//
//  This protocol abstracts settings access, allowing calculations
//  to use injected settings rather than global state.

import Foundation
import CoreGraphics

// MARK: - Settings Protocol

/// Provides access to window manager settings.
///
/// This abstraction allows calculations to work with any settings source:
/// - Real UserDefaults-backed settings
/// - In-memory settings for testing
/// - Custom configurations
public protocol SettingsProtocol {
    // MARK: Gap Settings

    /// Gap size between windows (in points)
    var gapSize: CGFloat { get }

    /// Gap from top edge of screen
    var screenEdgeGapTop: CGFloat { get }

    /// Gap from bottom edge of screen
    var screenEdgeGapBottom: CGFloat { get }

    /// Gap from left edge of screen
    var screenEdgeGapLeft: CGFloat { get }

    /// Gap from right edge of screen
    var screenEdgeGapRight: CGFloat { get }

    // MARK: Sizing Settings

    /// "Almost maximize" target height fraction (0.0-1.0)
    var almostMaximizeHeight: CGFloat { get }

    /// "Almost maximize" target width fraction (0.0-1.0)
    var almostMaximizeWidth: CGFloat { get }

    /// Minimum allowed window width
    var minimumWindowWidth: CGFloat { get }

    /// Minimum allowed window height
    var minimumWindowHeight: CGFloat { get }

    /// Size change amount for larger/smaller actions
    var sizeOffset: CGFloat { get }

    /// Step size for width adjustments
    var widthStepSize: CGFloat { get }

    /// Target height for "specified size" action
    var specifiedHeight: CGFloat { get }

    /// Target width for "specified size" action
    var specifiedWidth: CGFloat { get }

    /// Width of todo sidebar
    var todoSidebarWidth: CGFloat { get }

    // MARK: Behavior Settings

    /// Whether to apply gaps when maximizing
    var applyGapsToMaximize: Bool { get }

    /// Whether to apply gaps when maximizing height only
    var applyGapsToMaximizeHeight: Bool { get }

    /// Whether directional moves also resize the window
    var resizeOnDirectionalMove: Bool { get }

    /// Whether center is included in half-window cycling
    var centerHalfCycles: Bool { get }

    /// Whether to use alternate third-cycling behavior
    var altThirdCycle: Bool { get }

    /// Whether centered directional move is enabled
    var centeredDirectionalMove: Bool { get }
}

// MARK: - Default Settings

/// Default settings values for testing and initial state.
public struct DefaultSettings: SettingsProtocol {
    public var gapSize: CGFloat = 0
    public var screenEdgeGapTop: CGFloat = 0
    public var screenEdgeGapBottom: CGFloat = 0
    public var screenEdgeGapLeft: CGFloat = 0
    public var screenEdgeGapRight: CGFloat = 0

    public var almostMaximizeHeight: CGFloat = 0
    public var almostMaximizeWidth: CGFloat = 0
    public var minimumWindowWidth: CGFloat = 0
    public var minimumWindowHeight: CGFloat = 0
    public var sizeOffset: CGFloat = 0
    public var widthStepSize: CGFloat = 30
    public var specifiedHeight: CGFloat = 1050
    public var specifiedWidth: CGFloat = 1680
    public var todoSidebarWidth: CGFloat = 400

    public var applyGapsToMaximize: Bool = true
    public var applyGapsToMaximizeHeight: Bool = true
    public var resizeOnDirectionalMove: Bool = false
    public var centerHalfCycles: Bool = false
    public var altThirdCycle: Bool = false
    public var centeredDirectionalMove: Bool = false

    public init() {}
}
