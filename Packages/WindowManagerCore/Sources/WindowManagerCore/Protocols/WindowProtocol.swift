//  WindowProtocol.swift - Abstraction for window elements
//
//  This protocol abstracts window operations, allowing the core logic
//  to work with any window implementation (real or mock for testing).

import Foundation
import CoreGraphics

// MARK: - Window Protocol

/// Represents a window that can be positioned and sized.
///
/// This abstraction allows window calculations to be tested without
/// requiring actual macOS accessibility APIs.
public protocol WindowProtocol {
    /// Unique identifier for this window
    var id: CGWindowID { get }

    /// Current frame (position and size) of the window
    var frame: CGRect { get }

    /// Current size of the window
    var size: CGSize? { get }

    /// Current position of the window
    var position: CGPoint? { get }

    /// Whether this is a valid, visible window
    var isWindow: Bool? { get }

    /// Whether the window is minimized to the dock
    var isMinimized: Bool? { get }

    /// Whether the window is hidden
    var isHidden: Bool? { get }

    /// Whether this is a sheet attached to another window
    var isSheet: Bool? { get }

    /// Process ID of the application owning this window
    var pid: pid_t? { get }
}

// MARK: - Window Data (Value Type)

/// A simple value type representing window data for calculations.
///
/// Use this when you just need window properties without the ability
/// to modify the actual window.
public struct WindowData: WindowProtocol {
    public let id: CGWindowID
    public let frame: CGRect
    public let size: CGSize?
    public let position: CGPoint?
    public let isWindow: Bool?
    public let isMinimized: Bool?
    public let isHidden: Bool?
    public let isSheet: Bool?
    public let pid: pid_t?

    public init(
        id: CGWindowID,
        frame: CGRect,
        size: CGSize? = nil,
        position: CGPoint? = nil,
        isWindow: Bool? = true,
        isMinimized: Bool? = false,
        isHidden: Bool? = false,
        isSheet: Bool? = false,
        pid: pid_t? = nil
    ) {
        self.id = id
        self.frame = frame
        self.size = size ?? frame.size
        self.position = position ?? frame.origin
        self.isWindow = isWindow
        self.isMinimized = isMinimized
        self.isHidden = isHidden
        self.isSheet = isSheet
        self.pid = pid
    }
}
