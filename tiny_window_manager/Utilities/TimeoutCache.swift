//
//  TimeoutCache.swift
//  tiny_window_manager
//
//  A dictionary-like cache where entries automatically expire after a timeout.
//  Uses a doubly-linked list to efficiently remove expired entries in order.
//

import Foundation

// MARK: - Timeout Cache

/// A cache that automatically expires entries after a specified timeout.
///
/// Usage example:
/// ```swift
/// let cache = TimeoutCache<String, Int>(timeout: 5000)  // 5 second timeout
/// cache["myKey"] = 42           // Store a value
/// let value = cache["myKey"]    // Retrieve it (returns nil if expired)
/// ```
///
/// Internally uses a doubly-linked list to track entry order, allowing
/// efficient cleanup of expired entries from oldest to newest.
class TimeoutCache<Key: Hashable, Value> {

    // MARK: - Configuration

    /// How long entries stay valid (in milliseconds)
    private let timeout: UInt64

    // MARK: - Doubly-Linked List Pointers

    /// The oldest entry in the cache (first to expire)
    private var head: Entry?

    /// The newest entry in the cache (last to expire)
    private var tail: Entry?

    // MARK: - Storage

    /// Fast key-to-entry lookup dictionary
    private var cache = [Key: Entry]()

    // MARK: - Purge Rate Limiting

    /// Timestamp when we're allowed to purge again (prevents purging too often)
    private var nextAllowedPurgeTime: UInt64 = 0

    /// Returns true if enough time has passed to allow another purge
    private var canPurgeNow: Bool {
        return DispatchTime.now().uptimeMilliseconds > nextAllowedPurgeTime
    }

    // MARK: - Initialization

    /// Creates a new cache with the specified timeout.
    /// - Parameter timeout: How long entries remain valid, in milliseconds
    init(timeout: UInt64) {
        self.timeout = timeout
    }

    // MARK: - Public Subscript Access

    /// Gets or sets a cached value by key.
    ///
    /// **Getting:** Returns the value if it exists and hasn't expired, otherwise nil.
    /// **Setting:** Stores a new value (or removes it if set to nil).
    subscript(key: Key) -> Value? {
        get {
            return getValue(forKey: key)
        }
        set {
            setValue(newValue, forKey: key)
        }
    }

    // MARK: - Get Value

    /// Retrieves a value from the cache if it exists and hasn't expired.
    private func getValue(forKey key: Key) -> Value? {
        // Look up the entry in our dictionary
        guard let entry = cache[key] else {
            return nil
        }

        // Check if the entry has expired
        if entry.isExpired {
            remove(key)
            return nil
        }

        return entry.value
    }

    // MARK: - Set Value

    /// Stores a value in the cache, or removes it if the value is nil.
    private func setValue(_ value: Value?, forKey key: Key) {
        // Always remove the old entry first (if it exists)
        remove(key)

        // Clean up old expired entries periodically
        purgeExpiredEntries()

        // If value is nil, we're done (just wanted to remove)
        guard let value = value else {
            return
        }

        // Create the new entry with an expiration time
        let expirationTime = DispatchTime.now().uptimeMilliseconds + timeout
        let newEntry = Entry(
            key: key,
            value: value,
            expirationTimestamp: expirationTime,
            previous: tail
        )

        // Add to the end of the linked list
        appendEntryToTail(newEntry)

        // Store in the dictionary for fast lookup
        cache[key] = newEntry
    }

    /// Adds an entry to the end of the doubly-linked list.
    private func appendEntryToTail(_ entry: Entry) {
        // Link the old tail to this new entry
        tail?.next = entry

        // If the list was empty, this is now the head
        if head == nil {
            head = entry
        }

        // This entry is now the tail
        tail = entry
    }

    // MARK: - Remove Entry

    /// Removes an entry from both the dictionary and the linked list.
    private func remove(_ key: Key) {
        guard let entry = cache[key] else {
            return
        }

        // Remove from dictionary
        cache[key] = nil

        // Update tail pointer if we're removing the tail
        if entry === tail {
            tail = entry.previous
        }

        // Update head pointer if we're removing the head
        if entry === head {
            head = entry.next
        }

        // Unlink from the doubly-linked list
        // Before: [previous] <-> [entry] <-> [next]
        // After:  [previous] <-> [next]
        entry.previous?.next = entry.next
        entry.next?.previous = entry.previous
    }

    // MARK: - Purge Expired Entries

    /// Removes expired entries from the cache, starting from the oldest.
    /// Rate-limited to avoid purging too frequently.
    private func purgeExpiredEntries() {
        // Don't purge too often (rate limiting)
        guard canPurgeNow else {
            return
        }

        // Walk from head (oldest) and remove expired entries
        var currentEntry = head
        while let entry = currentEntry, entry.isExpired {
            let nextEntry = entry.next
            remove(entry.key)
            currentEntry = nextEntry
        }

        // Don't allow another purge for a while (100x the timeout)
        nextAllowedPurgeTime = DispatchTime.now().uptimeMilliseconds + (100 * timeout)
    }
}

// MARK: - Cache Entry

extension TimeoutCache {

    /// A single entry in the cache, also acting as a node in the doubly-linked list.
    ///
    /// The linked list structure allows us to efficiently iterate from oldest
    /// to newest when purging expired entries.
    private class Entry {

        /// The key used to look up this entry
        let key: Key

        /// The cached value
        let value: Value

        /// When this entry expires (in milliseconds since boot)
        let expirationTimestamp: UInt64

        /// Link to the previous (older) entry in the list
        var previous: Entry?

        /// Link to the next (newer) entry in the list
        var next: Entry?

        /// Returns true if this entry has passed its expiration time
        var isExpired: Bool {
            return DispatchTime.now().uptimeMilliseconds > expirationTimestamp
        }

        init(key: Key, value: Value, expirationTimestamp: UInt64, previous: Entry?) {
            self.key = key
            self.value = value
            self.expirationTimestamp = expirationTimestamp
            self.previous = previous
        }
    }
}
