//  ActionRecord.swift - Records of applied window actions
//
//  Tracks window actions for history, restore, and cycling features.

import Foundation
import CoreGraphics

// MARK: - ActionRecord

/// Records a window action that was applied, for history tracking.
///
/// Used for:
/// - Restoring windows to their previous position
/// - Cycling through action variants
/// - Matching actions when moving between displays
public struct ActionRecord: Sendable {
    /// The action that was applied
    public let action: WindowActionType

    /// The sub-action variant (for orientation-specific actions)
    public let subAction: SubActionType?

    /// The resulting window frame after the action
    public let rect: CGRect

    /// How many times this action was applied in sequence (for cycling)
    public let count: Int

    public init(
        action: WindowActionType,
        subAction: SubActionType? = nil,
        rect: CGRect,
        count: Int = 1
    ) {
        self.action = action
        self.subAction = subAction
        self.rect = rect
        self.count = count
    }
}

// MARK: - SubActionType

/// Represents sub-action variants for orientation-specific positioning.
///
/// Some actions (like sixths) have different layouts in landscape vs portrait.
/// This enum captures those variants for accurate history tracking.
public enum SubActionType: Sendable {
    // Vertical Thirds
    case leftThird, centerVerticalThird, rightThird
    case leftTwoThirds, rightTwoThirds

    // Horizontal Thirds
    case topThird, centerHorizontalThird, bottomThird
    case topTwoThirds, bottomTwoThirds

    // Vertical Fourths
    case leftFourth, centerLeftFourth, centerRightFourth, rightFourth

    // Horizontal Fourths
    case topFourth, centerTopFourth, centerBottomFourth, bottomFourth

    // Three-Fourths
    case rightThreeFourths, bottomThreeFourths
    case leftThreeFourths, topThreeFourths
    case centerVerticalThreeFourths, centerHorizontalThreeFourths

    // Centered Halves
    case centerVerticalHalf, centerHorizontalHalf

    // Sixths - Landscape
    case topLeftSixthLandscape, topCenterSixthLandscape, topRightSixthLandscape
    case bottomLeftSixthLandscape, bottomCenterSixthLandscape, bottomRightSixthLandscape

    // Sixths - Portrait
    case topLeftSixthPortrait, topRightSixthPortrait
    case leftCenterSixthPortrait, rightCenterSixthPortrait
    case bottomLeftSixthPortrait, bottomRightSixthPortrait

    // Two-Sixths
    case topLeftTwoSixthsLandscape, topLeftTwoSixthsPortrait
    case topRightTwoSixthsLandscape, topRightTwoSixthsPortrait
    case bottomLeftTwoSixthsLandscape, bottomLeftTwoSixthsPortrait
    case bottomRightTwoSixthsLandscape, bottomRightTwoSixthsPortrait

    // Ninths
    case topLeftNinth, topCenterNinth, topRightNinth
    case middleLeftNinth, middleCenterNinth, middleRightNinth
    case bottomLeftNinth, bottomCenterNinth, bottomRightNinth

    // Corner Thirds
    case topLeftThird, topRightThird, bottomLeftThird, bottomRightThird

    // Eighths
    case topLeftEighth, topCenterLeftEighth, topCenterRightEighth, topRightEighth
    case bottomLeftEighth, bottomCenterLeftEighth, bottomCenterRightEighth, bottomRightEighth

    // Special
    case maximize, leftTodo, rightTodo
}
