//
//  CompoundSnapArea.swift
//  tiny_window_manager
//
//  "Compound" snap areas are screen edges that offer MULTIPLE snap positions
//  depending on WHERE along the edge the user drags. For example, dragging to
//  the left edge might snap to:
//    - Left half (if dragged to the middle of the edge)
//    - Top-left quarter (if dragged near the top corner)
//    - Bottom-left quarter (if dragged near the bottom corner)
//
//  This is different from simple snap areas that always do the same action
//  regardless of cursor position along the edge.
//

import Foundation

// MARK: - Compound Snap Area Types

/// Defines the different compound snap area behaviors available.
/// Each case uses a negative integer as its raw value (to distinguish from WindowAction's positive values).
enum CompoundSnapArea: Int, Codable {

    // Left/Right edge behaviors - split into halves based on cursor Y position
    case leftTopBottomHalf = -2
    case rightTopBottomHalf = -3

    // Top/Bottom edge behaviors - split into thirds or other divisions
    case thirds = -4
    case portraitThirdsSide = -5
    case halves = -6
    case topSixths = -7
    case bottomSixths = -8
    case fourths = -9
    case portraitTopBottomHalves = -10

    // MARK: - Static Properties

    /// All compound snap area types in the order they appear in dropdown menus
    static let all: [CompoundSnapArea] = [
        .leftTopBottomHalf,
        .rightTopBottomHalf,
        .thirds,
        .portraitThirdsSide,
        .halves,
        .topSixths,
        .bottomSixths,
        .fourths,
        .portraitTopBottomHalves
    ]

    // MARK: - Calculation Instances (Singletons)
    // Each compound snap area type has a corresponding calculation object that
    // determines which window action to perform based on cursor position.

    static let leftCompoundCalculation = LeftTopBottomHalfCalculation()
    static let rightCompoundCalculation = RightTopBottomHalfCalculation()
    static let thirdsCompoundCalculation = ThirdsCompoundCalculation()
    static let portraitSideThirdsCalculation = PortraitSideThirdsCompoundCalculation()
    static let leftRightHalvesCalculation = LeftRightHalvesCompoundCalculation()
    static let topSixthsCalculation = TopSixthsCompoundCalculation()
    static let bottomSixthsCalculation = BottomSixthsCompoundCalculation()
    static let fourthsColumnCalculation = FourthsColumnCompoundCalculation()
    static let portraitTopBottomCalculation = TopBottomHalvesCalculation()

    // MARK: - Display Name

    /// Human-readable name shown in the preferences dropdown menus
    var displayName: String {
        switch self {
        case .leftTopBottomHalf:
            return NSLocalizedString(
                "Left half, top/bottom half near corners",
                tableName: "Main",
                value: "",
                comment: ""
            )

        case .rightTopBottomHalf:
            return NSLocalizedString(
                "Right half, top/bottom half near corners",
                tableName: "Main",
                value: "",
                comment: ""
            )

        case .thirds:
            return NSLocalizedString(
                "Thirds, drag toward center for two thirds",
                tableName: "Main",
                value: "",
                comment: ""
            )

        case .portraitThirdsSide:
            return NSLocalizedString(
                "Thirds, top/bottom half near corners",
                tableName: "Main",
                value: "",
                comment: ""
            )

        case .halves:
            return NSLocalizedString(
                "Left or right half",
                tableName: "Main",
                value: "",
                comment: ""
            )

        case .topSixths:
            return NSLocalizedString(
                "Top sixths from corners; maximize",
                tableName: "Main",
                value: "",
                comment: ""
            )

        case .bottomSixths:
            return NSLocalizedString(
                "Bottom sixths from corners; thirds",
                tableName: "Main",
                value: "",
                comment: ""
            )

        case .fourths:
            return NSLocalizedString(
                "Fourths columns",
                tableName: "Main",
                value: "",
                comment: ""
            )

        case .portraitTopBottomHalves:
            return NSLocalizedString(
                "Top/bottom halves",
                tableName: "Main",
                value: "",
                comment: ""
            )
        }
    }

    // MARK: - Calculation Logic

    /// Returns the calculation object that determines snap behavior based on cursor position.
    /// These are singleton instances to avoid creating new objects on every drag event.
    var calculation: CompoundSnapAreaCalculation {
        switch self {
        case .leftTopBottomHalf:
            return Self.leftCompoundCalculation
        case .rightTopBottomHalf:
            return Self.rightCompoundCalculation
        case .thirds:
            return Self.thirdsCompoundCalculation
        case .portraitThirdsSide:
            return Self.portraitSideThirdsCalculation
        case .halves:
            return Self.leftRightHalvesCalculation
        case .topSixths:
            return Self.topSixthsCalculation
        case .bottomSixths:
            return Self.bottomSixthsCalculation
        case .fourths:
            return Self.fourthsColumnCalculation
        case .portraitTopBottomHalves:
            return Self.portraitTopBottomCalculation
        }
    }

    // MARK: - Compatibility

    /// Which screen edges/corners this compound snap area can be assigned to.
    /// - `.l` = left edge
    /// - `.r` = right edge
    /// - `.t` = top edge
    /// - `.b` = bottom edge
    var compatibleDirectionals: [Directional] {
        switch self {
        case .leftTopBottomHalf:
            // Only makes sense on the left edge
            return [.l]

        case .rightTopBottomHalf:
            // Only makes sense on the right edge
            return [.r]

        case .thirds:
            // Horizontal thirds work on top/bottom edges (landscape monitors)
            return [.t, .b]

        case .portraitThirdsSide:
            // Vertical thirds work on left/right edges (portrait monitors)
            return [.l, .r]

        case .halves:
            // Left/right halves triggered from top/bottom edges
            return [.t, .b]

        case .topSixths:
            // Top row sixths only on top edge
            return [.t]

        case .bottomSixths:
            // Bottom row sixths only on bottom edge
            return [.b]

        case .fourths:
            // Four columns work on top/bottom edges
            return [.t, .b]

        case .portraitTopBottomHalves:
            // Top/bottom halves triggered from left/right edges (portrait monitors)
            return [.l, .r]
        }
    }

    /// Which display orientations this compound snap area is designed for.
    /// Some snap areas only make sense on landscape or portrait monitors.
    var compatibleOrientation: [DisplayOrientation] {
        switch self {
        case .leftTopBottomHalf, .rightTopBottomHalf, .halves:
            // These work on any monitor orientation
            return [.portrait, .landscape]

        case .portraitThirdsSide, .portraitTopBottomHalves:
            // These are specifically designed for portrait monitors
            return [.portrait]

        case .thirds, .topSixths, .bottomSixths, .fourths:
            // These are specifically designed for landscape monitors
            return [.landscape]
        }
    }
}

// MARK: - Calculation Protocol

/// Protocol that all compound snap area calculation classes must implement.
/// Each implementation decides which snap area to return based on where
/// the cursor is positioned along the screen edge.
protocol CompoundSnapAreaCalculation {

    /// Calculates which snap area to show based on cursor position.
    ///
    /// - Parameters:
    ///   - cursorLocation: Current mouse position in screen coordinates
    ///   - screen: The screen the cursor is on
    ///   - directional: Which edge/corner triggered this (left, right, top, bottom)
    ///   - priorSnapArea: The previously shown snap area (used for hysteresis to prevent flickering)
    ///
    /// - Returns: The snap area to display, or nil if no snap should occur
    func snapArea(
        cursorLocation: NSPoint,
        screen: NSScreen,
        directional: Directional,
        priorSnapArea: SnapArea?
    ) -> SnapArea?
}
