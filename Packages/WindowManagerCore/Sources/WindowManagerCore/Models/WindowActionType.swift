//  WindowActionType.swift - Window action types
//
//  Defines all possible window positioning actions as a pure Swift enum,
//  independent of any UI framework.

import Foundation

// MARK: - WindowActionType Enum

/// Represents all possible window positioning/sizing actions.
///
/// Each case has a unique integer ID used for persistence and identification.
public enum WindowActionType: Int, Codable, CaseIterable, Sendable {

    // MARK: Basic Halves (split screen into 2 parts)
    case leftHalf = 0
    case rightHalf = 1
    case bottomHalf = 10
    case topHalf = 11
    case centerHalf = 30

    // MARK: Corners (split screen into 4 quarters)
    case topLeft = 15
    case topRight = 16
    case bottomLeft = 13
    case bottomRight = 14

    // MARK: Thirds (split screen into 3 parts)
    case firstThird = 20
    case centerThird = 22
    case lastThird = 24
    case firstTwoThirds = 21
    case centerTwoThirds = 84
    case lastTwoThirds = 23

    // MARK: Fourths (split screen into 4 parts)
    case firstFourth = 31
    case secondFourth = 32
    case thirdFourth = 33
    case lastFourth = 34
    case firstThreeFourths = 35
    case centerThreeFourths = 85
    case lastThreeFourths = 36

    // MARK: Sixths (2 rows × 3 columns)
    case topLeftSixth = 37
    case topCenterSixth = 38
    case topRightSixth = 39
    case bottomLeftSixth = 40
    case bottomCenterSixth = 41
    case bottomRightSixth = 42

    // MARK: Ninths (3 rows × 3 columns)
    case topLeftNinth = 45
    case topCenterNinth = 46
    case topRightNinth = 47
    case middleLeftNinth = 48
    case middleCenterNinth = 49
    case middleRightNinth = 50
    case bottomLeftNinth = 51
    case bottomCenterNinth = 52
    case bottomRightNinth = 53

    // MARK: Corner Thirds
    case topLeftThird = 54
    case topRightThird = 55
    case bottomLeftThird = 56
    case bottomRightThird = 57

    // MARK: Eighths (2 rows × 4 columns)
    case topLeftEighth = 58
    case topCenterLeftEighth = 59
    case topCenterRightEighth = 60
    case topRightEighth = 61
    case bottomLeftEighth = 62
    case bottomCenterLeftEighth = 63
    case bottomCenterRightEighth = 64
    case bottomRightEighth = 65

    // MARK: Maximize & Size Actions
    case maximize = 2
    case almostMaximize = 29
    case maximizeHeight = 3
    case larger = 8
    case smaller = 9
    case largerWidth = 80
    case smallerWidth = 81
    case largerHeight = 82
    case smallerHeight = 83

    // MARK: Resize by Doubling/Halving
    case doubleHeightUp = 72
    case doubleHeightDown = 73
    case doubleWidthLeft = 74
    case doubleWidthRight = 75
    case halveHeightUp = 76
    case halveHeightDown = 77
    case halveWidthLeft = 78
    case halveWidthRight = 79

    // MARK: Centering & Positioning
    case center = 12
    case centerProminently = 71
    case restore = 19

    // MARK: Display Navigation
    case previousDisplay = 4
    case nextDisplay = 5

    // MARK: Movement (no resize)
    case moveLeft = 25
    case moveRight = 26
    case moveUp = 27
    case moveDown = 28

    // MARK: Multi-Window Actions
    case tileAll = 66
    case cascadeAll = 67
    case cascadeActiveApp = 70
    case reverseAll = 44

    // MARK: Special/Custom
    case specified = 43
    case leftTodo = 68
    case rightTodo = 69

    // MARK: - Properties

    /// String identifier for this action
    public var name: String {
        String(describing: self)
    }

    /// Whether this action changes the window's size
    public func resizes(settings: SettingsProtocol) -> Bool {
        switch self {
        case .center, .centerProminently, .nextDisplay, .previousDisplay:
            return false
        case .moveUp, .moveDown, .moveLeft, .moveRight:
            return settings.resizeOnDirectionalMove
        default:
            return true
        }
    }

    /// Whether this action can position windows partially outside the screen
    public var allowsExtendingOutsideScreen: Bool {
        switch self {
        case .doubleHeightUp, .doubleHeightDown, .doubleWidthLeft, .doubleWidthRight:
            return true
        default:
            return false
        }
    }

    /// Category for menu organization
    public var category: WindowActionCategory? {
        switch self {
        case .firstFourth, .secondFourth, .thirdFourth, .lastFourth,
             .firstThreeFourths, .centerThreeFourths, .lastThreeFourths:
            return .fourths
        case .topLeftSixth, .topCenterSixth, .topRightSixth,
             .bottomLeftSixth, .bottomCenterSixth, .bottomRightSixth:
            return .sixths
        case .moveUp, .moveDown, .moveLeft, .moveRight:
            return .move
        default:
            return nil
        }
    }
}

// MARK: - WindowActionCategory

/// Categories for grouping related window actions.
public enum WindowActionCategory: Sendable {
    case halves, thirds, fourths, sixths, corners
    case max, size, move, display, other
}
