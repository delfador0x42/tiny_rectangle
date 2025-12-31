//
//  WindowUtil.swift
//  tiny_window_manager
//
//  Utilities for querying window information from the macOS window server.
//  Uses CoreGraphics APIs to get details about all windows on screen.
//

import Foundation

// MARK: - Window Info

/// Information about a single window on screen.
///
/// This struct holds basic properties that macOS provides about each window,
/// such as its position, size, and which app owns it.
struct WindowInfo {

    /// Unique identifier for this window (assigned by the window server)
    let id: CGWindowID

    /// The window's z-order level (higher values are drawn on top)
    let level: CGWindowLevel

    /// The window's position and size on screen
    let frame: CGRect

    /// Process ID of the app that owns this window
    let pid: pid_t

    /// Name of the app that owns this window (e.g., "Finder", "Safari")
    let processName: String?
}

// MARK: - Window Utility

/// Provides methods for querying window information from macOS.
///
/// Uses the CoreGraphics window server APIs to get a list of all windows
/// currently on screen (or specific windows by ID).
class WindowUtil {

    // MARK: - Caching

    /// Cache to avoid repeated expensive calls to the window server.
    /// Results are cached for 100ms before being refreshed.
    private static var windowListCache = TimeoutCache<[CGWindowID]?, [WindowInfo]>(timeout: 100)

    // MARK: - Public API

    /// Gets information about windows on screen.
    ///
    /// - Parameters:
    ///   - ids: Optional array of specific window IDs to query.
    ///          If nil, returns all windows based on the `all` parameter.
    ///   - all: If true, includes off-screen windows. If false, only on-screen windows.
    ///          This parameter is ignored when `ids` is provided.
    /// - Returns: Array of WindowInfo structs describing each window.
    ///
    /// Example usage:
    /// ```swift
    /// // Get all visible windows
    /// let visibleWindows = WindowUtil.getWindowList()
    ///
    /// // Get specific windows by ID
    /// let specificWindows = WindowUtil.getWindowList(ids: [123, 456])
    ///
    /// // Get all windows including off-screen ones
    /// let allWindows = WindowUtil.getWindowList(all: true)
    /// ```
    static func getWindowList(ids: [CGWindowID]? = nil, all: Bool = false) -> [WindowInfo] {
        print(#function, "called")
        // Check cache first to avoid expensive window server calls
        if let cachedInfos = windowListCache[ids] {
            return cachedInfos
        }

        // Fetch raw window data from the window server
        let rawWindowInfos = fetchRawWindowInfos(ids: ids, includeOffScreen: all)

        // Parse the raw CoreFoundation data into Swift structs
        let windowInfos = parseWindowInfos(from: rawWindowInfos)

        // Cache the results for future calls
        windowListCache[ids] = windowInfos

        return windowInfos
    }

    // MARK: - Fetching Raw Window Data

    /// Fetches raw window information from the CoreGraphics window server.
    ///
    /// - Parameters:
    ///   - ids: Specific window IDs to fetch, or nil for all windows
    ///   - includeOffScreen: Whether to include windows that aren't currently visible
    /// - Returns: A CFArray of CFDictionary entries, one per window
    private static func fetchRawWindowInfos(ids: [CGWindowID]?, includeOffScreen: Bool) -> CFArray? {
        print(#function, "called")
        if let ids = ids {
            // Fetch specific windows by their IDs
            return fetchWindowInfosByIds(ids)
        } else {
            // Fetch all windows matching the criteria
            return fetchAllWindowInfos(includeOffScreen: includeOffScreen)
        }
    }

    /// Fetches window info for specific window IDs.
    ///
    /// This requires converting Swift's [CGWindowID] array into a CFArray
    /// of raw pointers, which is what the CoreGraphics API expects.
    private static func fetchWindowInfosByIds(_ ids: [CGWindowID]) -> CFArray? {
        print(#function, "called")
        // Allocate memory for an array of raw pointers
        let pointerArray = UnsafeMutablePointer<UnsafeRawPointer?>.allocate(capacity: ids.count)

        // Convert each window ID to a raw pointer
        // (CoreGraphics stores IDs as pointer-sized values in CFArrays)
        for (index, windowId) in ids.enumerated() {
            pointerArray[index] = UnsafeRawPointer(bitPattern: UInt(windowId))
        }

        // Create a CFArray from our pointer array
        let cfArrayOfIds = CFArrayCreate(kCFAllocatorDefault, pointerArray, ids.count, nil)

        // Query the window server for info about these specific windows
        return CGWindowListCreateDescriptionFromArray(cfArrayOfIds)
    }

    /// Fetches window info for all windows on screen.
    private static func fetchAllWindowInfos(includeOffScreen: Bool) -> CFArray? {
        print(#function, "called")
        // Choose which windows to include
        let listOption: CGWindowListOption = includeOffScreen ? .optionAll : .optionOnScreenOnly

        // Query the window server (excludes desktop elements like wallpaper)
        return CGWindowListCopyWindowInfo([listOption, .excludeDesktopElements], kCGNullWindowID)
    }

    // MARK: - Parsing Window Data

    /// Converts raw CoreFoundation window data into Swift WindowInfo structs.
    private static func parseWindowInfos(from rawInfos: CFArray?) -> [WindowInfo] {
        print(#function, "called")
        guard let rawInfos = rawInfos else {
            return []
        }

        var windowInfos = [WindowInfo]()
        let windowCount = rawInfos.getCount()

        for index in 0..<windowCount {
            if let windowInfo = parseWindowInfo(from: rawInfos, at: index) {
                windowInfos.append(windowInfo)
            }
        }

        return windowInfos
    }

    /// Parses a single window's data from the CFArray.
    ///
    /// Each window is represented as a CFDictionary with keys like
    /// kCGWindowNumber, kCGWindowBounds, kCGWindowOwnerPID, etc.
    private static func parseWindowInfo(from rawInfos: CFArray, at index: Int) -> WindowInfo? {
        print(#function, "called")
        let rawDict = rawInfos.getValue(index) as CFDictionary

        // Extract required fields from the dictionary
        let rawId = rawDict.getValue(kCGWindowNumber) as CFNumber
        let rawLevel = rawDict.getValue(kCGWindowLayer) as CFNumber
        let rawFrame = rawDict.getValue(kCGWindowBounds) as CFDictionary
        let rawPid = rawDict.getValue(kCGWindowOwnerPID) as CFNumber
        let rawProcessName = rawDict.getValue(kCGWindowOwnerName) as CFString?

        // Convert to Swift types
        let windowId = CGWindowID(truncating: rawId)
        let windowLevel = CGWindowLevel(truncating: rawLevel)
        let processPid = pid_t(truncating: rawPid)

        // Parse the frame (this can fail if the dictionary is malformed)
        guard let windowFrame = CGRect(dictionaryRepresentation: rawFrame) else {
            return nil
        }

        // Convert the process name (if available)
        let processName: String? = rawProcessName.map { String($0) }

        return WindowInfo(
            id: windowId,
            level: windowLevel,
            frame: windowFrame,
            pid: processPid,
            processName: processName
        )
    }
}
