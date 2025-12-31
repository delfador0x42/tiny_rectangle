//
//  SequenceExtension.swift
//  tiny_window_manager
//
//  Extension for working with sequences (arrays, sets, etc.) in Swift.
//
//  WHAT IS A SEQUENCE?
//  A Sequence is anything you can loop over with a for-in loop:
//    - Arrays: [1, 2, 3]
//    - Sets: Set([1, 2, 3])
//    - Strings: "hello" (each character)
//    - Dictionary keys/values
//    - And many more!
//
//  By extending Sequence, our method works on ALL of these types.
//
//  WHAT IS uniqueMap?
//  It's like Swift's built-in `map`, but it removes duplicates.
//
//  Regular map:        [1, 2, 2, 3].map { $0 * 2 }     → [2, 4, 4, 6] (keeps duplicates)
//  Our uniqueMap:      [1, 2, 2, 3].uniqueMap { $0 * 2 } → [2, 4, 6] (removes duplicates)
//
//  IMPORTANTLY: It preserves the ORDER of first occurrences!
//  Example: [1, 2, 1, 3, 2].uniqueMap { $0 } → [1, 2, 3] (not [1, 3, 2] or random)
//

import Foundation

// MARK: - Sequence Extension

extension Sequence {

    /// Transforms each element and returns only unique results, preserving order.
    ///
    /// This is like `map` followed by removing duplicates, but more efficient
    /// because it removes duplicates as it goes rather than in a second pass.
    ///
    /// - Parameter transform: A closure that converts each element to type T.
    /// - Returns: An array of transformed elements with duplicates removed.
    ///
    /// Example usage:
    /// ```
    /// let words = ["Apple", "APPLE", "Banana", "apple"]
    ///
    /// // Get unique lowercase versions (preserving first occurrence order)
    /// let unique = words.uniqueMap { $0.lowercased() }
    /// // Result: ["apple", "banana"]
    ///
    /// // Get unique first characters
    /// let firstChars = words.uniqueMap { $0.first! }
    /// // Result: ["A", "B", "a"]
    /// ```
    ///
    /// WHY THE CONSTRAINT `T: Hashable`?
    /// We use a Set internally for O(1) duplicate detection, and Sets require
    /// their elements to be Hashable (able to produce a hash value for fast lookup).
    ///
    func uniqueMap<T>(_ transform: (Element) -> T) -> [T] where T: Hashable {
        print(#function, "called")

        // We use TWO data structures for different purposes:
        //
        // 1. Set: For fast O(1) "have we seen this before?" checks
        //    - Sets don't preserve order, but lookups are instant
        //
        // 2. Array: For preserving the order of first occurrences
        //    - Arrays maintain order, but searching would be O(n)
        //
        // By using both, we get fast lookups AND preserved order!

        var seenElements = Set<T>()       // Tracks what we've already encountered
        var uniqueResults = Array<T>()    // Stores results in order

        // Process each element in the sequence
        for originalElement in self {

            // Transform the element using the provided closure
            let transformedElement = transform(originalElement)

            // Try to insert into the set
            // insert() returns a tuple: (inserted: Bool, memberAfterInsert: T)
            // - inserted = true if this was a NEW element
            // - inserted = false if the element already existed
            let insertResult = seenElements.insert(transformedElement)
            let isNewElement = insertResult.inserted

            // Only add to our results array if this is the first time we've seen it
            if isNewElement {
                uniqueResults.append(transformedElement)
            }
        }

        return uniqueResults
    }
}
