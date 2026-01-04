//  CycleCalculator.swift - Action cycling logic
//
//  Handles cycling through related window actions when the same
//  shortcut is pressed repeatedly.

import Foundation

// MARK: - CycleCalculator

/// Handles cycling through related window actions.
///
/// When a user presses the same shortcut repeatedly, actions can cycle
/// through related positions (e.g., left half → first two-thirds → first third).
public enum CycleCalculator {

    /// Get the cycle group for a window action.
    ///
    /// A cycle group is a list of related actions that should be cycled
    /// through when the same shortcut is pressed repeatedly.
    public static func cycleGroup(for action: WindowActionType) -> [WindowActionType] {
        switch action {
        // Halves cycle through thirds
        case .leftHalf:
            return [.leftHalf, .firstTwoThirds, .firstThird]
        case .rightHalf:
            return [.rightHalf, .lastTwoThirds, .lastThird]
        case .centerHalf:
            return [.centerHalf, .centerTwoThirds, .centerThird]

        // Top/bottom halves don't cycle
        case .topHalf:
            return [.topHalf]
        case .bottomHalf:
            return [.bottomHalf]

        // Corners don't cycle by default
        case .topLeft, .topRight, .bottomLeft, .bottomRight:
            return [action]

        // Ninths cycle through all 9 positions
        case .topLeftNinth, .topCenterNinth, .topRightNinth,
             .middleLeftNinth, .middleCenterNinth, .middleRightNinth,
             .bottomLeftNinth, .bottomCenterNinth, .bottomRightNinth:
            return [
                .topLeftNinth, .topCenterNinth, .topRightNinth,
                .middleLeftNinth, .middleCenterNinth, .middleRightNinth,
                .bottomLeftNinth, .bottomCenterNinth, .bottomRightNinth
            ]

        // Sixths cycle through all 6 positions
        case .topLeftSixth, .topCenterSixth, .topRightSixth,
             .bottomLeftSixth, .bottomCenterSixth, .bottomRightSixth:
            return [
                .topLeftSixth, .topCenterSixth, .topRightSixth,
                .bottomLeftSixth, .bottomCenterSixth, .bottomRightSixth
            ]

        // Eighths cycle through all 8 positions
        case .topLeftEighth, .topCenterLeftEighth, .topCenterRightEighth, .topRightEighth,
             .bottomLeftEighth, .bottomCenterLeftEighth, .bottomCenterRightEighth, .bottomRightEighth:
            return [
                .topLeftEighth, .topCenterLeftEighth, .topCenterRightEighth, .topRightEighth,
                .bottomLeftEighth, .bottomCenterLeftEighth, .bottomCenterRightEighth, .bottomRightEighth
            ]

        // Corner thirds cycle through all 4 positions
        case .topLeftThird, .topRightThird, .bottomLeftThird, .bottomRightThird:
            return [.topLeftThird, .topRightThird, .bottomLeftThird, .bottomRightThird]

        // All other actions don't cycle
        default:
            return [action]
        }
    }

    /// Get the next action in the cycle.
    /// - Parameters:
    ///   - action: The current action
    ///   - currentIndex: The current index in the cycle (0-based)
    /// - Returns: A tuple of (next action, new index)
    public static func nextAction(
        for action: WindowActionType,
        currentIndex: Int
    ) -> (action: WindowActionType, index: Int) {
        let group = cycleGroup(for: action)
        let nextIndex = (currentIndex + 1) % group.count
        return (group[nextIndex], nextIndex)
    }

    /// Check if the next iteration would wrap back to the start.
    public static func wouldWrap(for action: WindowActionType, currentIndex: Int) -> Bool {
        let group = cycleGroup(for: action)
        return currentIndex == group.count - 1
    }
}

// MARK: - CycleState

/// Tracks the current state of action cycling.
///
/// This is a value type that can be used to track cycling state
/// without global mutable state.
public struct CycleState: Sendable {
    public var lastAction: WindowActionType?
    public var cycleIndex: Int = 0

    public init(lastAction: WindowActionType? = nil, cycleIndex: Int = 0) {
        self.lastAction = lastAction
        self.cycleIndex = cycleIndex
    }

    /// Get the effective action for a given input action.
    ///
    /// If the action is the same as the last action, advances the cycle.
    /// If it's a different action, resets the cycle.
    public mutating func effectiveAction(for action: WindowActionType) -> WindowActionType {
        if lastAction == action {
            let (next, newIndex) = CycleCalculator.nextAction(for: action, currentIndex: cycleIndex)
            cycleIndex = newIndex
            return next
        } else {
            lastAction = action
            cycleIndex = 0
            return CycleCalculator.cycleGroup(for: action)[0]
        }
    }

    /// Check if the next call would wrap back to the start of the cycle.
    public func wouldWrap(for action: WindowActionType) -> Bool {
        guard lastAction == action else { return false }
        return CycleCalculator.wouldWrap(for: action, currentIndex: cycleIndex)
    }

    /// Reset the cycle state.
    public mutating func reset() {
        lastAction = nil
        cycleIndex = 0
    }
}
