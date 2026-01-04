//
//  CBridge.swift
//  WindowManagerCore
//
//  Utilities for passing Swift objects to and from C functions.
//
//  WHY THIS IS NEEDED:
//  Many macOS APIs (like accessibility observers) are C-based and use callbacks.
//  C callbacks can't capture Swift objects directly, but they CAN accept a "context"
//  parameter as a raw pointer (void*). These bridge functions let us:
//    1. Convert a Swift object → raw pointer (to pass INTO the C callback)
//    2. Convert a raw pointer → Swift object (to use INSIDE the C callback)
//
//  MEMORY MANAGEMENT NOTE:
//  We use "unretained" references, meaning these functions do NOT affect the
//  object's reference count. The caller must ensure the object stays alive
//  for as long as the pointer might be used.
//

import Foundation

// MARK: - C Bridging Utilities

public enum CBridge {

    /// Converts a Swift object into a raw pointer that can be passed to C functions.
    ///
    /// Use this when you need to pass a Swift object as a "context" or "user data"
    /// parameter to a C callback function.
    ///
    /// - Parameter obj: The Swift object to convert (must be a class, not a struct).
    /// - Returns: A raw pointer representing the object.
    ///
    /// Example usage:
    /// ```
    /// let observer = MyObserver()
    /// let pointer = CBridge.toPointer(observer)
    /// // Pass 'pointer' to a C function as void* context
    /// ```
    ///
    /// WARNING: The object must stay alive while the pointer is in use!
    ///
    public static func toPointer<T: AnyObject>(_ obj: T) -> UnsafeMutableRawPointer {
        return Unmanaged.passUnretained(obj).toOpaque()
    }

    /// Converts a raw pointer back into a Swift object.
    ///
    /// Use this inside a C callback to get back the original Swift object
    /// that was passed as context.
    ///
    /// - Parameter ptr: The raw pointer that was created by `toPointer(_:)`.
    /// - Returns: The original Swift object, cast to type T.
    ///
    /// Example usage:
    /// ```
    /// // Inside a C callback that received a void* context:
    /// let observer: MyObserver = CBridge.fromPointer(contextPointer)
    /// observer.handleEvent()
    /// ```
    ///
    public static func fromPointer<T: AnyObject>(_ ptr: UnsafeMutableRawPointer) -> T {
        return Unmanaged<T>.fromOpaque(ptr).takeUnretainedValue()
    }
}
