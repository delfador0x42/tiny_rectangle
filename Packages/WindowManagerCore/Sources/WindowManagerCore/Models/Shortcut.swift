//
//  Shortcut.swift
//  WindowManagerCore
//
//  Represents a keyboard shortcut (key + modifiers like Cmd, Ctrl, etc.)
//

import Foundation

// MARK: - Shortcut Struct

/// Represents a keyboard shortcut (key + modifiers like Cmd, Ctrl, etc.)
///
/// Used to define and store keyboard shortcuts for window actions.
/// The modifierFlags use the same raw values as NSEvent.ModifierFlags.
///
/// Example usage:
/// ```swift
/// // Create a shortcut for Ctrl+Option+Left Arrow
/// let ctrl: UInt = 0x40000  // Control key
/// let alt: UInt = 0x80000   // Option key
/// let shortcut = Shortcut(ctrl | alt, kVK_LeftArrow)
/// ```
public struct Shortcut: Codable, Sendable {

    /// The virtual key code (from Carbon/Events.h).
    ///
    /// Examples: kVK_LeftArrow (123), kVK_ANSI_F (3), kVK_Return (36)
    public let keyCode: Int

    /// Bitmask of modifier keys (Cmd, Ctrl, Option, Shift).
    ///
    /// Uses the same raw values as NSEvent.ModifierFlags:
    /// - Command: 0x100000
    /// - Control: 0x40000
    /// - Option:  0x80000
    /// - Shift:   0x20000
    public let modifierFlags: UInt

    // MARK: - Initializers

    /// Creates a shortcut from modifier flags and key code.
    ///
    /// - Parameters:
    ///   - modifierFlags: Bitmask of modifiers (combine with bitwise OR)
    ///   - keyCode: The virtual key code (e.g., kVK_LeftArrow)
    public init(_ modifierFlags: UInt, _ keyCode: Int) {
        self.keyCode = keyCode
        self.modifierFlags = modifierFlags
    }
}
