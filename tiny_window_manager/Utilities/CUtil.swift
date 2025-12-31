//
//  CUtil.swift
//  tiny_window_manager
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

class CUtil {

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
    /// let pointer = CUtil.bridge(obj: observer)
    /// // Pass 'pointer' to a C function as void* context
    /// ```
    ///
    /// WARNING: The object must stay alive while the pointer is in use!
    ///
    static func bridge<T: AnyObject>(obj: T) -> UnsafeMutableRawPointer {
        print(#function, "called")
        // Step 1: Wrap the object in an "Unmanaged" container
        // passUnretained means we DON'T increase the reference count
        // (the caller is responsible for keeping the object alive)
        let unmanagedObject = Unmanaged.passUnretained(obj)

        // Step 2: Convert to an "opaque" pointer (loses type information)
        let opaquePointer = unmanagedObject.toOpaque()

        // Step 3: Convert to the final UnsafeMutableRawPointer type that C expects
        let rawPointer = UnsafeMutableRawPointer(opaquePointer)

        return rawPointer
    }

    /// Converts a raw pointer back into a Swift object.
    ///
    /// Use this inside a C callback to get back the original Swift object
    /// that was passed as context.
    ///
    /// - Parameter ptr: The raw pointer that was created by `bridge(obj:)`.
    /// - Returns: The original Swift object, cast to type T.
    ///
    /// Example usage:
    /// ```
    /// // Inside a C callback that received a void* context:
    /// let observer: MyObserver = CUtil.bridge(ptr: contextPointer)
    /// observer.handleEvent()
    /// ```
    ///
    static func bridge<T: AnyObject>(ptr: UnsafeMutableRawPointer) -> T {
        print(#function, "called")
        // Step 1: Create an Unmanaged wrapper from the opaque pointer
        // We specify the type T so Swift knows what we're converting to
        let unmanagedObject = Unmanaged<T>.fromOpaque(ptr)

        // Step 2: Extract the actual object
        // takeUnretainedValue means we DON'T decrease the reference count
        // (we're just "borrowing" a reference, not taking ownership)
        let object = unmanagedObject.takeUnretainedValue()

        return object
    }
}
