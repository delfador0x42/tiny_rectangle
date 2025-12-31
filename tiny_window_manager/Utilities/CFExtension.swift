//
//  CFExtension.swift
//  tiny_window_manager
//
//  These extensions make Core Foundation (CF) types easier to use in Swift.
//  Core Foundation is Apple's low-level C-based framework. These helpers
//  bridge the gap between CF's C-style API and Swift's type-safe approach.
//

import Foundation

// MARK: - CFArray Extension

extension CFArray {

    /// Retrieves a value from the array at the specified index and casts it to the desired type.
    ///
    /// - Parameter index: The position in the array (0-based).
    /// - Returns: The value at that index, cast to type T.
    ///
    /// Example usage:
    ///   let windowID: CGWindowID = myArray.getValue(0)
    ///
    func getValue<T>(_ index: CFIndex) -> T {
        print(#function, "called")
        // Step 1: Get the raw pointer to the value at this index
        // CFArrayGetValueAtIndex returns an UnsafeRawPointer (like a void* in C)
        let rawPointer = CFArrayGetValueAtIndex(self, index)

        // Step 2: Convert the raw pointer to our desired Swift type
        // unsafeBitCast reinterprets the bits as a different type without any checks
        let typedValue: T = unsafeBitCast(rawPointer, to: T.self)

        return typedValue
    }

    /// Returns the number of elements in the array.
    ///
    /// - Returns: The count as a CFIndex (which is just an Int on most platforms).
    ///
    func getCount() -> CFIndex {
        print(#function, "called")
        return CFArrayGetCount(self)
    }
}

// MARK: - CFDictionary Extension

extension CFDictionary {

    /// Retrieves a value from the dictionary for the specified key and casts it to the desired type.
    ///
    /// - Parameter key: The CFString key to look up.
    /// - Returns: The value associated with that key, cast to type T.
    ///
    /// Example usage:
    ///   let bounds: CFDictionary = myDict.getValue(kCGWindowBounds)
    ///
    func getValue<T>(_ key: CFString) -> T {
        print(#function, "called")
        // Step 1: Convert the CFString key to a raw pointer
        // CFDictionary's C API expects keys as UnsafeRawPointer (void*)
        let keyAsPointer = unsafeBitCast(key, to: UnsafeRawPointer.self)

        // Step 2: Look up the value in the dictionary using the key pointer
        // This returns another raw pointer to the value
        let valuePointer = CFDictionaryGetValue(self, keyAsPointer)

        // Step 3: Convert the raw value pointer to our desired Swift type
        let typedValue: T = unsafeBitCast(valuePointer, to: T.self)

        return typedValue
    }
}
