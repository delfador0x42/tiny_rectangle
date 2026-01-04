//  WindowHistory.swift - Tracks window positions for restore/cycling

import Foundation

/// Stores window position history for restore and cycling features.
class WindowHistory {
    /// Original positions before app modified windows (for restore)
    var restoreRects = [CGWindowID: CGRect]()

    /// Most recent action applied to each window (for cycling)
    var lastWindowActions = [CGWindowID: WindowActionRecord]()
}
