//
//  DispatchTimeExtension.swift
//  tiny_window_manager
//
//  A simple extension to make working with DispatchTime easier.
//
//  BACKGROUND:
//  DispatchTime represents a point in time, typically used for scheduling delayed
//  operations with Grand Central Dispatch (GCD). By default, it provides time in
//  nanoseconds, but milliseconds are often more practical to work with.
//

import Foundation

// MARK: - DispatchTime Extension

extension DispatchTime {

    /// Returns the system uptime in milliseconds.
    ///
    /// This converts the built-in `uptimeNanoseconds` property to milliseconds
    /// for easier use in timing calculations.
    ///
    /// TIME UNIT CONVERSIONS:
    /// - 1 second       = 1,000 milliseconds
    /// - 1 millisecond  = 1,000 microseconds
    /// - 1 microsecond  = 1,000 nanoseconds
    /// - 1 millisecond  = 1,000,000 nanoseconds (hence dividing by 1_000_000)
    ///
    /// Example usage:
    /// ```
    /// let startTime = DispatchTime.now().uptimeMilliseconds
    /// // ... do some work ...
    /// let endTime = DispatchTime.now().uptimeMilliseconds
    /// let elapsedMs = endTime - startTime
    /// print("Operation took \(elapsedMs) milliseconds")
    /// ```
    ///
    var uptimeMilliseconds: UInt64 {
        // Convert nanoseconds to milliseconds by dividing by 1 million
        // Swift allows underscores in numbers for readability: 1_000_000 = 1000000
        return uptimeNanoseconds / 1_000_000
    }
}
