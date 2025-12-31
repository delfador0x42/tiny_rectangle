//
//  SnapAreaModel.swift
//  tiny_window_manager
//
//  Manages the configuration for snap areas - the regions on screen edges/corners
//  where dragging a window will trigger a snap action.
//
//  Screen positions (Directional enum):
//  ┌──────┬──────┬──────┐
//  │  TL  │  T   │  TR  │   TL = top-left corner
//  │      │ top  │      │   T  = top edge
//  ├──────┼──────┼──────┤   TR = top-right corner
//  │  L   │  C   │  R   │   L  = left edge
//  │ left │center│right │   C  = center (unused)
//  ├──────┼──────┼──────┤   R  = right edge
//  │  BL  │  B   │  BR  │   BL = bottom-left corner
//  │      │bottom│      │   B  = bottom edge
//  └──────┴──────┴──────┘   BR = bottom-right corner
//
//  Each position can be configured with either:
//  - A single WindowAction (e.g., .leftHalf, .maximize)
//  - A CompoundSnapArea (e.g., .thirds, .leftTopBottomHalf)
//
//  There are separate configurations for landscape and portrait monitors.
//

import Foundation

// MARK: - Snap Area Model (Singleton)

/// Central manager for snap area configurations.
/// This is a singleton - access via `SnapAreaModel.instance`.
class SnapAreaModel {

    /// The shared instance (singleton pattern)
    static let instance = SnapAreaModel()

    /// Private initializer prevents creating additional instances
    private init() {
        print(#function, "called")
    }

    // MARK: - Default Configurations

    /// Default snap area configuration for LANDSCAPE monitors.
    /// These are the out-of-the-box settings before user customization.
    static let defaultLandscape: [Directional: SnapAreaConfig] = [
        .tl: SnapAreaConfig(action: .topLeft),           // Top-left corner → top-left quarter
        .t:  SnapAreaConfig(action: .maximize),          // Top edge → maximize
        .tr: SnapAreaConfig(action: .topRight),          // Top-right corner → top-right quarter
        .l:  SnapAreaConfig(compound: .leftTopBottomHalf),   // Left edge → left half with corner options
        .r:  SnapAreaConfig(compound: .rightTopBottomHalf),  // Right edge → right half with corner options
        .bl: SnapAreaConfig(action: .bottomLeft),        // Bottom-left corner → bottom-left quarter
        .b:  SnapAreaConfig(compound: .thirds),          // Bottom edge → thirds
        .br: SnapAreaConfig(action: .bottomRight)        // Bottom-right corner → bottom-right quarter
    ]

    /// Default snap area configuration for PORTRAIT monitors.
    /// Optimized for vertical screen orientations.
    static let defaultPortrait: [Directional: SnapAreaConfig] = [
        .tl: SnapAreaConfig(action: .topLeft),           // Top-left corner → top-left quarter
        .t:  SnapAreaConfig(action: .maximize),          // Top edge → maximize
        .tr: SnapAreaConfig(action: .topRight),          // Top-right corner → top-right quarter
        .l:  SnapAreaConfig(compound: .portraitThirdsSide),  // Left edge → vertical thirds
        .r:  SnapAreaConfig(compound: .portraitThirdsSide),  // Right edge → vertical thirds
        .bl: SnapAreaConfig(action: .bottomLeft),        // Bottom-left corner → bottom-left quarter
        .b:  SnapAreaConfig(compound: .halves),          // Bottom edge → left/right halves
        .br: SnapAreaConfig(action: .bottomRight)        // Bottom-right corner → bottom-right quarter
    ]

    // MARK: - Current Configuration

    /// The current landscape snap area configuration.
    /// Returns user-customized settings, or defaults if none are saved.
    var landscape: [Directional: SnapAreaConfig] {
        return Defaults.landscapeSnapAreas.typedValue ?? SnapAreaModel.defaultLandscape
    }

    /// The current portrait snap area configuration.
    /// Returns user-customized settings, or defaults if none are saved.
    var portrait: [Directional: SnapAreaConfig] {
        return Defaults.portraitSnapAreas.typedValue ?? SnapAreaModel.defaultPortrait
    }

    // MARK: - Configuration Queries

    /// Whether the TOP edge has any snap action configured.
    /// Used to determine if dragging to the top should do anything.
    var isTopConfigured: Bool {
        // Check landscape configuration
        if let landscapeTop = landscape[.t] {
            let hasAction = landscapeTop.action != nil || landscapeTop.compound != nil
            if hasAction {
                return true
            }
        }

        // Check portrait configuration (only if a portrait display is connected)
        if NSScreen.portraitDisplayConnected, let portraitTop = portrait[.t] {
            let hasAction = portraitTop.action != nil || portraitTop.compound != nil
            if hasAction {
                return true
            }
        }

        return false
    }

    // MARK: - Configuration Updates

    /// Updates the snap area configuration for a specific screen position.
    ///
    /// - Parameters:
    ///   - type: Whether to update the landscape or portrait configuration
    ///   - directional: Which screen position to update (e.g., .tl, .t, .l)
    ///   - snapAreaConfig: The new configuration, or nil to disable snapping at this position
    func setConfig(type: DisplayOrientation, directional: Directional, snapAreaConfig: SnapAreaConfig?) {
        print(#function, "called")
        switch type {
        case .landscape:
            setLandscape(directional: directional, snapAreaConfig: snapAreaConfig)
        case .portrait:
            setPortrait(directional: directional, snapAreaConfig: snapAreaConfig)
        }
    }

    /// Updates a single position in the landscape configuration.
    func setLandscape(directional: Directional, snapAreaConfig: SnapAreaConfig?) {
        print(#function, "called")
        var newConfig = landscape
        newConfig[directional] = snapAreaConfig
        Defaults.landscapeSnapAreas.typedValue = newConfig
    }

    /// Updates a single position in the portrait configuration.
    func setPortrait(directional: Directional, snapAreaConfig: SnapAreaConfig?) {
        print(#function, "called")
        var newConfig = portrait
        newConfig[directional] = snapAreaConfig
        Defaults.portraitSnapAreas.typedValue = newConfig
    }

    // MARK: - Migration from Legacy Settings

    /// Migrates settings from older app versions to the current format.
    /// This handles backwards compatibility when upgrading the app.
    func migrate() {
        print(#function, "called")
        migrateSixthsSnapArea()
        migrateIgnoredSnapAreas()
    }

    /// Migrates the legacy "sixths snap area" setting.
    /// In older versions, sixths were a separate toggle; now they're part of the config.
    private func migrateSixthsSnapArea() {
        print(#function, "called")
        guard Defaults.sixthsSnapArea.userEnabled else { return }

        setLandscape(directional: .t, snapAreaConfig: SnapAreaConfig(compound: .topSixths))
        setLandscape(directional: .b, snapAreaConfig: SnapAreaConfig(compound: .bottomSixths))
    }

    /// Migrates the legacy "ignored snap areas" setting.
    /// In older versions, users could disable specific snap areas via a bitmask;
    /// now they configure each area individually.
    private func migrateIgnoredSnapAreas() {
        print(#function, "called")
        let ignoredSnapAreas = SnapAreaOption(rawValue: Defaults.ignoredSnapAreas.value)

        // Nothing to migrate if no areas were ignored
        guard ignoredSnapAreas.rawValue > 0 else { return }

        // Mapping from screen positions to their corresponding option flags
        let directionalToSnapAreaOption: [Directional: SnapAreaOption] = [
            .tl: .topLeft,
            .t:  .top,
            .tr: .topRight,
            .l:  .left,
            .r:  .right,
            .bl: .bottomLeft,
            .b:  .bottom,
            .br: .bottomRight
        ]

        // Disable any snap areas that were previously ignored
        for directional in Directional.cases {
            if let option = directionalToSnapAreaOption[directional] {
                if ignoredSnapAreas.contains(option) {
                    setLandscape(directional: directional, snapAreaConfig: nil)
                    setPortrait(directional: directional, snapAreaConfig: nil)
                }
            }
        }

        // Special case: If both corner zones on the left edge were disabled,
        // simplify to just "left half" instead of the compound snap area
        let bothLeftCornersIgnored = ignoredSnapAreas.contains(.bottomLeftShort)
            && ignoredSnapAreas.contains(.topLeftShort)
        if bothLeftCornersIgnored {
            setLandscape(directional: .l, snapAreaConfig: SnapAreaConfig(action: .leftHalf))
        }

        // Special case: Same for right edge
        let bothRightCornersIgnored = ignoredSnapAreas.contains(.bottomRightShort)
            && ignoredSnapAreas.contains(.topRightShort)
        if bothRightCornersIgnored {
            setLandscape(directional: .r, snapAreaConfig: SnapAreaConfig(action: .rightHalf))
        }
    }
}

// MARK: - Display Orientation

/// Represents whether a display is in landscape or portrait orientation.
enum DisplayOrientation {
    case landscape  // Width > Height (typical horizontal monitor)
    case portrait   // Height > Width (rotated vertical monitor)
}

// MARK: - Snap Area Configuration

/// Configuration for a single snap area position.
/// Contains either a compound snap area OR a single action (not both).
struct SnapAreaConfig: Codable {

    /// A compound snap area that offers multiple snap options based on cursor position.
    /// Example: `.thirds` splits the edge into thirds.
    let compound: CompoundSnapArea?

    /// A single window action that always triggers the same snap.
    /// Example: `.leftHalf` always snaps to the left half.
    let action: WindowAction?

    /// Creates a snap area configuration.
    ///
    /// - Parameters:
    ///   - compound: A compound snap area (mutually exclusive with action)
    ///   - action: A single window action (mutually exclusive with compound)
    ///
    /// Note: Typically you pass one or the other, not both.
    init(compound: CompoundSnapArea? = nil, action: WindowAction? = nil) {
        print(#function, "called")
        self.compound = compound
        self.action = action
    }
}

// MARK: - Screen Position (Directional)

/// Represents a position on the screen edge or corner.
/// Raw values match the tags used in Interface Builder for the preference UI.
///
/// Visual layout:
/// ```
/// ┌────┬────┬────┐
/// │ 1  │ 2  │ 3  │   1=TL, 2=T, 3=TR
/// ├────┼────┼────┤
/// │ 4  │ 9  │ 5  │   4=L, 9=C, 5=R
/// ├────┼────┼────┤
/// │ 6  │ 7  │ 8  │   6=BL, 7=B, 8=BR
/// └────┴────┴────┘
/// ```
enum Directional: Int, Codable {
    case tl = 1  // Top-left corner
    case t  = 2  // Top edge
    case tr = 3  // Top-right corner
    case l  = 4  // Left edge
    case r  = 5  // Right edge
    case bl = 6  // Bottom-left corner
    case b  = 7  // Bottom edge
    case br = 8  // Bottom-right corner
    case c  = 9  // Center (not used for snapping)

    /// All directional cases that are used for snap areas (excludes center)
    static var cases = [tl, t, tr, l, r, bl, b, br]
}

// MARK: - Snap Area Options (Legacy Bitmask)

/// A bitmask representing which snap areas should be ignored.
/// This is a LEGACY type used for migrating settings from older app versions.
/// New code should configure snap areas directly via SnapAreaModel.
struct SnapAreaOption: OptionSet, Hashable {
    let rawValue: Int

    // Main snap areas (edges and corners)
    static let top         = SnapAreaOption(rawValue: 1 << 0)
    static let bottom      = SnapAreaOption(rawValue: 1 << 1)
    static let left        = SnapAreaOption(rawValue: 1 << 2)
    static let right       = SnapAreaOption(rawValue: 1 << 3)
    static let topLeft     = SnapAreaOption(rawValue: 1 << 4)
    static let topRight    = SnapAreaOption(rawValue: 1 << 5)
    static let bottomLeft  = SnapAreaOption(rawValue: 1 << 6)
    static let bottomRight = SnapAreaOption(rawValue: 1 << 7)

    // "Short" zones - the corner regions of compound snap areas
    // (e.g., the top/bottom portions of the left edge that snap to top-half/bottom-half)
    static let topLeftShort     = SnapAreaOption(rawValue: 1 << 8)
    static let topRightShort    = SnapAreaOption(rawValue: 1 << 9)
    static let bottomLeftShort  = SnapAreaOption(rawValue: 1 << 10)
    static let bottomRightShort = SnapAreaOption(rawValue: 1 << 11)

    /// All possible snap area options
    static let all: SnapAreaOption = [
        .top, .bottom, .left, .right,
        .topLeft, .topRight, .bottomLeft, .bottomRight,
        .topLeftShort, .topRightShort, .bottomLeftShort, .bottomRightShort
    ]

    /// No snap areas (empty set)
    static let none: SnapAreaOption = []
}
