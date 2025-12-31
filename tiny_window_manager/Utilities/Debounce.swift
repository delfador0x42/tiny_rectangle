//
//  Debounce.swift
//  tiny_window_manager
//
//  A utility for "debouncing" rapid inputs - waiting until the input stabilizes
//  before taking action.
//
//  WHAT IS DEBOUNCING?
//  Imagine a user rapidly resizing a window. Each tiny movement triggers an event.
//  Without debouncing, we'd process EVERY intermediate position (wasteful!).
//  With debouncing, we wait until the user stops moving, then process just the final position.
//
//  HOW THIS IMPLEMENTATION WORKS:
//  1. When input arrives, we schedule an action for 0.5 seconds in the future
//  2. After 0.5 seconds, we check if the input is STILL the current value
//  3. If yes → the input has stabilized, so we perform the action
//  4. If no → newer input arrived, so we skip this (the newer input has its own scheduled check)
//

import Foundation
import Dispatch

// MARK: - Debounce Utility

/// A generic debouncing utility that delays action until input stops changing.
///
/// The type parameter T must be Equatable so we can compare values.
///
class Debounce<T: Equatable> {

    // Private initializer prevents creating instances.
    // All functionality is through the static method.
    private init() {
        print(#function, "called")
    }

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
    ///
    /// SWIFT CONCEPTS USED:
    /// - @escaping: The closure will be called later (after this function returns)
    /// - @autoclosure: Automatically wraps an expression in a closure (so you can
    ///                 write `self.value` instead of `{ self.value }`)
    ///
    static func input(
        _ input: T,
        comparedAgainst current: @escaping @autoclosure () -> (T),
        perform: @escaping (T) -> ()
    ) {
        print(#function, "called")
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
