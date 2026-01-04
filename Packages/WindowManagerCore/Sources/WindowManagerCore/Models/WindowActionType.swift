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

    // MARK: - Basic Properties

    /// String identifier for this action.
    public var name: String {
        String(describing: self)
    }

    /// Whether this action changes the window's size.
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

    /// Whether this action can position windows partially outside the screen.
    public var allowsExtendingOutsideScreen: Bool {
        switch self {
        case .doubleHeightUp, .doubleHeightDown, .doubleWidthLeft, .doubleWidthRight:
            return true
        default:
            return false
        }
    }

    // MARK: - Menu Organization

    /// Returns true if this action should have a separator above it in the menu.
    public var firstInGroup: Bool {
        switch self {
        case .leftHalf, .topLeft, .firstThird, .maximize, .nextDisplay,
             .moveLeft, .firstFourth, .topLeftSixth:
            return true
        default:
            return false
        }
    }

    /// Category for menu organization.
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

    /// A broader classification of the action type, used for grouping in settings.
    public var classification: WindowActionCategory? {
        switch self {
        case .firstThird, .firstTwoThirds, .centerThird, .centerTwoThirds,
             .lastTwoThirds, .lastThird:
            return .thirds
        case .smaller, .larger, .smallerWidth, .largerWidth,
             .smallerHeight, .largerHeight:
            return .size
        case .previousDisplay, .nextDisplay:
            return .display
        default:
            return nil
        }
    }

    // MARK: - Gap Properties

    /// Which edges of this window position are "shared" with adjacent windows.
    /// Used for applying window gaps - shared edges get half the gap size.
    public func gapSharedEdge(settings: SettingsProtocol) -> Edge {
        switch self {
        case .leftHalf: return .right
        case .rightHalf: return .left
        case .bottomHalf: return .top
        case .topHalf: return .bottom
        case .bottomLeft: return [.top, .right]
        case .bottomRight: return [.top, .left]
        case .topLeft: return [.bottom, .right]
        case .topRight: return [.bottom, .left]
        case .moveUp: return settings.resizeOnDirectionalMove ? .bottom : .none
        case .moveDown: return settings.resizeOnDirectionalMove ? .top : .none
        case .moveLeft: return settings.resizeOnDirectionalMove ? .right : .none
        case .moveRight: return settings.resizeOnDirectionalMove ? .left : .none
        default:
            return .none
        }
    }

    /// Which dimensions (horizontal, vertical, both, or none) should have gaps applied.
    public func gapsApplicable(settings: SettingsProtocol) -> Dimension {
        switch self {
        case .leftHalf, .rightHalf, .bottomHalf, .topHalf, .centerHalf,
             .bottomLeft, .bottomRight, .topLeft, .topRight,
             .firstThird, .firstTwoThirds, .centerThird, .centerTwoThirds,
             .lastTwoThirds, .lastThird,
             .firstFourth, .secondFourth, .thirdFourth, .lastFourth,
             .firstThreeFourths, .centerThreeFourths, .lastThreeFourths,
             .topLeftSixth, .topCenterSixth, .topRightSixth,
             .bottomLeftSixth, .bottomCenterSixth, .bottomRightSixth,
             .topLeftNinth, .topCenterNinth, .topRightNinth,
             .middleLeftNinth, .middleCenterNinth, .middleRightNinth,
             .bottomLeftNinth, .bottomCenterNinth, .bottomRightNinth,
             .topLeftThird, .topRightThird, .bottomLeftThird, .bottomRightThird,
             .topLeftEighth, .topCenterLeftEighth, .topCenterRightEighth, .topRightEighth,
             .bottomLeftEighth, .bottomCenterLeftEighth, .bottomCenterRightEighth, .bottomRightEighth,
             .doubleHeightUp, .doubleHeightDown, .doubleWidthLeft, .doubleWidthRight,
             .halveHeightUp, .halveHeightDown, .halveWidthLeft, .halveWidthRight,
             .leftTodo, .rightTodo:
            return .both
        case .moveUp, .moveDown:
            return settings.resizeOnDirectionalMove ? .vertical : .none
        case .moveLeft, .moveRight:
            return settings.resizeOnDirectionalMove ? .horizontal : .none
        case .maximize:
            return settings.applyGapsToMaximize ? .both : .none
        case .maximizeHeight:
            return settings.applyGapsToMaximizeHeight ? .both : .vertical
        case .almostMaximize, .previousDisplay, .nextDisplay,
             .larger, .smaller, .largerWidth, .smallerWidth, .largerHeight, .smallerHeight,
             .center, .centerProminently, .restore,
             .specified, .reverseAll, .tileAll, .cascadeAll, .cascadeActiveApp:
            return .none
        }
    }

    // MARK: - Snap Properties

    /// Whether this action can be triggered by dragging a window to a screen edge.
    public var isDragSnappable: Bool {
        switch self {
        case .restore, .previousDisplay, .nextDisplay,
             .moveUp, .moveDown, .moveLeft, .moveRight,
             .specified, .reverseAll, .tileAll, .cascadeAll,
             .larger, .smaller, .largerWidth, .smallerWidth, .cascadeActiveApp,
             .topLeftNinth, .topCenterNinth, .topRightNinth,
             .middleLeftNinth, .middleCenterNinth, .middleRightNinth,
             .bottomLeftNinth, .bottomCenterNinth, .bottomRightNinth,
             .topLeftThird, .topRightThird, .bottomLeftThird, .bottomRightThird,
             .topLeftEighth, .topCenterLeftEighth, .topCenterRightEighth, .topRightEighth,
             .bottomLeftEighth, .bottomCenterLeftEighth, .bottomCenterRightEighth, .bottomRightEighth:
            return false
        default:
            return true
        }
    }

    // MARK: - Cycling

    /// The group of actions that cycle when this action is repeated.
    public var cycleGroup: [WindowActionType] {
        switch self {
        case .leftHalf:
            return [.leftHalf, .firstTwoThirds, .firstThird]
        case .rightHalf:
            return [.rightHalf, .lastTwoThirds, .lastThird]
        case .topHalf:
            return [.topHalf]
        case .bottomHalf:
            return [.bottomHalf]
        case .centerHalf:
            return [.centerHalf, .centerTwoThirds, .centerThird]
        case .topLeft, .topRight, .bottomLeft, .bottomRight:
            return [self]
        case .topLeftNinth, .topCenterNinth, .topRightNinth,
             .middleLeftNinth, .middleCenterNinth, .middleRightNinth,
             .bottomLeftNinth, .bottomCenterNinth, .bottomRightNinth:
            return [.topLeftNinth, .topCenterNinth, .topRightNinth,
                    .middleLeftNinth, .middleCenterNinth, .middleRightNinth,
                    .bottomLeftNinth, .bottomCenterNinth, .bottomRightNinth]
        case .topLeftSixth, .topCenterSixth, .topRightSixth,
             .bottomLeftSixth, .bottomCenterSixth, .bottomRightSixth:
            return [.topLeftSixth, .topCenterSixth, .topRightSixth,
                    .bottomLeftSixth, .bottomCenterSixth, .bottomRightSixth]
        case .topLeftEighth, .topCenterLeftEighth, .topCenterRightEighth, .topRightEighth,
             .bottomLeftEighth, .bottomCenterLeftEighth, .bottomCenterRightEighth, .bottomRightEighth:
            return [.topLeftEighth, .topCenterLeftEighth, .topCenterRightEighth, .topRightEighth,
                    .bottomLeftEighth, .bottomCenterLeftEighth, .bottomCenterRightEighth, .bottomRightEighth]
        case .topLeftThird, .topRightThird, .bottomLeftThird, .bottomRightThird:
            return [.topLeftThird, .topRightThird, .bottomLeftThird, .bottomRightThird]
        default:
            return [self]
        }
    }

    // MARK: - Active Actions List

    /// All actions that appear in the menu, in display order.
    public static let active: [WindowActionType] = [
        // Halves
        .leftHalf, .rightHalf, .centerHalf, .topHalf, .bottomHalf,
        // Corners
        .topLeft, .topRight, .bottomLeft, .bottomRight,
        // Thirds
        .firstThird, .centerThird, .lastThird, .firstTwoThirds, .centerTwoThirds, .lastTwoThirds,
        // Size actions
        .maximize, .almostMaximize, .maximizeHeight, .larger, .smaller,
        .largerWidth, .smallerWidth, .largerHeight, .smallerHeight,
        // Positioning
        .center, .centerProminently, .restore,
        // Display navigation
        .nextDisplay, .previousDisplay,
        // Movement
        .moveLeft, .moveRight, .moveUp, .moveDown,
        // Fourths
        .firstFourth, .secondFourth, .thirdFourth, .lastFourth,
        .firstThreeFourths, .centerThreeFourths, .lastThreeFourths,
        // Sixths
        .topLeftSixth, .topCenterSixth, .topRightSixth,
        .bottomLeftSixth, .bottomCenterSixth, .bottomRightSixth,
        // Special
        .specified, .reverseAll,
        // Ninths
        .topLeftNinth, .topCenterNinth, .topRightNinth,
        .middleLeftNinth, .middleCenterNinth, .middleRightNinth,
        .bottomLeftNinth, .bottomCenterNinth, .bottomRightNinth,
        // Corner thirds
        .topLeftThird, .topRightThird, .bottomLeftThird, .bottomRightThird,
        // Eighths
        .topLeftEighth, .topCenterLeftEighth, .topCenterRightEighth, .topRightEighth,
        .bottomLeftEighth, .bottomCenterLeftEighth, .bottomCenterRightEighth, .bottomRightEighth,
        // Resize by doubling/halving
        .doubleHeightUp, .doubleHeightDown, .doubleWidthLeft, .doubleWidthRight,
        .halveHeightUp, .halveHeightDown, .halveWidthLeft, .halveWidthRight,
        // Multi-window
        .tileAll, .cascadeAll,
        .leftTodo, .rightTodo,
        .cascadeActiveApp
    ]
}

// MARK: - WindowActionCategory

/// Categories for grouping related window actions.
public enum WindowActionCategory: Sendable {
    case halves, thirds, fourths, sixths, corners
    case max, size, move, display, other

    /// Human-readable display name for this category.
    public var displayName: String {
        switch self {
        case .halves: return "Halves"
        case .thirds: return "Thirds"
        case .fourths: return "Fourths"
        case .sixths: return "Sixths"
        case .corners: return "Corners"
        case .max: return "Maximize"
        case .size: return "Size"
        case .move: return "Move"
        case .display: return "Display"
        case .other: return "Other"
        }
    }
}
