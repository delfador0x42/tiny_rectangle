//
//  ActionIdentifier.swift
//  WindowCalculationKit
//
//  Pure enum identifying window actions without UI dependencies.
//  This is a simplified version of WindowAction for use in calculations.
//

import Foundation

/// Identifies a window positioning action.
///
/// This enum contains only the action identity - no UI elements, shortcuts, or localization.
/// The main app's `WindowAction` can bridge to/from this type.
public enum ActionIdentifier: String, Codable, Hashable, Sendable, CaseIterable {

    // MARK: - Halves

    case leftHalf
    case rightHalf
    case topHalf
    case bottomHalf
    case centerHalf

    // MARK: - Corners

    case topLeft
    case topRight
    case bottomLeft
    case bottomRight

    // MARK: - Thirds

    case firstThird
    case centerThird
    case lastThird
    case firstTwoThirds
    case centerTwoThirds
    case lastTwoThirds

    // MARK: - Fourths

    case firstFourth
    case secondFourth
    case thirdFourth
    case lastFourth
    case firstThreeFourths
    case centerThreeFourths
    case lastThreeFourths

    // MARK: - Sixths

    case topLeftSixth
    case topCenterSixth
    case topRightSixth
    case bottomLeftSixth
    case bottomCenterSixth
    case bottomRightSixth

    // MARK: - Ninths

    case topLeftNinth
    case topCenterNinth
    case topRightNinth
    case middleLeftNinth
    case middleCenterNinth
    case middleRightNinth
    case bottomLeftNinth
    case bottomCenterNinth
    case bottomRightNinth

    // MARK: - Corner Thirds

    case topLeftThird
    case topRightThird
    case bottomLeftThird
    case bottomRightThird

    // MARK: - Eighths

    case topLeftEighth
    case topCenterLeftEighth
    case topCenterRightEighth
    case topRightEighth
    case bottomLeftEighth
    case bottomCenterLeftEighth
    case bottomCenterRightEighth
    case bottomRightEighth

    // MARK: - Maximize & Center

    case maximize
    case almostMaximize
    case maximizeHeight
    case center
    case centerProminently

    // MARK: - Size Changes

    case larger
    case smaller
    case largerWidth
    case smallerWidth
    case largerHeight
    case smallerHeight

    // MARK: - Halve/Double Dimensions

    case halveHeightUp
    case halveHeightDown
    case halveWidthLeft
    case halveWidthRight
    case doubleHeightUp
    case doubleHeightDown
    case doubleWidthLeft
    case doubleWidthRight

    // MARK: - Movement

    case moveLeft
    case moveRight
    case moveUp
    case moveDown

    // MARK: - Display Navigation

    case previousDisplay
    case nextDisplay

    // MARK: - Special

    case restore
    case specified
    case leftTodo
    case rightTodo
    case tileAll
    case cascadeAll
    case cascadeActiveApp
    case reverseAll
}

// MARK: - SubActionIdentifier

/// More granular action identifiers for orientation-specific variations.
///
/// Used internally by calculations to track exactly which variation was applied
/// (e.g., leftThird vs topThird depending on screen orientation).
public enum SubActionIdentifier: String, Codable, Hashable, Sendable {

    // MARK: - Vertical Thirds (left to right in landscape)

    case leftThird
    case centerVerticalThird
    case rightThird
    case leftTwoThirds
    case rightTwoThirds

    // MARK: - Horizontal Thirds (top to bottom in portrait)

    case topThird
    case centerHorizontalThird
    case bottomThird
    case topTwoThirds
    case bottomTwoThirds

    // MARK: - Vertical Fourths

    case leftFourth
    case centerLeftFourth
    case centerRightFourth
    case rightFourth

    // MARK: - Horizontal Fourths

    case topFourth
    case centerTopFourth
    case centerBottomFourth
    case bottomFourth

    // MARK: - Three-Fourths

    case rightThreeFourths
    case bottomThreeFourths
    case leftThreeFourths
    case topThreeFourths
    case centerVerticalThreeFourths
    case centerHorizontalThreeFourths

    // MARK: - Centered Halves

    case centerVerticalHalf
    case centerHorizontalHalf

    // MARK: - Sixths Landscape

    case topLeftSixthLandscape
    case topCenterSixthLandscape
    case topRightSixthLandscape
    case bottomLeftSixthLandscape
    case bottomCenterSixthLandscape
    case bottomRightSixthLandscape

    // MARK: - Sixths Portrait

    case topLeftSixthPortrait
    case topRightSixthPortrait
    case leftCenterSixthPortrait
    case rightCenterSixthPortrait
    case bottomLeftSixthPortrait
    case bottomRightSixthPortrait

    // MARK: - Two-Sixths

    case topLeftTwoSixthsLandscape
    case topLeftTwoSixthsPortrait
    case topRightTwoSixthsLandscape
    case topRightTwoSixthsPortrait
    case bottomLeftTwoSixthsLandscape
    case bottomLeftTwoSixthsPortrait
    case bottomRightTwoSixthsLandscape
    case bottomRightTwoSixthsPortrait

    // MARK: - Ninths

    case topLeftNinth
    case topCenterNinth
    case topRightNinth
    case middleLeftNinth
    case middleCenterNinth
    case middleRightNinth
    case bottomLeftNinth
    case bottomCenterNinth
    case bottomRightNinth

    // MARK: - Corner Thirds

    case topLeftThird
    case topRightThird
    case bottomLeftThird
    case bottomRightThird

    // MARK: - Eighths

    case topLeftEighth
    case topCenterLeftEighth
    case topCenterRightEighth
    case topRightEighth
    case bottomLeftEighth
    case bottomCenterLeftEighth
    case bottomCenterRightEighth
    case bottomRightEighth

    // MARK: - Special

    case maximize
    case leftTodo
    case rightTodo
}
