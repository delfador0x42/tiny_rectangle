//
//  Debounce.swift
//  WindowManagerCore
//
//  A utility for "debouncing" rapid inputs - waiting until the input stabilizes
//  before taking action.
//
//  WHAT IS DEBOUNCING?
//  Imagine a user rapidly resizing a window. Each tiny movement triggers an event.
//  Without debouncing, we'd process EVERY intermediate position (wasteful!).
//  With debouncing, we wait until the user stops moving, then process just the final position.
//

import Foundation
import Dispatch

// MARK: - Debounce Utility

/// A generic debouncing utility that delays action until input stops changing.
///
/// The type parameter T must be Equatable so we can compare values.
///
public final class Debounce<T: Equatable> {

    // Private initializer prevents creating instances.
    // All functionality is through the static method.
    private init() {}

    /// Schedules an action to be performed after a delay, but ONLY if the input hasn't changed.
    ///
    /// - Parameters:
    ///   - input: The input value that triggered this call.
    ///   - current: A closure that returns the CURRENT value (checked after the delay).
    ///              This is marked @autoclosure so you can pass a property directly.
    ///   - perform: The action to perform if the input is still current after the delay.
    ///
    /// Example usage:
    /// ```
    /// // In a window resize handler:
    /// Debounce.input(
    ///     newSize,                           // The size that just arrived
    ///     comparedAgainst: self.windowSize,  // Will be checked after 0.5s
    ///     perform: { finalSize in
    ///         self.updateLayout(for: finalSize)  // Only runs when resizing stops
    ///     }
    /// )
    /// ```
    public static func input(
        _ input: T,
        comparedAgainst current: @escaping @autoclosure () -> (T),
        perform: @escaping (T) -> ()
    ) {
        // Define when the delayed check should happen (0.5 seconds from now)
        let delay = DispatchTime.now() + 0.5

        // Schedule a check to run on the main thread after the delay
        DispatchQueue.main.asyncAfter(deadline: delay) {
            // Get the CURRENT value at this moment (0.5 seconds later)
            let currentValue = current()

            // Compare: is the input still the current value?
            let inputIsStillCurrent = (input == currentValue)

            // Only perform the action if the input hasn't been superseded
            if inputIsStillCurrent {
                perform(input)
            }
            // If not current, we silently skip - a newer input will handle itself
        }
    }
}
