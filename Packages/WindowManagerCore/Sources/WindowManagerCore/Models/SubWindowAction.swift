//
//  SubWindowAction.swift
//  WindowManagerCore
//
//  Represents window positions used internally for calculations.
//  More granular than WindowAction - includes orientation-specific variants.
//

import Foundation

// MARK: - SubWindowAction Enum

/// Represents window positions used internally for calculations.
///
/// This is more granular than WindowAction - it includes orientation-specific
/// variants (landscape vs portrait) for sixths, etc.
///
/// Used primarily for calculating exact window rectangles and gap edges.
public enum SubWindowAction: Sendable {

    // MARK: Vertical Thirds (left to right)
    case leftThird
    case centerVerticalThird
    case rightThird
    case leftTwoThirds
    case rightTwoThirds

    // MARK: Horizontal Thirds (top to bottom)
    case topThird
    case centerHorizontalThird
    case bottomThird
    case topTwoThirds
    case bottomTwoThirds

    // MARK: Vertical Fourths (left to right)
    case leftFourth
    case centerLeftFourth
    case centerRightFourth
    case rightFourth

    // MARK: Horizontal Fourths (top to bottom)
    case topFourth
    case centerTopFourth
    case centerBottomFourth
    case bottomFourth

    // MARK: Three-Fourths Variations
    case rightThreeFourths
    case bottomThreeFourths
    case leftThreeFourths
    case topThreeFourths
    case centerVerticalThreeFourths
    case centerHorizontalThreeFourths

    // MARK: Centered Halves
    case centerVerticalHalf
    case centerHorizontalHalf

    // MARK: Sixths - Landscape (2 rows × 3 columns)
    case topLeftSixthLandscape
    case topCenterSixthLandscape
    case topRightSixthLandscape
    case bottomLeftSixthLandscape
    case bottomCenterSixthLandscape
    case bottomRightSixthLandscape

    // MARK: Sixths - Portrait (3 rows × 2 columns)
    case topLeftSixthPortrait
    case topRightSixthPortrait
    case leftCenterSixthPortrait
    case rightCenterSixthPortrait
    case bottomLeftSixthPortrait
    case bottomRightSixthPortrait

    // MARK: Two-Sixths Combinations
    case topLeftTwoSixthsLandscape
    case topLeftTwoSixthsPortrait
    case topRightTwoSixthsLandscape
    case topRightTwoSixthsPortrait
    case bottomLeftTwoSixthsLandscape
    case bottomLeftTwoSixthsPortrait
    case bottomRightTwoSixthsLandscape
    case bottomRightTwoSixthsPortrait

    // MARK: Ninths (3×3 grid)
    case topLeftNinth
    case topCenterNinth
    case topRightNinth
    case middleLeftNinth
    case middleCenterNinth
    case middleRightNinth
    case bottomLeftNinth
    case bottomCenterNinth
    case bottomRightNinth

    // MARK: Corner Thirds
    case topLeftThird
    case topRightThird
    case bottomLeftThird
    case bottomRightThird

    // MARK: Eighths (2×4 grid)
    case topLeftEighth
    case topCenterLeftEighth
    case topCenterRightEighth
    case topRightEighth
    case bottomLeftEighth
    case bottomCenterLeftEighth
    case bottomCenterRightEighth
    case bottomRightEighth

    // MARK: Special
    case maximize
    case leftTodo
    case rightTodo

    // MARK: - Properties

    /// Which edges are shared with adjacent windows for gap calculations.
    ///
    /// Used for applying window gaps - shared edges get half the gap size
    /// so adjacent windows end up with a full gap between them.
    public var gapSharedEdge: Edge {
        switch self {
        case .leftThird: return .right
        case .centerVerticalThird: return [.right, .left]
        case .rightThird: return .left
        case .leftTwoThirds: return .right
        case .rightTwoThirds: return .left
        case .topThird: return .bottom
        case .centerHorizontalThird: return [.top, .bottom]
        case .bottomThird: return .top
        case .topTwoThirds: return .bottom
        case .bottomTwoThirds: return .top
        case .leftFourth: return .right
        case .centerLeftFourth: return [.right, .left]
        case .centerRightFourth: return [.right, .left]
        case .rightFourth: return .left
        case .topFourth: return .bottom
        case .centerTopFourth: return [.top, .bottom]
        case .centerBottomFourth: return [.top, .bottom]
        case .bottomFourth: return .top
        case .rightThreeFourths: return .left
        case .bottomThreeFourths: return .top
        case .leftThreeFourths: return .right
        case .topThreeFourths: return .bottom
        case .centerVerticalThreeFourths: return [.right, .left]
        case .centerHorizontalThreeFourths: return [.top, .bottom]
        case .centerVerticalHalf: return [.right, .left]
        case .centerHorizontalHalf: return [.top, .bottom]
        case .topLeftSixthLandscape: return [.right, .bottom]
        case .topCenterSixthLandscape: return [.right, .left, .bottom]
        case .topRightSixthLandscape: return [.left, .bottom]
        case .bottomLeftSixthLandscape: return [.top, .right]
        case .bottomCenterSixthLandscape: return [.left, .right, .top]
        case .bottomRightSixthLandscape: return [.left, .top]
        case .topLeftSixthPortrait: return [.right, .bottom]
        case .topRightSixthPortrait: return [.left, .bottom]
        case .leftCenterSixthPortrait: return [.top, .bottom, .right]
        case .rightCenterSixthPortrait: return [.left, .top, .bottom]
        case .bottomLeftSixthPortrait: return [.top, .right]
        case .bottomRightSixthPortrait: return [.left, .top]
        case .topLeftTwoSixthsLandscape: return [.right, .bottom]
        case .topLeftTwoSixthsPortrait: return [.right, .bottom]
        case .topRightTwoSixthsLandscape: return [.left, .bottom]
        case .topRightTwoSixthsPortrait: return [.left, .bottom]
        case .bottomLeftTwoSixthsLandscape: return [.right, .top]
        case .bottomLeftTwoSixthsPortrait: return [.right, .top]
        case .bottomRightTwoSixthsLandscape: return [.left, .top]
        case .bottomRightTwoSixthsPortrait: return [.left, .top]
        case .topLeftNinth: return [.right, .bottom]
        case .topCenterNinth: return [.right, .left, .bottom]
        case .topRightNinth: return [.left, .bottom]
        case .middleLeftNinth: return [.top, .right, .bottom]
        case .middleCenterNinth: return [.top, .right, .bottom, .left]
        case .middleRightNinth: return [.left, .top, .bottom]
        case .bottomLeftNinth: return [.top, .right]
        case .bottomCenterNinth: return [.left, .top, .right]
        case .bottomRightNinth: return [.left, .top]
        case .topLeftThird: return [.right, .bottom]
        case .topRightThird: return [.left, .bottom]
        case .bottomLeftThird: return [.right, .top]
        case .bottomRightThird: return [.left, .top]
        case .topLeftEighth: return [.right, .bottom]
        case .topCenterLeftEighth: return [.right, .left, .bottom]
        case .topCenterRightEighth: return [.right, .left, .bottom]
        case .topRightEighth: return [.left, .bottom]
        case .bottomLeftEighth: return [.right, .top]
        case .bottomCenterLeftEighth: return [.right, .left, .top]
        case .bottomCenterRightEighth: return [.right, .left, .top]
        case .bottomRightEighth: return [.left, .top]
        case .maximize: return .none
        case .leftTodo: return .right
        case .rightTodo: return .left
        }
    }
}
